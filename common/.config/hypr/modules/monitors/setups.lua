-- Works out the Hyprland monitor rules for the connected monitors, from the saved setups. Plain Lua
-- with no `hl` and no files, so tests/monitor-setups.sh can run it outside Hyprland.
-- See docs/adr/0002-hyprland-owns-monitor-setups.md.

local json = require("modules.monitors.json")

local M = {}

-- hl.monitor starts from the last rule for that output, so every rule writes every field and nothing
-- of the previous setup carries over. These are the values Hyprland gives a rule that sets none.
-- icc is the one gap: Hyprland rejects an empty icc, so a rule can't clear one from an earlier setup
-- (docs/adr/0002-hyprland-owns-monitor-setups.md).
local UNSET = {
	disabled = false,
	transform = 0,
	mirror = "",
	bitdepth = 8,
	vrr = -1,
	reserved = 0,
	cm = "srgb",
	sdr_eotf = "default",
	sdrbrightness = 1,
	sdrsaturation = 1,
	supports_wide_color = 0,
	supports_hdr = 0,
	sdr_min_luminance = 0.2,
	sdr_max_luminance = 80,
	min_luminance = -1,
	max_luminance = -1,
	max_avg_luminance = -1,
}

local function automatic(monitor)
	local rule = { output = monitor.name, mode = "highres", position = "auto", scale = "auto" }
	for field, value in pairs(UNSET) do
		rule[field] = value
	end
	return rule
end

local function combination(descriptions)
	table.sort(descriptions)
	return table.concat(descriptions, "\n")
end

local function descriptions_of(list)
	local descriptions = {}
	for i = 1, #list do
		descriptions[i] = list[i].description
	end
	return descriptions
end

local function find_setup(saved, connected)
	local wanted = combination(descriptions_of(connected))
	for i = 1, #saved do
		if combination(descriptions_of(saved[i].monitors)) == wanted then
			return saved[i]
		end
	end
end

-- Pairs each connected monitor with its entry in the setup: by description, and by port where the
-- description isn't enough. Identical monitors that changed ports take what's left, in order.
local function pair(setup, connected)
	local pairs_by_port, taken = {}, {}
	local function take(accepts)
		for i = 1, #connected do
			local monitor = connected[i]
			if not pairs_by_port[monitor.name] then
				for j = 1, #setup.monitors do
					local entry = setup.monitors[j]
					if not taken[j] and accepts(monitor, entry) then
						taken[j] = true
						pairs_by_port[monitor.name] = entry
						break
					end
				end
			end
		end
	end
	take(function(monitor, entry)
		return entry.description == monitor.description and entry.port == monitor.name
	end)
	take(function(monitor, entry)
		return entry.description == monitor.description
	end)
	return pairs_by_port
end

local function is_mode(candidate)
	return type(candidate) == "table"
		and type(candidate.width) == "number"
		and type(candidate.height) == "number"
		and type(candidate.refresh_rate) == "number"
end

-- Hyprland lists { width, height, refresh_rate, preferred } from the output, so a disabled monitor has
-- its modes too. Saying a mode is gone takes a list that shows it: a headless output lists none, and
-- anything else here is a shape Hyprland doesn't have yet.
local function mode_exists(mode, available)
	local width, height, refresh = mode:match("^(%d+)x(%d+)@?(.*)$")
	if not width then
		return true -- preferred, highres and the like
	end
	local hz = tonumber(refresh)
	local listed = false
	for _, candidate in ipairs(type(available) == "table" and available or {}) do
		if is_mode(candidate) then
			listed = true
			if
				candidate.width == tonumber(width)
				and candidate.height == tonumber(height)
				and (not hz or math.abs(candidate.refresh_rate - hz) < 1)
			then
				return true
			end
		end
	end
	return not listed
end

-- A mirror names the monitor it copies by description, or by port between identical monitors. Rules
-- need the port that monitor is on now.
local function mirror_port(mirror, entries)
	if mirror == "" then
		return ""
	end
	for port, entry in pairs(entries) do
		if entry.port == mirror then
			return port
		end
	end
	for port, entry in pairs(entries) do
		if entry.description == mirror then
			return port
		end
	end
	return ""
end

local function mode_gone(monitor, entry)
	return entry.mode and not entry.disabled and not mode_exists(entry.mode, monitor.available_modes)
end

local function saved_rule(monitor, entry, entries)
	local rule = automatic(monitor)
	for field in pairs(UNSET) do
		if entry[field] ~= nil then
			rule[field] = entry[field]
		end
	end
	rule.mode = entry.mode or rule.mode
	rule.position = entry.position or rule.position
	rule.scale = entry.scale or rule.scale
	rule.icc = entry.icc
	rule.mirror = mirror_port(rule.mirror, entries)
	return rule
end

local function check_monitor(entry)
	assert(type(entry) == "table" and type(entry.description) == "string", "a monitor has no description")
	for _, field in ipairs({ "mode", "position", "mirror", "port" }) do
		assert(entry[field] == nil or type(entry[field]) == "string", field .. " is not a string")
	end
end

local function check(data)
	assert(type(data) == "table" and type(data.setups) == "table", "no setups")
	assert(next(data.setups) == nil or #data.setups > 0, "setups is not a list")
	for _, setup in ipairs(data.setups) do
		assert(type(setup) == "table" and type(setup.monitors) == "table", "a setup has no monitors")
		assert(#setup.monitors > 0, "a setup has no monitors")
		for _, entry in ipairs(setup.monitors) do
			check_monitor(entry)
		end
	end
end

local function check_unkept(unkept)
	assert(type(unkept) == "table" and type(unkept.monitors) == "table", "unkept has no monitors")
	for _, entry in ipairs(unkept.monitors) do
		check_monitor(entry)
	end
	if unkept.before ~= nil then
		assert(type(unkept.before) == "string", "unkept has no text to go back to")
		check(json.decode(unkept.before))
	end
end

-- The saved setups in the file's text, or nil and why it can't be read. Third comes the file's
-- `unkept`, there while the shell tries a change out: { before, monitors }, the file's text before the
-- change, nil if there was no file, and the monitors' entries then.
function M.parse(text)
	local ok, data = pcall(json.decode, text)
	if ok then
		ok, data = pcall(function()
			check(data)
			if data.unkept ~= nil then
				check_unkept(data.unkept)
			end
			return data
		end)
	end
	if ok then
		return data.setups, nil, data.unkept
	end
	return nil, tostring(data)
end

-- The setups that put the monitors back as `unkept` says: the arrangement they were in comes first, as
-- it may never have been saved, then what was saved. For another combination that's just what's saved.
function M.going_back(unkept)
	local saved = { { monitors = unkept.monitors } }
	for _, setup in ipairs(unkept.before and M.parse(unkept.before) or {}) do
		saved[#saved + 1] = setup
	end
	return saved
end

-- Laptop ports are listed rather than external ones, so that a port nobody thought of can't lose its
-- picture. Also in the shell's MonitorEntries.js and scripts/import-monitor-setups.
local function is_laptop_port(port)
	return port:match("^eDP%-") or port:match("^LVDS%-") or port:match("^DSI%-")
end

-- With a closed lid and an external monitor, the laptop screen isn't part of the combination. With no
-- external monitor the lid means nothing here: what happens then is logind's.
local function split_by_lid(connected, lid_closed)
	local present, closed = {}, {}
	for i = 1, #connected do
		local monitor = connected[i]
		local list = (lid_closed and is_laptop_port(monitor.name)) and closed or present
		list[#list + 1] = monitor
	end
	if #present == 0 then
		return closed, {}
	end
	return present, closed
end

-- Monitors copying each other copy nothing, so a setup of those is as dark as one with all of them off.
local function shows_something(setup)
	for _, entry in ipairs(setup.monitors) do
		if not entry.disabled and (entry.mirror or "") == "" then
			return true
		end
	end
	return false
end

-- The rules for the connected monitors, always one per monitor and always by port, so a rule can't
-- reach a second identical monitor (Hyprland's desc: selector is a prefix match). Second comes the
-- description of each monitor that fell back to automatic because its saved mode is gone.
function M.rules_for(saved, connected, lid_closed)
	local present, closed = split_by_lid(connected, lid_closed)
	local setup = find_setup(saved, present)
	if setup and not shows_something(setup) then
		setup = nil
	end
	local entries = setup and pair(setup, present) or {}
	local rules, fell_back = {}, {}
	for i = 1, #present do
		local monitor = present[i]
		local entry = entries[monitor.name]
		if entry and mode_gone(monitor, entry) then
			fell_back[#fell_back + 1] = monitor.description
			entry = nil
		end
		rules[i] = entry and saved_rule(monitor, entry, entries) or automatic(monitor)
	end
	for i = 1, #closed do
		local rule = automatic(closed[i])
		rule.disabled = true
		rules[#rules + 1] = rule
	end
	return rules, fell_back
end

return M
