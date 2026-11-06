-- Applies the monitor setup matching the connected monitors, from one machine-local saved file, when
-- the config loads and whenever a monitor comes or goes. This is the part that talks to Hyprland; the
-- matching is in setups.lua. See docs/adr/0002-hyprland-owns-monitor-setups.md.

local setups = require("modules.monitors.setups")

local M = {}

-- monitor.removed fires before Hyprland drops the monitor from its list, and also when a monitor is
-- only turned off, so the list can only be trusted once the event is over. Waiting a moment also
-- takes several monitors appearing together as one change.
local SETTLE_MS = 100

-- How long a trial lasts with nobody answering: a few seconds past countdownSeconds in the shell's
-- MonitorChange.js, so the shell goes first when it's alive. Keep them in step.
local TRIAL_MS = 18000

-- Hyprland says when the lid moves but not where it is, and a config reload says nothing at all, so
-- the state is read from the kernel each time. The folder's name varies by machine, hence the glob.
local LID_SWITCH = "Lid Switch"
local LID_STATES = "/proc/acpi/button/lid/*/state"

local function default_path()
	local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
	return config .. "/hypr/monitor-setups.json"
end

local function read(path)
	local file, _, code = io.open(path, "r")
	if not file then
		return nil, code ~= 2 -- 2 is ENOENT: there's simply no file
	end
	local text = file:read("*a")
	file:close()
	return text, text == nil
end

local function exists(path)
	-- Renaming a file to itself changes nothing, and only fails if it isn't there. A file that can't be
	-- opened, which is what ends up here, still counts.
	local _, _, code = os.rename(path, path)
	return code ~= 2
end

-- A name nothing has yet, so one backup never replaces another. The first is the plain one. In a
-- folder that can't be written every name looks taken, and the rename fails anyway, hence the limit.
local function free_name(path)
	local name, number = path, 0
	while exists(name) and number < 1000 do
		number = number + 1
		name = path .. "." .. number
	end
	return name
end

-- The saved setups, or nil when there's no file, then the file's `unkept` if it has one. A file that
-- can't be read counts as no setups, and moves aside so nothing overwrites it, where the shell looks.
local function load_saved(path)
	local text, unreadable = read(path)
	if not text and not unreadable then
		return nil
	end
	local saved, unkept
	if text then
		local _
		saved, _, unkept = setups.parse(text)
	end
	if not saved then
		os.rename(path, free_name(path .. ".bad"))
	end
	return saved or {}, unkept
end

local function write_atomically(path, text)
	local file = io.open(path .. ".tmp", "w")
	if file then
		file:write(text)
		file:close()
		os.rename(path .. ".tmp", path)
	end
end

-- Puts the file back as it was before a trial, so the shell finds nothing left to recover.
local function restore_file(path, unkept)
	if unkept.before then
		write_atomically(path, unkept.before)
	else
		os.remove(path)
	end
end

-- Says which monitors fell back, one description per line, for the shell's toast. The file stays while
-- they're fallen back, so applying again doesn't look like news, and goes once none are.
local function leave_fallbacks(path, fell_back)
	if #fell_back == 0 then
		os.remove(path)
	else
		write_atomically(path, table.concat(fell_back, "\n") .. "\n")
	end
end

-- A lid that can't be read counts as open, which leaves every screen on.
local function lid_closed(states)
	local cat = io.popen("cat " .. states .. " 2>/dev/null")
	if not cat then
		return false
	end
	local text = cat:read("*a")
	cat:close()
	return text ~= nil and text:find("closed", 1, true) ~= nil
end

-- One line per setting, in a fixed order, to tell whether anything changed.
local function fingerprint(rules)
	local lines = {}
	for _, rule in ipairs(rules) do
		for field, value in pairs(rule) do
			lines[#lines + 1] = rule.output .. " " .. field .. " " .. tostring(value)
		end
	end
	table.sort(lines)
	return table.concat(lines, "\n")
end

-- options.path: the saved file, by default ~/.config/hypr/monitor-setups.json
-- options.lid_states: where to read the lid from, a glob
function M.install(options)
	local path = options.path or default_path()
	local lid_states = options.lid_states or LID_STATES
	local last_applied
	local waiting = false
	-- A trial is only running if this Lua state started one. Anything else that finds `unkept` in the
	-- file comes from a shell or a Hyprland that stopped, or from a reload, which clears Hyprland's timers.
	local trying = false
	local trials = 0
	local apply

	local function trial_over()
		trying = false
		local _, unkept = load_saved(path)
		if unkept then
			apply()
		end
	end

	-- Each change starts the time again, and the deadlines of the ones before it no longer count.
	local function start_trial()
		trying = true
		trials = trials + 1
		local trial = trials
		hl.timer(function()
			if trial == trials then
				trial_over()
			end
		end, { timeout = TRIAL_MS, type = "oneshot" })
	end

	-- asked: the shell wrote the file and wants it applied, `unkept` and all.
	apply = function(asked)
		-- `all` includes the monitors a setup turned off: they're still part of the combination.
		local connected = hl.get_monitors({ all = true })
		if #connected == 0 then
			return
		end
		local saved, unkept = load_saved(path)
		if unkept and asked then
			start_trial()
		elseif unkept and not trying then
			restore_file(path, unkept)
			saved = setups.going_back(unkept)
		end
		local rules, fell_back = setups.rules_for(saved or {}, connected, lid_closed(lid_states))
		leave_fallbacks(path .. ".fallback", fell_back)
		-- A setup turning a monitor off fires monitor.removed, which lands back here.
		local applying = fingerprint(rules)
		if applying == last_applied then
			return
		end
		-- Unset while it's under way: a rule that fails leaves the monitors part way.
		last_applied = nil
		for _, rule in ipairs(rules) do
			hl.monitor(rule)
		end
		last_applied = applying
	end

	local function apply_once_settled()
		if waiting then
			return
		end
		waiting = true
		hl.timer(function()
			waiting = false
			apply()
		end, { timeout = SETTLE_MS, type = "oneshot" })
	end

	-- The shell calls this over `hyprctl eval` after writing the file. A reload would do too, but that
	-- rebuilds the whole config, binds included, for what's only a change of monitors.
	M.apply_now = function()
		apply(true)
	end

	hl.on("hyprland.start", apply_once_settled)
	hl.on("monitor.added", apply_once_settled)
	hl.on("monitor.removed", apply_once_settled)
	hl.bind("switch:" .. LID_SWITCH, apply_once_settled, {
		locked = true,
		dont_inhibit = true,
		ignore_mods = true,
		submap_universal = true,
		description = "Apply the monitor setup when the lid moves",
	})
	apply()
end

return M
