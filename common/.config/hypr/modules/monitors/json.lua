-- A small JSON reader: Hyprland's Lua has none, and the shell writes monitor setups as JSON. decode()
-- raises an error on anything that isn't one JSON value. Objects and arrays are both Lua tables, and
-- null becomes nil.

local ESCAPES = {
	['"'] = '"',
	["\\"] = "\\",
	["/"] = "/",
	b = "\b",
	f = "\f",
	n = "\n",
	r = "\r",
	t = "\t",
}

local read_value

local function skip_space(text, at)
	return text:find("[^ \t\r\n]", at) or #text + 1
end

local function read_string(text, at)
	local out = {}
	at = at + 1
	while true do
		local stop = text:find('["\\]', at)
		assert(stop, "unterminated string")
		out[#out + 1] = text:sub(at, stop - 1)
		if text:sub(stop, stop) == '"' then
			return table.concat(out), stop + 1
		end
		local escape = text:sub(stop + 1, stop + 1)
		if escape == "u" then
			local code = tonumber(text:sub(stop + 2, stop + 5), 16)
			assert(code, "bad unicode escape")
			out[#out + 1] = utf8.char(code)
			at = stop + 6
		else
			assert(ESCAPES[escape], "bad escape")
			out[#out + 1] = ESCAPES[escape]
			at = stop + 2
		end
	end
end

local function read_number(text, at)
	local literal = text:match("^-?%d+%.?%d*[eE]?[+-]?%d*", at)
	assert(literal, "unexpected character at " .. at)
	local number = tonumber(literal)
	assert(number, "bad number at " .. at)
	return math.tointeger(number) or number, at + #literal
end

local function read_array(text, at)
	local array = {}
	at = skip_space(text, at + 1)
	if text:sub(at, at) == "]" then
		return array, at + 1
	end
	while true do
		array[#array + 1], at = read_value(text, at)
		at = skip_space(text, at)
		local separator = text:sub(at, at)
		if separator == "]" then
			return array, at + 1
		end
		assert(separator == ",", "expected , or ] at " .. at)
		at = at + 1
	end
end

local function read_object(text, at)
	local object = {}
	at = skip_space(text, at + 1)
	if text:sub(at, at) == "}" then
		return object, at + 1
	end
	while true do
		at = skip_space(text, at)
		assert(text:sub(at, at) == '"', "expected a key at " .. at)
		local key
		key, at = read_string(text, at)
		at = skip_space(text, at)
		assert(text:sub(at, at) == ":", "expected : at " .. at)
		object[key], at = read_value(text, at + 1)
		at = skip_space(text, at)
		local separator = text:sub(at, at)
		if separator == "}" then
			return object, at + 1
		end
		assert(separator == ",", "expected , or } at " .. at)
		at = at + 1
	end
end

function read_value(text, at)
	at = skip_space(text, at)
	local first = text:sub(at, at)
	if first == "{" then
		return read_object(text, at)
	elseif first == "[" then
		return read_array(text, at)
	elseif first == '"' then
		return read_string(text, at)
	elseif text:sub(at, at + 3) == "true" then
		return true, at + 4
	elseif text:sub(at, at + 4) == "false" then
		return false, at + 5
	elseif text:sub(at, at + 3) == "null" then
		return nil, at + 4
	end
	return read_number(text, at)
end

local M = {}

function M.decode(text)
	local value, at = read_value(text, 1)
	assert(skip_space(text, at) > #text, "trailing text at " .. at)
	return value
end

return M
