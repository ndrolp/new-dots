hl.window_rule({
	name = "spotify",
	match = { class = "Spotify|spotify" },
	workspace = "special:spotify",
})

hl.layer_rule({
	name = "spring",
	match = { class = "rofi" },
	animation = "spring",
})

hl.layer_rule({
	name = "ndro-bar",
	match = { namespace = "ndro-shell-bar" },
	ignore_alpha = 0.1,
	blur = true,
	dim_around = true,
	animation = "spring",
})

hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })
hl.layer_rule({
	name = "ndro-bar-no-blur",
	match = { namespace = "ndro-shell-settings|ndro-shell-wallpaper" },
	ignore_alpha = 0.2,
	blur = false,
	dim_around = true,
	animation = "slide",
})
