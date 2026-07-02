dofile(ModPath .. "lua/menu/automenubuilder.lua")

ProfileRebornSettings = ProfileRebornSettings or {
	settings = {
		IsMoveSkillpoint = false,
		WheelScrollValue = 3
	},
	values = {
		WheelScrollValue = {0.25, 5, 0.25}
	},
	order = {
		IsMoveSkillpoint = -1,
		WheelScrollValue = -2
	}
}

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustom_ProfileRebornSettings", function(menu_manager, nodes)
	AutoMenuBuilder_PReborn:load_settings(ProfileRebornSettings.settings, "ProfileReborn_Settings")
	AutoMenuBuilder_PReborn:create_menu_from_table(
		nodes,
		ProfileRebornSettings.settings,
		"ProfileReborn_Settings",
		"blt_options",
		ProfileRebornSettings.values,
		ProfileRebornSettings.order
	)
end)