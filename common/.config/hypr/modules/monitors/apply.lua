-- Applies the monitor setup matching the connected monitors, from one machine-local saved file, when
-- the config loads and whenever a monitor comes or goes. This is the part that talks to Hyprland; the
-- matching is in setups.lua. See docs/adr/0002-hyprland-owns-monitor-setups.md.

local setups = require("modules.monitors.setups")

local M = {}

-- monitor.removed fires before Hyprland drops the monitor from its list, and also when a monitor is
-- only turned off, so the list can only be trusted once the event is over. Waiting a moment also
-- takes several monitors appearing together as one change.
local SETTLE_MS = 100

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

-- The saved setups, or nil when there's no file. A file that can't be read counts as no setups, and
-- moves aside so nothing overwrites it. It's kept under one name, which the shell can look for.
local function load_saved(path)
	local text, unreadable = read(path)
	if not text and not unreadable then
		return nil
	end
	local saved = text and setups.parse(text)
	if not saved then
		os.rename(path, path .. ".bad")
	end
	return saved or {}
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
-- options.stand_aside: with no saved file, leave the monitors alone instead of extending automatically
-- options.lid_states: where to read the lid from, a glob
function M.install(options)
	local path = options.path or default_path()
	local lid_states = options.lid_states or LID_STATES
	local last_applied
	local waiting = false

	local function apply()
		-- `all` includes the monitors a setup turned off: they're still part of the combination.
		local connected = hl.get_monitors({ all = true })
		if #connected == 0 then
			return
		end
		local saved = load_saved(path)
		if not saved and options.stand_aside then
			return
		end
		local rules = setups.rules_for(saved or {}, connected, lid_closed(lid_states))
		-- A setup turning a monitor off fires monitor.removed, which lands back here.
		local applying = fingerprint(rules)
		if applying == last_applied then
			return
		end
		last_applied = applying
		for _, rule in ipairs(rules) do
			hl.monitor(rule)
		end
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
