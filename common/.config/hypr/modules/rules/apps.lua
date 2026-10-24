hl.layer_rule({
	name = "spring",
	match = { namespace = "rofi" },
	animation = "popin 80 20",
	dim_around = true,
})

-- The bar and its popups. Quickshell PopupWindows are xdg popups of this
-- layer, so they have no namespace of their own and take this rule's
-- blur_popups and ignore_alpha. ignore_alpha keeps the blur to the drawn
-- shape: it skips the transparent room beside a popup and the faint
-- anti-aliased fringe, and stays below the lowest bar opacity (20%).
hl.layer_rule({
	name = "ndro-bar",
	match = { namespace = "ndro-shell-bar" },
	ignore_alpha = 0.1,
	blur = true,
	blur_popups = true,
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

hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.layer_rule({
	name = "ndro-bar-no-blur",
	match = { namespace = "ndro-shell-settings|ndro-shell-notifications" },
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
	match = { namespace = "ndro-shell-settings" },
	ignore_alpha = 0.0,
	blur = false,
	dim_around = true,
	animation = "popin",
})

hl.layer_rule({
	name = "ndro-shell-wallpaper-selector",
	match = { namespace = "ndro-shell-wallpaper-selector" },
	ignore_alpha = 0.0,
	blur = true,
	dim_around = false,
	animation = "popin",
})

hl.layer_rule({
	name = "ndro-shell-overlay-blur",
	match = { namespace = "ndro-shell-application-launcher|ndro-shell-clipboard-selector|ndro-shell-quick-search|ndro-shell-unified-search|ndro-shell-quick-settings|ndro-shell-audio-sink-selector|ndro-shell-theme-selector|ndro-shell-command-launcher" },
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
	match = { namespace = "ndro-shell-screen-capture" },
	ignore_alpha = 0.0,
	blur = true,
	dim_around = false,
	animation = "popin",
})

-- The Control center is its own layer. It is blurred like the bar's popups
-- so it matches them when it hangs from the bar.
hl.layer_rule({
	name = "ndro-shell-control-center",
	match = { namespace = "ndro-shell-control-center" },
	ignore_alpha = 0.1,
	blur = true,
	dim_around = false,
	animation = "popin",
})
