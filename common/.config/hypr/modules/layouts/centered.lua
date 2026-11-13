-- Centered layout (see GLOSSARY-MAP.md): one main window in a middle column, the rest tiled to its
-- left and right. It is Hyprland's master layout with orientation = center; the master options below
-- are global, so master *is* the centered layout everywhere.
--
-- It is toggled one workspace at a time with a runtime workspace rule. Disabling the rule gives the
-- workspace back whatever layout its other rules (or general.layout) gave it. Nothing is saved: a
-- reload or restart drops every rule made here.

local M = {}

local MFACT_STEP = 0.05

M.options = {
	orientation = "center",
	mfact = 0.5,
	new_status = "slave",
	slave_count_for_center_master = 0, -- centre the main window even with fewer than two side windows
	always_keep_position = true, -- ...and even when it is alone
}

-- Workspace name -> the runtime rule that switches it to the centered layout.
local rules = {}

local function is_centered(workspace)
	return workspace.tiled_layout == "master"
end

function M.toggle()
	local workspace = hl.get_active_workspace()
	if not workspace then
		return
	end
	local rule = rules[workspace.name]
	if is_centered(workspace) then
		if rule then
			rule:set_enabled(false)
		end
	elseif rule then
		rule:set_enabled(true)
	else
		rules[workspace.name] = hl.workspace_rule({ workspace = workspace.name, layout = "master" })
	end
end

-- Layout messages only make sense on a centered workspace; elsewhere they would just error.
local function on_centered(message)
	return function()
		local workspace = hl.get_active_workspace()
		if workspace and is_centered(workspace) then
			hl.dispatch(hl.dsp.layout(message))
		end
	end
end

M.swap_into_middle = on_centered("swapwithmaster master")
M.narrower = on_centered(string.format("mfact -%.2f", MFACT_STEP))
M.wider = on_centered(string.format("mfact +%.2f", MFACT_STEP))

function M.install()
	hl.config({ master = M.options })
end

return M
