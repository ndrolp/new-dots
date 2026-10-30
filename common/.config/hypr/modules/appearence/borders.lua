-- Window borders in the current colorscheme's colours: custom/colors.lua is linked to the chosen
-- colorscheme's hypr/colors.lua by colorschemes/colorscheme_changer.sh. Hyprland clears user
-- modules from package.loaded on every reload, so a switched link is picked up without a restart.
-- Without usable colours (fresh checkout, broken link) the borders fall back to the old greys.

local function hex_digits(value)
	return type(value) == "string" and value:match("^#?(%x%x%x%x%x%x)$")
end

local active, inactive = "rgba(535353ee)", "rgba(2b2b2baa)"

local ok, colors = pcall(require, "custom.colors")
if ok and type(colors) == "table" and hex_digits(colors.accent) and hex_digits(colors.border) then
	active = "rgb(" .. hex_digits(colors.accent) .. ")"
	inactive = "rgb(" .. hex_digits(colors.border) .. ")"
end

hl.config({
	general = {
		border_size = 2,
		col = {
			active_border = active,
			inactive_border = inactive,
		},
	},
})
