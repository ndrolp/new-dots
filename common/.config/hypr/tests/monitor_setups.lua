-- Tests for monitor setups, run under plain Lua by monitor-setups.sh. Nothing here needs Hyprland:
-- matching is plain Lua, and the part that talks to Hyprland runs against a stubbed `hl`.

local hypr = arg[1]
local filter = arg[2] or ""
package.path = hypr .. "/?.lua"

local setups = require("modules.monitors.setups")

local tests = {}
local function test(name, body)
	tests[#tests + 1] = { name = name, body = body }
end

local function equal(actual, expected, what)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", what, tostring(expected), tostring(actual)), 2)
	end
end

local LAPTOP = "Samsung Display Corp. ATNA40HQ01-0"
local AOC = "AOC Q27G42XE 2S6S1HA031479"

local function monitor(name, description, modes)
	return {
		name = name,
		description = description,
		available_modes = modes or { { width = 2560, height = 1440, refresh_rate = 143.91 } },
	}
end

local function rule_for(rules, output)
	for _, rule in ipairs(rules) do
		if rule.output == output then
			return rule
		end
	end
	error("no rule for " .. output, 2)
end

test("with no setups a monitor extends right at its highest resolution", function()
	local rules = setups.rules_for({}, { monitor("eDP-1", LAPTOP) })
	equal(#rules, 1, "rules")
	equal(rules[1].output, "eDP-1", "output")
	equal(rules[1].mode, "highres", "mode")
	equal(rules[1].position, "auto", "position")
	equal(rules[1].scale, "auto", "scale")
end)

local DOCKED = {
	monitors = {
		{ description = LAPTOP, port = "eDP-1", disabled = true },
		{
			description = AOC,
			port = "DP-2",
			mode = "2560x1440@143.91",
			position = "1600x0",
			scale = 1.25,
			transform = 1,
			vrr = 1,
			bitdepth = 10,
		},
	},
}

test("a setup applies to its combination", function()
	local rules = setups.rules_for({ DOCKED }, { monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) })
	equal(rule_for(rules, "eDP-1").disabled, true, "laptop disabled")
	local aoc = rule_for(rules, "DP-2")
	equal(aoc.mode, "2560x1440@143.91", "mode")
	equal(aoc.position, "1600x0", "position")
	equal(aoc.scale, 1.25, "scale")
	equal(aoc.transform, 1, "transform")
	equal(aoc.vrr, 1, "vrr")
	equal(aoc.bitdepth, 10, "bitdepth")
end)

test("a combination matches regardless of port", function()
	local rules = setups.rules_for({ DOCKED }, { monitor("DP-7", AOC), monitor("eDP-2", LAPTOP) })
	equal(rule_for(rules, "DP-7").position, "1600x0", "the AOC on a new port")
	equal(rule_for(rules, "eDP-2").disabled, true, "the laptop on a new port")
end)

test("a subset or superset of a setup's monitors is a different combination", function()
	local alone = setups.rules_for({ DOCKED }, { monitor("DP-2", AOC) })
	equal(rule_for(alone, "DP-2").mode, "highres", "fewer monitors")
	local more = setups.rules_for({ DOCKED }, {
		monitor("eDP-1", LAPTOP),
		monitor("DP-2", AOC),
		monitor("DP-3", "Other"),
	})
	equal(rule_for(more, "DP-2").mode, "highres", "more monitors")
end)

test("identical monitors are told apart by port", function()
	local twins = {
		monitors = {
			{ description = AOC, port = "DP-1", position = "0x0" },
			{ description = AOC, port = "DP-2", position = "2560x0" },
		},
	}
	local rules = setups.rules_for({ twins }, { monitor("DP-2", AOC), monitor("DP-1", AOC) })
	equal(rule_for(rules, "DP-1").position, "0x0", "DP-1")
	equal(rule_for(rules, "DP-2").position, "2560x0", "DP-2")
end)

test("identical monitors that moved ports still get a setup each", function()
	local twins = {
		monitors = {
			{ description = AOC, port = "DP-1", position = "0x0" },
			{ description = AOC, port = "DP-2", position = "2560x0" },
		},
	}
	local rules = setups.rules_for({ twins }, { monitor("DP-2", AOC), monitor("DP-5", AOC) })
	equal(rule_for(rules, "DP-2").position, "2560x0", "the one still on its port")
	equal(rule_for(rules, "DP-5").position, "0x0", "the one that moved")
end)

-- Hyprland starts each rule from the last one for that output, so anything left out carries over.
test("every rule writes rotation, disabled and mirroring", function()
	local plain = { monitors = { { description = AOC, port = "DP-2", mode = "2560x1440@143.91" } } }
	for _, rule in ipairs({
		setups.rules_for({}, { monitor("DP-2", AOC) })[1],
		setups.rules_for({ plain }, { monitor("DP-2", AOC) })[1],
	}) do
		equal(rule.transform, 0, "transform")
		equal(rule.disabled, false, "disabled")
		equal(rule.mirror, "", "mirror")
		equal(rule.vrr, -1, "vrr")
		equal(rule.bitdepth, 8, "bitdepth")
		equal(rule.cm, "srgb", "cm")
		equal(rule.sdr_eotf, "default", "sdr_eotf")
		equal(rule.sdrbrightness, 1, "sdrbrightness")
		equal(rule.sdrsaturation, 1, "sdrsaturation")
		equal(rule.supports_wide_color, 0, "supports_wide_color")
		equal(rule.supports_hdr, 0, "supports_hdr")
		equal(rule.sdr_min_luminance, 0.2, "sdr_min_luminance")
		equal(rule.sdr_max_luminance, 80, "sdr_max_luminance")
		equal(rule.min_luminance, -1, "min_luminance")
		equal(rule.max_luminance, -1, "max_luminance")
		equal(rule.max_avg_luminance, -1, "max_avg_luminance")
		equal(rule.reserved, 0, "reserved")
	end
end)

test("a field Hyprland doesn't know is not passed to it", function()
	local future = { monitors = { { description = AOC, port = "DP-2", brightness = 40 } } }
	equal(setups.rules_for({ future }, { monitor("DP-2", AOC) })[1].brightness, nil, "unknown field")
end)

-- Hyprland reports an error for an empty icc, so it can only be written when there is one.
test("icc is written only when a setup has one", function()
	local with = { monitors = { { description = AOC, port = "DP-2", icc = "/tmp/a.icc" } } }
	equal(setups.rules_for({ with }, { monitor("DP-2", AOC) })[1].icc, "/tmp/a.icc", "saved")
	equal(setups.rules_for({}, { monitor("DP-2", AOC) })[1].icc, nil, "automatic")
end)

test("a mirror names a monitor by description and is applied by port", function()
	local mirrored = {
		monitors = {
			{ description = LAPTOP, port = "eDP-1", mirror = AOC },
			{ description = AOC, port = "DP-2" },
		},
	}
	local rules = setups.rules_for({ mirrored }, { monitor("eDP-1", LAPTOP), monitor("DP-9", AOC) })
	equal(rule_for(rules, "eDP-1").mirror, "DP-9", "mirror target")
	equal(rule_for(rules, "DP-9").mirror, "", "the mirrored monitor copies nothing")
end)

test("what the quick switch keeps for a mirror stays out of its rule", function()
	local mirrored = {
		monitors = {
			{
				description = AOC,
				port = "DP-2",
				mirror = LAPTOP,
				mode = "preferred",
				scale = 1,
				arrangement = { mode = "2560x1440@143.91", position = "1800x0", scale = 1 },
			},
			{ description = LAPTOP, port = "eDP-1", mode = "preferred", position = "0x0", scale = 1 },
		},
	}
	local rules = setups.rules_for({ mirrored }, { monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) })
	equal(rule_for(rules, "DP-2").arrangement, nil, "arrangement")
	equal(rule_for(rules, "DP-2").mode, "preferred", "mode")
	equal(rule_for(rules, "DP-2").mirror, "eDP-1", "mirror target")
end)

test("a mirror of one of two identical monitors names it by port", function()
	local mirrored = {
		monitors = {
			{ description = AOC, port = "DP-1", mirror = "DP-2" },
			{ description = AOC, port = "DP-2" },
		},
	}
	local rules = setups.rules_for({ mirrored }, { monitor("DP-1", AOC), monitor("DP-2", AOC) })
	equal(rule_for(rules, "DP-1").mirror, "DP-2", "mirror target")
end)

local EXTERNAL_ONLY = {
	monitors = {
		{ description = AOC, port = "DP-2", mode = "2560x1440@143.91", position = "0x0", scale = 1.5 },
	},
}

test("a closed lid with an external monitor is the combination without the laptop screen", function()
	local rules = setups.rules_for({ DOCKED, EXTERNAL_ONLY }, { monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) }, true)
	equal(#rules, 2, "rules")
	equal(rule_for(rules, "DP-2").scale, 1.5, "the setup of the external monitor alone")
	equal(rule_for(rules, "eDP-1").disabled, true, "the laptop screen goes off")
end)

test("a closed lid with no external monitor changes nothing", function()
	local laptop = { monitor("eDP-1", LAPTOP) }
	local rules = setups.rules_for({}, laptop, true)
	equal(#rules, 1, "rules")
	equal(rules[1].disabled, false, "the laptop screen stays on")
end)

test("the laptop screen off for a closed lid still writes every field", function()
	local rules = setups.rules_for({}, { monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) }, true)
	equal(rule_for(rules, "eDP-1").transform, 0, "transform")
	equal(rule_for(rules, "eDP-1").mirror, "", "mirror")
end)

test("a saved mode that no longer exists makes only that monitor automatic", function()
	local rules = setups.rules_for({ DOCKED }, {
		monitor("eDP-1", LAPTOP),
		monitor("DP-2", AOC, { { width = 1920, height = 1080, refresh_rate = 60 } }),
	})
	local aoc = rule_for(rules, "DP-2")
	equal(aoc.mode, "highres", "mode")
	equal(aoc.position, "auto", "position")
	equal(aoc.scale, "auto", "scale")
	equal(aoc.transform, 0, "transform")
	equal(rule_for(rules, "eDP-1").disabled, true, "the other monitor keeps its setup")
end)

test("a saved mode matches within Hyprland's 1Hz tolerance", function()
	local rounded = { monitors = { { description = AOC, port = "DP-2", mode = "2560x1440@144.00" } } }
	equal(setups.rules_for({ rounded }, { monitor("DP-2", AOC) })[1].mode, "2560x1440@144.00", "mode")
end)

test("a saved mode without a refresh rate needs only the resolution", function()
	local sized = { monitors = { { description = AOC, port = "DP-2", mode = "2560x1440" } } }
	equal(setups.rules_for({ sized }, { monitor("DP-2", AOC) })[1].mode, "2560x1440", "mode")
end)

test("a keyword mode always exists", function()
	local keyword = { monitors = { { description = AOC, port = "DP-2", mode = "preferred" } } }
	equal(setups.rules_for({ keyword }, { monitor("DP-2", AOC) })[1].mode, "preferred", "mode")
end)

test("a disabled monitor keeps its setup whatever modes it has", function()
	local off = { monitors = { { description = AOC, port = "DP-2", mode = "640x480@60", disabled = true } } }
	equal(setups.rules_for({ off }, { monitor("DP-2", AOC) })[1].disabled, true, "disabled")
end)

local SAVED_DOCKED = [[
{
  "setups": [
    {
      "monitors": [
        { "description": "Samsung Display Corp. ATNA40HQ01-0", "port": "eDP-1", "disabled": true },
        {
          "description": "AOC Q27G42XE 2S6S1HA031479",
          "port": "DP-2",
          "mode": "2560x1440@143.91",
          "position": "1600x0",
          "scale": 1.25,
          "transform": 1,
          "vrr": 0,
          "bitdepth": 10,
          "mirror": ""
        }
      ]
    }
  ]
}
]]

test("a saved file reads back as setups", function()
	local saved = setups.parse(SAVED_DOCKED)
	local rules = setups.rules_for(saved, { monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) })
	equal(rule_for(rules, "eDP-1").disabled, true, "disabled")
	equal(rule_for(rules, "DP-2").position, "1600x0", "position")
	equal(rule_for(rules, "DP-2").scale, 1.25, "scale")
	equal(rule_for(rules, "DP-2").vrr, 0, "vrr")
end)

-- Hyprland rejects 1.0 for an integer field.
test("whole numbers read back as integers", function()
	local saved = setups.parse('{"setups":[{"monitors":[{"description":"a","transform":1.0,"vrr":0}]}]}')
	equal(math.type(saved[1].monitors[1].transform), "integer", "transform")
	equal(math.type(saved[1].monitors[1].vrr), "integer", "vrr")
end)

test("escapes in a description read back", function()
	local saved = setups.parse([[{"setups":[{"monitors":[{"description":"a\"b\\cé"}]}]}]])
	equal(saved[1].monitors[1].description, 'a"b\\c\u{e9}', "description")
end)

test("a file with no setups is valid", function()
	equal(#setups.parse('{"setups":[]}'), 0, "setups")
end)

test("anything else can't be read", function()
	for _, text in ipairs({
		"",
		"{",
		"[]",
		"garbage",
		'{"setups":{"a":1}}',
		'{"setups":[{}]}',
		'{"setups":[{"monitors":[{}]}]}',
		'{"setups":[{"monitors":[{"description":"a"}]}]} trailing',
		'{"setups":[{"monitors":[{"description":"a","mode":1}]}]}',
		'{"setups":[{"monitors":[{"description":"a","mirror":1}]}]}',
	}) do
		local saved, reason = setups.parse(text)
		equal(saved, nil, "setups from " .. text)
		equal(type(reason), "string", "reason for " .. text)
	end
end)

-- The part that talks to Hyprland, against a stubbed `hl`. `session` plays Hyprland: its list of
-- monitors can change between events, and timers only run when settle() says so.
local function new_session(monitors)
	local session = { monitors = monitors, applied = {}, handlers = {}, timers = {}, binds = {} }
	hl = {
		get_monitors = function(options)
			local listed = {}
			for _, m in ipairs(session.monitors) do
				if (options and options.all) or not m.off then
					listed[#listed + 1] = m
				end
			end
			return listed
		end,
		monitor = function(rule)
			session.applied[#session.applied + 1] = rule
		end,
		on = function(event, handler)
			session.handlers[event] = handler
		end,
		bind = function(keys, handler, options)
			session.binds[keys] = { handler = handler, options = options }
		end,
		timer = function(callback, options)
			equal(options.type, "oneshot", "timer type")
			equal(options.timeout > 0, true, "Hyprland refuses a timeout of 0")
			session.timers[#session.timers + 1] = callback
		end,
	}
	function session.fire(event)
		session.handlers[event]()
	end
	-- Hyprland only says the lid moved. The state is in the files install() was told to read.
	function session.flip_lid()
		session.binds["switch:Lid Switch"].handler()
	end
	function session.settle()
		local timers = session.timers
		session.timers = {}
		for _, callback in ipairs(timers) do
			callback()
		end
	end
	return session
end

local function temp_path(contents)
	local path = os.tmpname()
	os.remove(path)
	if contents then
		local file = assert(io.open(path, "w"))
		file:write(contents)
		file:close()
	end
	return path
end

local function read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local contents = file:read("*a")
	file:close()
	return contents
end

-- Tests have no lid unless they ask for one, whatever this machine's lid is doing.
local function install(options)
	options.lid_states = options.lid_states or "/nonexistent/lid/*/state"
	package.loaded["modules.monitors.apply"] = nil
	require("modules.monitors.apply").install(options)
end

local function apply_test(name, body)
	test(name, function()
		local path = temp_path()
		body(path)
		os.remove(path)
		os.remove(path .. ".bad")
	end)
end

apply_test("with no file every connected monitor gets the automatic rule", function(path)
	local session = new_session({ monitor("eDP-1", LAPTOP) })
	install({ path = path })
	equal(#session.applied, 1, "rules at startup")
	equal(session.applied[1].mode, "highres", "mode")
	equal(session.applied[1].position, "auto", "position")
end)

apply_test("a setup applies when the config loads", function(path)
	local session = new_session({ monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) })
	local file = assert(io.open(path, "w"))
	file:write(SAVED_DOCKED)
	file:close()
	install({ path = path })
	equal(rule_for(session.applied, "DP-2").position, "1600x0", "position")
	equal(rule_for(session.applied, "eDP-1").disabled, true, "disabled")
end)

-- Hyprland starts with no monitors when the config first loads.
apply_test("a setup applies when the monitors appear after the config", function(path)
	local session = new_session({})
	local file = assert(io.open(path, "w"))
	file:write(SAVED_DOCKED)
	file:close()
	install({ path = path })
	equal(#session.applied, 0, "rules with no monitors")
	session.monitors = { monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) }
	session.fire("monitor.added")
	session.settle()
	equal(rule_for(session.applied, "DP-2").position, "1600x0", "position")
end)

apply_test("nothing is read while no monitors are connected", function(path)
	local bad = assert(io.open(path, "w"))
	bad:write("garbage")
	bad:close()
	new_session({})
	install({ path = path })
	equal(read_file(path), "garbage", "the file")
	equal(read_file(path .. ".bad"), nil, "the backup")
end)

apply_test("a hotplug applies the setup of the new combination", function(path)
	local session = new_session({ monitor("eDP-1", LAPTOP) })
	local file = assert(io.open(path, "w"))
	file:write(SAVED_DOCKED)
	file:close()
	install({ path = path })
	equal(rule_for(session.applied, "eDP-1").disabled, false, "alone, the laptop stays on")
	session.applied = {}
	session.monitors[2] = monitor("DP-2", AOC)
	session.fire("monitor.added")
	session.settle()
	equal(rule_for(session.applied, "eDP-1").disabled, true, "docked, the laptop goes off")
	equal(rule_for(session.applied, "DP-2").position, "1600x0", "docked position")
end)

-- monitor.removed fires while the monitor is still listed, so reading the list then gets it wrong.
apply_test("an unplug is worked out once Hyprland has dropped the monitor", function(path)
	local session = new_session({ monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) })
	local file = assert(io.open(path, "w"))
	file:write(SAVED_DOCKED)
	file:close()
	install({ path = path })
	session.applied = {}
	session.fire("monitor.removed")
	session.monitors[2] = nil
	session.settle()
	equal(#session.applied, 1, "rules")
	equal(session.applied[1].output, "eDP-1", "output")
	equal(session.applied[1].disabled, false, "the laptop comes back on")
end)

-- Turning a monitor off fires monitor.removed, but it's still connected.
apply_test("a monitor a setup turned off still counts as connected", function(path)
	local laptop = monitor("eDP-1", LAPTOP)
	local session = new_session({ laptop, monitor("DP-2", AOC) })
	local file = assert(io.open(path, "w"))
	file:write(SAVED_DOCKED)
	file:close()
	install({ path = path })
	laptop.off = true
	session.applied = {}
	session.fire("monitor.removed")
	session.settle()
	equal(#session.applied, 0, "rules written for the same setup")
end)

apply_test("several events at once are worked out once", function(path)
	local session = new_session({ monitor("eDP-1", LAPTOP) })
	install({ path = path })
	session.fire("monitor.added")
	session.fire("monitor.added")
	session.fire("monitor.removed")
	equal(#session.timers, 1, "timers")
end)

apply_test("a file that can't be read gives the automatic setup and is kept", function(path)
	local bad = assert(io.open(path, "w"))
	bad:write("{ not json")
	bad:close()
	local session = new_session({ monitor("eDP-1", LAPTOP) })
	install({ path = path })
	equal(#session.applied, 1, "rules")
	equal(session.applied[1].mode, "highres", "mode")
	equal(read_file(path .. ".bad"), "{ not json", "the backup")
	equal(read_file(path), nil, "the bad file")
end)

apply_test("a path that can't be opened as a file gives the automatic setup", function(path)
	assert(os.execute("mkdir " .. path))
	local session = new_session({ monitor("eDP-1", LAPTOP) })
	install({ path = path })
	equal(session.applied[1].mode, "highres", "mode")
	assert(os.execute("rmdir " .. path .. ".bad"))
end)

-- The shell writes the file, then asks over `hyprctl eval` for it to be read. No event fires for that.
apply_test("apply_now applies the file as it is now", function(path)
	local session = new_session({ monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) })
	install({ path = path })
	local file = assert(io.open(path, "w"))
	file:write(SAVED_DOCKED)
	file:close()
	session.applied = {}
	require("modules.monitors.apply").apply_now()
	equal(rule_for(session.applied, "DP-2").position, "1600x0", "position")
end)

-- The shell keeps what to go back to in the file while a change waits for Keep or Revert.
apply_test("a setup the shell is still trying out applies like any other", function(path)
	local session = new_session({ monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) })
	install({ path = path })
	local trying = SAVED_DOCKED:gsub("^%s*{", '{ "unkept": { "before": "{\\"setups\\": []}\\n", "monitors": [] },', 1)
	local file = assert(io.open(path, "w"))
	file:write(trying)
	file:close()
	session.applied = {}
	require("modules.monitors.apply").apply_now()
	equal(rule_for(session.applied, "DP-2").position, "1600x0", "position")
	equal(read_file(path .. ".bad"), nil, "the backup")
end)

-- A folder laid out like /proc/acpi/button/lid, whose state a test can change.
local function fake_lid(state)
	local folder = temp_path()
	assert(os.execute("mkdir -p " .. folder .. "/LID0"))
	local lid = { states = folder .. "/*/state" }
	function lid.set(new_state)
		local file = assert(io.open(folder .. "/LID0/state", "w"))
		file:write("state:      " .. new_state .. "\n")
		file:close()
	end
	function lid.remove()
		assert(os.execute("rm -r " .. folder))
	end
	lid.set(state)
	return lid
end

local function write_saved(path, contents)
	local file = assert(io.open(path, "w"))
	file:write(contents)
	file:close()
end

local LID_SETUPS = [[{"setups": [
	{"monitors": [{"description": "Samsung Display Corp. ATNA40HQ01-0", "port": "eDP-1", "position": "0x0"},
	              {"description": "AOC Q27G42XE 2S6S1HA031479", "port": "DP-2", "position": "1600x0"}]},
	{"monitors": [{"description": "AOC Q27G42XE 2S6S1HA031479", "port": "DP-2", "position": "0x0"}]}
]}]]

apply_test("closing and opening the lid applies the matching setup", function(path)
	write_saved(path, LID_SETUPS)
	local lid = fake_lid("open")
	local session = new_session({ monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) })
	install({ path = path, lid_states = lid.states })
	equal(rule_for(session.applied, "DP-2").position, "1600x0", "open, beside the laptop")

	session.applied = {}
	lid.set("closed")
	session.flip_lid()
	session.settle()
	equal(rule_for(session.applied, "eDP-1").disabled, true, "closed, the laptop screen goes off")
	equal(rule_for(session.applied, "DP-2").position, "0x0", "closed, the external monitor alone")

	session.applied = {}
	lid.set("open")
	session.flip_lid()
	session.settle()
	equal(rule_for(session.applied, "eDP-1").disabled, false, "open again, the laptop screen is back")
	equal(rule_for(session.applied, "DP-2").position, "1600x0", "open again, beside the laptop")
	lid.remove()
end)

apply_test("with no external monitor the lid writes no rule", function(path)
	write_saved(path, LID_SETUPS)
	local lid = fake_lid("open")
	local session = new_session({ monitor("eDP-1", LAPTOP) })
	install({ path = path, lid_states = lid.states })
	session.applied = {}
	lid.set("closed")
	session.flip_lid()
	session.settle()
	lid.set("open")
	session.flip_lid()
	session.settle()
	equal(#session.applied, 0, "rules written")
	lid.remove()
end)

-- A reload runs the config again, and no switch event comes with it.
apply_test("a config load with the lid already closed keeps the laptop screen off", function(path)
	write_saved(path, LID_SETUPS)
	local lid = fake_lid("closed")
	local session = new_session({ monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) })
	install({ path = path, lid_states = lid.states })
	equal(rule_for(session.applied, "eDP-1").disabled, true, "laptop screen")
	lid.remove()
end)

apply_test("plugging a monitor into a closed laptop turns the laptop screen off", function(path)
	write_saved(path, LID_SETUPS)
	local lid = fake_lid("closed")
	local session = new_session({ monitor("eDP-1", LAPTOP) })
	install({ path = path, lid_states = lid.states })
	session.applied = {}
	session.monitors[2] = monitor("DP-2", AOC)
	session.fire("monitor.added")
	session.settle()
	equal(rule_for(session.applied, "eDP-1").disabled, true, "laptop screen")
	lid.remove()
end)

apply_test("unplugging the last external monitor from a closed laptop brings its screen back", function(path)
	write_saved(path, LID_SETUPS)
	local lid = fake_lid("closed")
	local session = new_session({ monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) })
	install({ path = path, lid_states = lid.states })
	session.applied = {}
	session.monitors[2] = nil
	session.fire("monitor.removed")
	session.settle()
	equal(rule_for(session.applied, "eDP-1").disabled, false, "laptop screen")
	lid.remove()
end)

apply_test("a machine with no lid counts as open", function(path)
	write_saved(path, LID_SETUPS)
	local session = new_session({ monitor("eDP-1", LAPTOP), monitor("DP-2", AOC) })
	install({ path = path })
	equal(rule_for(session.applied, "eDP-1").disabled, false, "laptop screen")
end)

-- Closing the lid has to count while locked, under a fullscreen game inhibiting shortcuts, in a submap
-- and with a key held down.
apply_test("the lid counts whatever else is going on", function(path)
	local session = new_session({ monitor("eDP-1", LAPTOP) })
	install({ path = path })
	local options = session.binds["switch:Lid Switch"].options
	equal(options.locked, true, "locked")
	equal(options.dont_inhibit, true, "dont_inhibit")
	equal(options.ignore_mods, true, "ignore_mods")
	equal(options.submap_universal, true, "submap_universal")
end)

-- monitor-setups.sh points HOME at an empty folder, so there's no saved file here.
test("the config applies setups by itself, at startup and on hotplug", function()
	local session = new_session({ monitor("eDP-1", LAPTOP) })
	local anything = setmetatable({}, {})
	getmetatable(anything).__index = function()
		return anything
	end
	getmetatable(anything).__call = function()
		return anything
	end
	setmetatable(hl, { __index = anything })
	dofile(hypr .. "/hyprland.lua")
	equal(rule_for(session.applied, "eDP-1").mode, "highres", "the laptop at startup")
	session.monitors[2] = monitor("DP-2", AOC)
	session.fire("monitor.added")
	session.settle()
	equal(rule_for(session.applied, "DP-2").mode, "highres", "the new monitor")
end)

local failed = 0
local ran = 0
for _, t in ipairs(tests) do
	if t.name:find(filter, 1, true) then
		ran = ran + 1
		local ok, err = pcall(t.body)
		print((ok and "ok    " or "FAIL  ") .. t.name)
		if not ok then
			failed = failed + 1
			print("      " .. tostring(err))
		end
	end
end
print(string.format("passed: %d, failed: %d", ran - failed, failed))
os.exit(failed == 0)
