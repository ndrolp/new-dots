local mainMod = "ALT"
local win = "SUPER"
local terminal = "kitty"
local qs = "quickshell ipc --path ~/.config/quickshell call "

for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Go to workspace " .. i })
	hl.bind(
		mainMod .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Move window to workspace " .. i }
	)
end
for i = 11, 20 do
	local key = (i - 10) % 10
	hl.bind(win .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Go to workspace " .. i })
	hl.bind(
		win .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Move window to workspace " .. i }
	)
end

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal), { description = "Open terminal" })
hl.bind(
	mainMod .. " + S",
	hl.dsp.workspace.toggle_special("magic"),
	{ description = "Toggle scratchpad workspace" }
)
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Pick a colour from the screen" })
hl.bind(
	mainMod .. " + SHIFT + S",
	hl.dsp.window.move({ workspace = "special:magic" }),
	{ description = "Move window to scratchpad" }
)
hl.bind(mainMod .. " + SHIFT + q", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + SHIFT + t", hl.dsp.window.float(), { description = "Toggle floating" })
hl.bind(mainMod .. " + SHIFT + f", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })
hl.bind(
	mainMod .. " + SHIFT + S",
	hl.dsp.window.move({ workspace = "special:magic" }),
	{ description = "Move window to scratchpad" }
)
hl.bind(
	win .. " + SHIFT + S",
	hl.dsp.exec_cmd("~/.dotfiles/scripts/screenshots/basic.sh"),
	{ description = "Take a screenshot" }
)
hl.bind(mainMod .. " + SHIFT + e", hl.dsp.exec_cmd(qs .. "power toggle"), { description = "Toggle power menu" })
hl.bind(
	mainMod .. " + SHIFT + a",
	hl.dsp.exec_cmd(qs .. "audio-sinks toggle"),
	{ description = "Toggle audio output picker" }
)
hl.bind(win .. " + t", hl.dsp.exec_cmd(qs .. "themes toggle"), { description = "Toggle theme picker" })
hl.bind(
	mainMod .. " + SHIFT + r",
	hl.dsp.exec_cmd("~/.dotfiles/scripts/hyprland/reload.sh"),
	{ description = "Reload Hyprland and shell" }
)
hl.bind(
	mainMod .. " + r",
	hl.dsp.exec_cmd(qs .. "command-launcher toggle"),
	{ description = "Toggle command launcher" }
)
hl.bind(
	mainMod .. " + SHIFT + w",
	hl.dsp.exec_cmd("~/.dotfiles/scripts/hyprland/move_workspaces.sh"),
	{ description = "Move workspaces between monitors" }
)
hl.bind(mainMod .. " + g", hl.dsp.exec_cmd(qs .. "quick-search toggle"), { description = "Toggle quick search" })
hl.bind(mainMod .. " + f", hl.dsp.exec_cmd(qs .. "unified-search toggle"), { description = "Toggle unified search" })
hl.bind(
	mainMod .. " + CTRL + 1",
	hl.dsp.exec_cmd(qs .. "bar-profiles minimal"),
	{ description = "Bar profile: minimal" }
)
hl.bind(mainMod .. " + CTRL + 2", hl.dsp.exec_cmd(qs .. "bar-profiles work"), { description = "Bar profile: work" })
hl.bind(mainMod .. " + CTRL + 3", hl.dsp.exec_cmd(qs .. "bar-profiles media"), { description = "Bar profile: media" })
hl.bind(
	mainMod .. " + CTRL + 4",
	hl.dsp.exec_cmd(qs .. "bar-profiles presentation"),
	{ description = "Bar profile: presentation" }
)
hl.bind(mainMod .. " + d", hl.dsp.exec_cmd(qs .. "launcher toggle"), { description = "Toggle app launcher" })
hl.bind(mainMod .. " + v", hl.dsp.exec_cmd(qs .. "clipboard toggle"), { description = "Toggle clipboard history" })
hl.bind(mainMod .. " + p", hl.dsp.exec_cmd(qs .. "config toggle"), { description = "Toggle shell settings" })
hl.bind(win .. " + p", hl.dsp.exec_cmd(qs .. "config toggle"), { description = "Toggle shell settings" })
hl.bind(mainMod .. " + c", hl.dsp.exec_cmd(qs .. "control-center toggle"), { description = "Toggle control center" })
hl.bind(mainMod .. " + q", hl.dsp.exec_cmd(qs .. "quick-settings toggle"), { description = "Toggle quick settings" })
hl.bind(mainMod .. " + n", hl.dsp.exec_cmd(qs .. "notifications toggle"), { description = "Toggle notifications" })
hl.bind(mainMod .. " + b", hl.dsp.exec_cmd("pypr expose"), { description = "Expose all windows" })
hl.bind(
	mainMod .. " + SHIFT + b",
	hl.dsp.exec_cmd(qs .. "wallpapers toggle"),
	{ description = "Toggle wallpaper picker" }
)
hl.bind(
	mainMod .. " + SHIFT + x",
	hl.dsp.exec_cmd(qs .. "screen-capture toggle"),
	{ description = "Toggle screen capture" }
)
hl.bind(
	win .. " + b",
	hl.dsp.exec_cmd(qs .. "workspace-overview toggle"),
	{ description = "Toggle workspace overview" }
)
hl.bind(
	mainMod .. " + TAB",
	hl.dsp.exec_cmd(qs .. "window-switcher next"),
	{ description = "Switch to next window" }
)
hl.bind(
	mainMod .. " + SHIFT + TAB",
	hl.dsp.exec_cmd(qs .. "window-switcher previous"),
	{ description = "Switch to previous window" }
)
hl.bind(win .. " + l", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock screen" })
-- Emergency lock: hyprlock, should the shell's lock screen fail. Locked, so it
-- still works while the session is locked and the shell has crashed.
hl.bind(
	win .. " + CTRL + ALT + l",
	hl.dsp.exec_cmd("hyprlock"),
	{ locked = true, description = "Emergency lock (hyprlock)" }
)
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { description = "Focus window left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Focus window right" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Focus window up" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Focus window down" })
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }), { description = "Focus window left" })
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }), { description = "Focus window right" })
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }), { description = "Focus window up" })
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }), { description = "Focus window down" })
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })

hl.bind(
	mainMod .. " + SHIFT +  m",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"),
	{ description = "Exit Hyprland" }
)

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+; " .. qs .. "osd volume"),
	{ locked = true, repeating = true, description = "Raise volume" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; " .. qs .. "osd volume"),
	{ locked = true, repeating = true, description = "Lower volume" }
)
hl.bind(
	"XF86PowerOff",
	hl.dsp.exec_cmd(qs .. "power toggle"),
	{ locked = true, repeating = true, description = "Toggle power menu" }
)

hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; " .. qs .. "osd volume"),
	{ locked = true, repeating = true, description = "Mute audio" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true, description = "Mute microphone" }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+; " .. qs .. "osd brightness"),
	{ locked = true, repeating = true, description = "Raise brightness" }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-; " .. qs .. "osd brightness"),
	{ locked = true, repeating = true, description = "Lower brightness" }
)

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause media" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause media" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })
