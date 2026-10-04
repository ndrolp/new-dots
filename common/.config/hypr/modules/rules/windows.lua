hl.window_rule({
	name = "allways-float",
	match = {
		class = "yad|ristretto|waypaper|org.gnome.Calculator|blueman|protonvpn-app|blueman-manager|nm-connection-editor|pavucontrol-qt|vlc",
	},
	float = true,
})

hl.layer_rule({
	name = "add-blur",
	match = { class = "wofi|eww|tofi|Tofi|eww-volume|mako|swaync|swaync-client" },
	blur = true,
})

hl.layer_rule({
	name = "remove-blur",
	match = { class = "slurp" },
	blur = false,
})

hl.window_rule({
	name = "transparent",
	match = {
		class = "nemo|Spotify|md.obsidian.Obsidian",
	},
	opacity = 0.9,
})

hl.window_rule({
	name = "to-workspace-2",
	match = {
		class = "firefox|qutebrowser|Brave-browser|chromium|google-chrome|vivaldi|microsoft-edge|librewolf|waterfox",
	},
	workspace = 2,
})

hl.window_rule({
	name = "to-workspace-4",
	match = {
		class = "discord|dmd.obsidian.Obsidian|obsidian|Obsidian|obsidian-app|obsidian-app-qt|obsidian-app-qt5|obsidian-app-qt6",
	},
	workspace = 4,
})
