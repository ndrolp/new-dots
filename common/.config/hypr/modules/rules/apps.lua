hl.layer_rule({
	name = "spring",
	match = { namespace = "rofi" },
	animation = "popin 80 20",
	dim_around = true,
})

hl.layer_rule({
	name = "ndro-bar",
	match = { namespace = "ndro-shell-bar" },
	ignore_alpha = 0.1,
	blur = false,
	dim_around = false,
	animation = "spring",
})

hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })
hl.layer_rule({
	name = "ndro-bar-no-blur",
	match = { namespace = "ndro-shell-settings|ndro-shell-wallpaper|ndro-shell-notifications" },
	ignore_alpha = 0.1,
	blur = false,
	dim_around = false,
	animation = "slide",
})
