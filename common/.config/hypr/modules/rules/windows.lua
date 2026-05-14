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

hl.window_rule({
	name = "transparent",
	match = {
		class = "nemo|Spotify",
	},
	opacity = 0.9,
})
