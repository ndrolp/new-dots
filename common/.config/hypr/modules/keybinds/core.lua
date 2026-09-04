local mainMod = "ALT"
local win = "SUPER"
local terminal = "kitty"

for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
for i = 11, 20 do
	local key = (i - 10) % 10
	hl.bind(win .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(win .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + SHIFT + q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + t", hl.dsp.window.float())
hl.bind(mainMod .. " + SHIFT + f", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(win .. " + SHIFT + S", hl.dsp.exec_cmd("~/.dotfiles/scripts/screenshots/basic.sh"))
hl.bind(mainMod .. " + SHIFT + e", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call power toggle"))
hl.bind(mainMod .. " + SHIFT + a", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call audio-sinks toggle"))
hl.bind(win .. " + t", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call themes toggle"))
hl.bind(mainMod .. " + SHIFT + r", hl.dsp.exec_cmd("~/.dotfiles/scripts/hyprland/reload.sh"))
hl.bind(mainMod .. " + r", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call command-launcher toggle"))
hl.bind(mainMod .. " + SHIFT + w", hl.dsp.exec_cmd("~/.dotfiles/scripts/hyprland/move_workspaces.sh"))
hl.bind(mainMod .. " + g", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call quick-search toggle"))
hl.bind(mainMod .. " + d", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call launcher toggle"))
hl.bind(mainMod .. " + v", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call clipboard toggle"))
hl.bind(mainMod .. " + p", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call config toggle"))
hl.bind(mainMod .. " + c", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call control-center toggle"))
hl.bind(mainMod .. " + n", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call notifications toggle"))
hl.bind(mainMod .. " + b", hl.dsp.exec_cmd("pypr expose"))
hl.bind(mainMod .. " + SHIFT + b", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call wallpapers toggle"))
hl.bind(mainMod .. " + SHIFT + x", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call screen-capture toggle"))
hl.bind(win .. " + b", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call workspace-overview toggle"))
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call window-switcher next"))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call window-switcher previous"))
hl.bind(win .. " + l", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))

hl.bind(
	mainMod .. " + SHIFT +  m",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd(
		"wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+; quickshell ipc --path ~/.config/quickshell call osd volume"
	),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd(
		"wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; quickshell ipc --path ~/.config/quickshell call osd volume"
	),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd(
		"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; quickshell ipc --path ~/.config/quickshell call osd volume"
	),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+; quickshell ipc --path ~/.config/quickshell call osd brightness"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-; quickshell ipc --path ~/.config/quickshell call osd brightness"),
	{ locked = true, repeating = true }
)

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
