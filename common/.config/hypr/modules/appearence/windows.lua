-- How Hyprland draws windows, as the Windows section of the shell's settings saves it in one
-- machine-local file, ~/.config/hypr/window-appearance.json. Hyprland owns it the way it owns monitor
-- setups (docs/adr/0002-hyprland-owns-monitor-setups.md): the config applies it when it loads, and the
-- shell, after writing it, runs `require("modules.appearence.windows").apply()` over `hyprctl eval`,
-- which applies only this, without a full reload.
--
-- No file, or one that can't be read or isn't a JSON object, gives every default. A value that's
-- missing, of the wrong type or out of range gives that setting's default; the rest still apply. The
-- file is never moved aside: the shell's next change rewrites it.

local json = require("modules.monitors.json")

local M = {}

-- One entry per setting: its key in the file, the Hyprland option it sets (a dotted path; none for a
-- setting M.apply applies itself), what it takes and its default. Kinds: "integer" and "number"
-- between min and max, "boolean". Keep the keys, ranges and defaults in step with the shell's
-- services/WindowAppearance.js.
M.SETTINGS = {
	{ key = "gaps_in", option = "general.gaps_in", kind = "integer", min = 0, max = 30, default = 5 },
	{ key = "gaps_out", option = "general.gaps_out", kind = "integer", min = 0, max = 60, default = 10 },
	-- 0 hides the border. Its colours come from the colorscheme (borders.lua), which leaves the size alone.
	{ key = "border_size", option = "general.border_size", kind = "integer", min = 0, max = 6, default = 2 },
	{ key = "rounding", option = "decoration.rounding", kind = "integer", min = 0, max = 24, default = 5 },
	{ key = "active_opacity", option = "decoration.active_opacity", kind = "number", min = 0.5, max = 1, default = 1.0 },
	{ key = "inactive_opacity", option = "decoration.inactive_opacity", kind = "number", min = 0.3, max = 1, default = 0.9 },
	{ key = "shadows", option = "decoration.shadow.enabled", kind = "boolean", default = true },
	{ key = "window_blur", kind = "boolean", default = true },
	{ key = "blur_size", option = "decoration.blur.size", kind = "integer", min = 1, max = 15, default = 7 },
}

local function default_path()
	local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
	return config .. "/hypr/window-appearance.json"
end

local function valid(setting, value)
	if setting.kind == "boolean" then
		return type(value) == "boolean"
	end
	if type(value) ~= "number" or value ~= value or value < setting.min or value > setting.max then
		return false
	end
	return setting.kind ~= "integer" or value == math.floor(value)
end

-- The saved values as a table, or nil when there are none to use.
local function load_saved(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local text = file:read("*a")
	file:close()
	if not text then
		return nil
	end
	local ok, saved = pcall(json.decode, text)
	if not ok or type(saved) ~= "table" or saved[1] ~= nil then
		return nil
	end
	return saved
end

-- Every setting's value, by key: the saved one where it's usable, its default otherwise.
function M.values(path)
	local saved = load_saved(path or default_path()) or {}
	local values = {}
	for _, setting in ipairs(M.SETTINGS) do
		local value = saved[setting.key]
		if valid(setting, value) then
			values[setting.key] = value
		else
			values[setting.key] = setting.default
		end
	end
	return values
end

-- What hl.config takes for `values`: each setting's option path filled in.
function M.config(values)
	local config = {}
	for _, setting in ipairs(M.SETTINGS) do
		if not setting.option then
			goto continue
		end
		local at = config
		local path = {}
		for part in setting.option:gmatch("[^.]+") do
			path[#path + 1] = part
		end
		for i = 1, #path - 1 do
			at[path[i]] = at[path[i]] or {}
			at = at[path[i]]
		end
		at[path[#path]] = values[setting.key]
		::continue::
	end
	return config
end

-- Reads the saved file (by default ~/.config/hypr/window-appearance.json) and hands Hyprland the result.
function M.apply(path)
	local values = M.values(path)
	hl.config(M.config(values))
	M.apply_window_blur(values.window_blur)
end

-- Window blur off is a window rule turning blur off for every window, not decoration.blur.enabled,
-- so the shell's layers (the bar, the capsule, popups) keep their blur (modules/rules/apps.lua). The
-- rule is made once per config load and switched on or off after that, so applying again over
-- `hyprctl eval` never stacks rules; a reload starts a fresh Lua state, and with it a fresh rule.
-- set_enabled re-evaluates the rules of every open window itself (Hyprland 0.57's LuaWindowRule.cpp
-- calls ruleEngine()->updateAllRules()), so windows already open follow the switch.
local window_blur_rule
function M.apply_window_blur(on)
	if window_blur_rule then
		window_blur_rule:set_enabled(not on)
	else
		window_blur_rule = hl.window_rule({
			name = "ndro-window-blur-off",
			match = { class = ".*" },
			enabled = not on,
			no_blur = true,
		})
	end
end

return M
