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

hl.layer_rule({
	name = "ndro-desktop-widgets",
	match = { namespace = "ndro-shell-desktop-widgets" },
	ignore_alpha = 0.0,
	blur = true,
	dim_around = false,
})

hl.layer_rule({
	name = "ndro-bar",
	match = { class = "maim" },
	ignore_alpha = 0.0,
	blur = false,
	dim_around = false,
	animation = "spring",
})

hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.layer_rule({
	name = "ndro-bar-no-blur",
	match = { namespace = "ndro-shell-settings|ndro-shell-wallpaper|ndro-shell-notifications" },
	ignore_alpha = 0.0,
	blur = false,
	dim_around = false,
	animation = "slide",
})

hl.layer_rule({
	name = "ndro-notifications-no-blur",
	match = { namespace = "ndro-shell-notifications" },
	ignore_alpha = 0.0,
	blur = false,
	dim_around = false,
})

hl.layer_rule({
	name = "ndro-bar-no-blur",
	match = { namespace = "ndro-shell-settings|ndro-shell-wallpaper" },
	ignore_alpha = 0.0,
	blur = false,
	dim_around = true,
	animation = "popin",
})

hl.layer_rule({
	name = "ndro-shell-overlay-blur",
	match = { namespace = "ndro-shell-application-launcher|ndro-shell-clipboard-selector|ndro-shell-quick-search|ndro-shell-audio-sink-selector|ndro-shell-theme-selector|ndro-shell-command-launcher" },
	ignore_alpha = 0.0,
	blur = true,
	dim_around = false,
})

hl.layer_rule({
	name = "ndro-shell-switcher-overlays",
	match = { namespace = "ndro-shell-window-switcher|ndro-shell-workspace-overview" },
	ignore_alpha = 0.0,
	blur = true,
	dim_around = false,
	animation = "popin",
})

hl.layer_rule({
	name = "ndro-shell-panel-overlays",
	match = { namespace = "ndro-shell-screen-capture|ndro-shell-control-center" },
	ignore_alpha = 0.0,
	blur = true,
	dim_around = false,
	animation = "popin",
})
