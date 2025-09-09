ProfileReborn = ProfileReborn or class()
ProfileReborn.save_path = SavePath .. "ProfileReborn.txt"

local MPath = ModPath
DB:create_entry(Idstring("texture"), Idstring("guis/textures/pd2/profile_rebvorn_none_icon"), MPath .. "assets/profile_rebvorn_none_icon.texture")
DB:create_entry(Idstring("texture"), Idstring("guis/textures/pd2/profile_rebvorn_add_profile_icon"), MPath .. "assets/profile_rebvorn_add_profile_icon.texture")
DB:create_entry(Idstring("texture"), Idstring("guis/textures/pd2/profile_rebvorn_loading_icon"), MPath .. "assets/profile_rebvorn_loading_icon.texture")
DB:create_entry(Idstring("texture"), Idstring("guis/textures/pd2/profile_rebvorn_up_icon"), MPath .. "assets/profile_rebvorn_up_icon.texture")
DB:create_entry(Idstring("texture"), Idstring("guis/textures/pd2/profile_rebvorn_down_icon"), MPath .. "assets/profile_rebvorn_down_icon.texture")

function ProfileReborn:init()
	self._ui_layer = 500  --整体UI的层级
	self._wheel_scroll_value = 3  --浏览下拉Profile列表的速度
	self._wheel_scroll_value_custom = 15  --左列表文字系列的下拉速度
	self._filter_list_h = 30  --左文字列表的高度
	self._bg_h = 100  --Profile显示的高度
	self._max_length = 15  --Custom筛选器输入命名的最大长度

	self._normal_text_color = Color.white  --主题文字颜色
	self._profile_name_color = self._normal_text_color  --Profile名称的颜色
	self._profile_skillpoints_text_color = self._normal_text_color  --Profile技能显示的颜色
	self._perk_deck_display_method_text_color = self._normal_text_color  --Perk Deck筛选器切换显示方式的颜色
	self._filter_method_font_color = self._normal_text_color  --切换筛选器的文字颜色
	self._leftlist_font_color = self._normal_text_color  --左列表文字显示的颜色
	self._new_add_filter_text_color = self._normal_text_color  --Custom筛选器背景文字 ‘创建新的筛选器’ 的颜色

	self._main_color = Color(173 / 255,216 / 255,230 / 255)  --主题颜色
	self._leftlist_text_bg_color = self._main_color  --左文字列表的选中时的背景颜色
	self._filter_bg_color = self._main_color  --选中切换筛选器时的背景颜色
	self._profile_highlight_color = self:Saturation(self._main_color)  --当前使用的Profile的颜色

	--筛选器列表
	self.filter_method = {
		"default",
		"perk_deck",
		"custom"
	}
	
	--Perk Deck筛选器显示方式列表
	self.perk_deck_display_method = {
		"icon_1",
		"text",
		"text_sort"
	}

	self._reset_ignore = {
		["profile_list"] = true,
		["filter"] = true,
		["set_filter_left"] = true,
		["set_filter_right"] = true
	}

	--初始化记录鼠标指针位置
	self._mouse_x = 0
	self._mouse_y = 0
end

function ProfileReborn:active()
	self._ws = managers.gui_data:create_fullscreen_workspace()

	self._controller_cls = {}
	
	self._controller_cls.profile_list = PRebornScrollList:new(self._ws:panel(), {
		scrollbar_padding = 0,
		bar_minimum_size = 16,
		padding = 0,
		w = 800,
		h = 500,
		input_focus = true,
		layer = self._ui_layer,
		dy = self._wheel_scroll_value,
		main_color = self._main_color
	}, {
		padding = 0
	})

	self._controller_cls.profile_list:add_lines_and_static_down_indicator(5000)

	self._panel = self._controller_cls.profile_list:panel()
	self._canvas = self._controller_cls.profile_list:canvas()

	self._panel:set_center(self._ws:panel():center_x(), self._ws:panel():center_y())
	
	self:load()

	self._current_filter = self.save_data and self.save_data.current_filter or 1
	self._controller_cls.filter = PRebornButton:new(self._ws:panel(), {
		layer = self._ui_layer,
		w = 150,
		h = 30,
		bg = true,
		bg_color = self._filter_bg_color,
		bg_alpha = 0,
		bg_layer = -49,
		active = false
	})
	
	self._filter = self._controller_cls.filter:panel()

	self._filter:set_left(self._panel:left())
	self._filter:set_top(self._panel:bottom() + 2)
	local menu_arrows_texture = "guis/textures/menu_arrows"

	self._controller_cls.set_filter_left = PRebornButton:new(self._filter, {
		w = self._filter:h(),
		h = self._filter:h(),
		selection_mode = 2,
		callback = function()
			self:switch_filter(self._current_filter - 1)
		end
	})

	local arrow_left_panel = self._controller_cls.set_filter_left:panel()

	local arrow_left = arrow_left_panel:bitmap({
		texture = menu_arrows_texture,
		layer = 2,
		texture_rect = {
			0,
			0,
			24,
			24
		}
	})

	arrow_left_panel:set_center_y(self._filter:h() / 2)
	arrow_left:set_center_y(arrow_left_panel:h() / 2)

	self._controller_cls.set_filter_right = PRebornButton:new(self._filter, {
		w = self._filter:h(),
		h = self._filter:h(),
		selection_mode = 2,
		callback = function()
			self:switch_filter(self._current_filter + 1)
		end
	})

	local arrow_right_panel = self._controller_cls.set_filter_right:panel()

	local arrow_right = arrow_right_panel:bitmap({
		texture = menu_arrows_texture,
		layer = 2,
		rotation = 180,
		texture_rect = {
			0,
			0,
			24,
			24
		}
	})

	arrow_right_panel:set_right(self._filter:w())
	arrow_right_panel:set_center_y(self._filter:h() / 2)
	arrow_right:set_right(arrow_right_panel:w())
	arrow_right:set_center_y(arrow_right_panel:h() / 2)

	for layer, method in ipairs(self.filter_method) do
		self._filter:text({
			name = "bp_filter_" .. method,
			visible = layer == self._current_filter,
			vertical = "center",
			valign = "center",
			align = "center",
			halign = "center",
			font = tweak_data.hud_players.ammo_font,
			text = string.upper(managers.localization:text("menu_bp_filter_" .. method)),
			font_size = 18,
			layer = layer,
			color = self._filter_method_font_color
		})
	end
	
	self._filter_bg = self._filter:rect({
		color = Color.black,
		alpha = 0.9,
		layer = -50,
		w = self._filter:w(),
		h = self._filter:h()
	})
	
	self._bg = self._ws:panel():bitmap({
		render_template = "VertexColorTexturedBlur3D",
		texture = "guis/textures/test_blur_df",
		w = 2000,
		h = 2000,
		layer = self._ui_layer - 10,
		color = Color.white
	})
	
	self._rect = self._panel:rect({
		color = Color.black,
		alpha = 0.9,
		layer = -60,
		w = self._canvas:w(),
		h = self._canvas:h()
	})
	
	--创建滚动条
	self._scroll_bar = self._canvas:rect({
	    name = "scroll_bar",
	    color = Color.white,
	    visible = false,
	    color = Color(0.5,0.5,0.5),
		layer = -1
	})
	self._scroll_bar:set_w(2)

	-- self:create_side(self._canvas)
	self:create_side(self._filter)
	
	self.profiles = {}
	self.perk_deck = {}
	self.perk_deck.perks = {}
	self.perk_deck.deck_list = {}
	
	if not self.custom then
		self:set_custom_profile()
	end
	
	self:switch_filter(self._current_filter)

	self._ws:connect_keyboard(Input:keyboard())
	self._panel:key_press(callback(self, self, "key_press"))
	self._panel:key_release(callback(self, self, "key_release"))

	if PRebornSearchBox and managers.menu:is_pc_controller() then
		local scbox = self._ws:panel():panel({
			layer = self._ui_layer,
			w = self._canvas:w(),
			h = tweak_data.menu.pd2_medium_font_size + 1
		})

		scbox:set_left(self._panel:left())
		scbox:set_top(self._panel:bottom())

		self._saved_search = nil

		self._profile_searchbox = PRebornSearchBox:new(scbox, self._ws, self._saved_search)
		self._profile_searchbox.panel:set_right(scbox:w())
		self._profile_searchbox.panel:set_top(1)
		self._profile_searchbox:register_callback(callback(self, self, "update_items_list", false))
		self._profile_searchbox:register_disconnect_callback(function()
			self._profile_searchbox.panel:enter_text(nil)
			self._profile_searchbox._enter_text_set = false
			managers.multi_profile.profile_reborn._selected = false
			self._ws:connect_keyboard(Input:keyboard())
		end)

		local ProfileSearchbox = self._profile_searchbox

		local old_ProfileSearchbox_connect_search_input = ProfileSearchbox.connect_search_input
		function ProfileSearchbox:connect_search_input(...)
			old_ProfileSearchbox_connect_search_input(self, ...)

			managers.multi_profile.profile_reborn._selected = true
		end
	end

	self:show()
end

function ProfileReborn:set_profile(idx, profile, profile_idx, tool, to_profiles)
	if not profile then
		return
	end
	
	local tool_visible = tool or false

	if not to_profiles then
		self.profiles[profile_idx] = profile
	end
	
	local text = profile.name or "Profile " .. profile_idx or idx

	self._controller_cls["profile" .. idx] = PRebornButton:new(self._canvas, {
		layer = profile_idx or 0, --借用层级，存取profile编号
		w = self._rect:w(),
		h = self._bg_h,
		selection_mode = 5,
		callback = function()
			if alive(self._ws) then
				managers.multi_profile:set_current_profile(profile_idx or idx)
				self:hide()
			end
		end
	})

	local profile_cls = self._controller_cls["profile" .. idx]
	local panel = profile_cls:panel()

	self._controller_cls.profile_list:add_item(panel)

	local profile_bg = panel:bitmap({
		visible = false,
		texture = "guis/textures/menu_selected",
		texture_rect = {20, 20, 24, 24},
		alpha = 0.3,
		layer = 1,
		w = self._rect:w(),
		h = self._bg_h
	})
		
	local perk_deck = tweak_data.skilltree.specializations[profile.perk_deck]

	if perk_deck then
		local icon_atlas_texture, texture_rect, multi_choice_icon = self:get_specialization_icon(perk_deck[1])
		
		if profile.perk_deck == 1 then
			icon_atlas_texture, texture_rect = self:get_specialization_icon(perk_deck[9])		
		elseif profile.perk_deck == 23 then
			icon_atlas_texture, texture_rect, multi_choice_icon = self:get_specialization_icon(perk_deck[9], profile.perk_deck_choices[9])
		end

		local profile_icon_bg = panel:bitmap({
			texture = icon_atlas_texture,
			texture_rect = texture_rect,
			alpha = 0.3,
			layer = 2,
			w = profile_bg:h() * 0.5,
			h = profile_bg:h() * 0.5
		})
		profile_icon_bg:set_right(profile_bg:right())
		
		if profile.perk_deck == 23 then
			profile_icon_bg:set_w(profile_bg:h() * 0.45)
			profile_icon_bg:set_h(profile_bg:h() * 0.45)
			profile_icon_bg:set_right(profile_bg:right())

			local profile_icon_23_bg = panel:bitmap({
				texture = multi_choice_icon.texture,
				texture_rect = multi_choice_icon.texture_rect,
				alpha = 0.3,
				layer = 2,
				w = profile_bg:h() * 0.3,
				h = profile_bg:h() * 0.3
			})
			
			profile_icon_23_bg:set_top(profile_icon_bg:bottom()-profile_icon_23_bg:w()/3)
			profile_icon_23_bg:set_center_x(profile_icon_bg:center_x())
		end
	end

	self._controller_cls["remove_icon" .. idx] = PRebornButton:new(panel, {
		name = "remove_icon" .. idx,
		visible = false,
		w = 40,
		h = 40,
		layer = 3,
		selection_mode = 2,
		callback = function()
			local current_filter = self:get_current_custom_filter()

			table.remove(current_filter.profiles, idx)
			self:switch_filter(3, self.custom.current_custom_filter)
			managers.mouse_pointer:set_pointer_image("arrow")
		end
	})

	local remove_icon_panel = self._controller_cls["remove_icon" .. idx]:panel()

	local remove_icon = remove_icon_panel:bitmap({
		w = 40,
		h = 40,
		texture = "guis/textures/pd2/profile_rebvorn_none_icon",
	})
	
	remove_icon_panel:set_bottom(panel:h()-5)
	remove_icon_panel:set_right(panel:right())
	remove_icon:set_center_y(remove_icon_panel:h() / 2)
	
	self._controller_cls["down_icon" .. idx] = PRebornButton:new(panel, {
		name = "down_icon" .. idx,
		visible = false,
		w = 40,
		h = 40,
		layer = 3,
		selection_mode = 2,
		callback = function()
			if idx < #self:profiles_panel() then
				local f = idx
				local t = idx + 1

				self:swap_profile(f, t)
				self:switch_filter(3, self.custom.current_custom_filter)
				managers.mouse_pointer:set_pointer_image("arrow")
			end
		end
	})

	local down_icon_panel = self._controller_cls["down_icon" .. idx]:panel()

	local down_icon = down_icon_panel:bitmap({
		w = 40,
		h = 40,
		texture = "guis/textures/pd2/profile_rebvorn_down_icon",
	})
	
	down_icon_panel:set_bottom(panel:h()-5)
	down_icon_panel:set_right(remove_icon_panel:left())
	down_icon:set_center_y(down_icon_panel:h() / 2)

	self._controller_cls["up_icon" .. idx] = PRebornButton:new(panel, {
		name = "up_icon" .. idx,
		visible = false,
		w = 40,
		h = 40,
		layer = 3,
		selection_mode = 2,
		callback = function()
			if idx > 1 then
				local f = idx
				local t = idx - 1
						
				self:swap_profile(f, t)
				self:switch_filter(3, self.custom.current_custom_filter)
				managers.mouse_pointer:set_pointer_image("arrow")
			end
		end
	})

	local up_icon_panel = self._controller_cls["up_icon" .. idx]:panel()

	local up_icon = up_icon_panel:bitmap({
		w = 40,
		h = 40,
		texture = "guis/textures/pd2/profile_rebvorn_up_icon",
	})
	
	up_icon_panel:set_bottom(panel:h()-5)
	up_icon_panel:set_right(down_icon_panel:left())
	up_icon:set_center_y(up_icon_panel:h() / 2)

	local cls = self._controller_cls["profile" .. idx]
	local old_inside_func = cls.inside

	function cls:inside(x, y)
		if not managers.multi_profile.profile_reborn._panel:inside(x, y) then
			return
		end

		if tool_visible then
			if self:panel():inside(x, y) then
				remove_icon_panel:set_visible(true)
				down_icon_panel:set_visible(true)
				up_icon_panel:set_visible(true)
			else
				remove_icon_panel:set_visible(false)
				down_icon_panel:set_visible(false)
				up_icon_panel:set_visible(false)				
			end
		end

		if remove_icon_panel:inside(x, y) or down_icon_panel:inside(x, y) or up_icon_panel:inside(x, y) then
			return
		else
			return old_inside_func(self, x, y)
		end
	end

	local text_color = self._profile_name_color
	
	if profile_idx == managers.multi_profile._global._current_profile then
		text_color = self._profile_highlight_color
	end

	local profile_text = panel:text({
		font = tweak_data.hud_players.ammo_font,
		text = text,
		color = text_color,
		font_size = 14,
		layer = 3,
		y = 5,
		x = 3
	})
	
	local slot = profile.primary
	local crafted_items = managers.blackmarket._global.crafted_items
	local primary = crafted_items["primaries"][slot]
	
	if not primary then
		return
	end
	
	local primary_texture, primary_bg_texture= managers.blackmarket:get_weapon_icon_path(primary.weapon_id, primary.cosmetics and primary.cosmetics)
	local primary_weapon = panel:bitmap({
		texture = primary_texture,
		w = 120,
		h = 60,
		x = 10,
		layer = 4
	})
	primary_weapon:set_center_y(profile_bg:center_y())
	
	if primary_bg_texture then
		local primary_weapon_bg = panel:bitmap({
			texture = primary_bg_texture,
			w = primary_weapon:w(),
			h = primary_weapon:h(),
			layer = 3
		})
		primary_weapon_bg:set_center_y(primary_weapon:center_y())
	end
		
	local slot = profile.secondary
	local crafted_items = managers.blackmarket._global.crafted_items
	local secondary = crafted_items["secondaries"][slot]
	
	if not secondary then
		return
	end
	
	local secondary_texture, secondary_bg_texture= managers.blackmarket:get_weapon_icon_path(secondary.weapon_id, secondary.cosmetics and secondary.cosmetics)
	local secondary_weapon = panel:bitmap({
		texture = secondary_texture,
		w = 120,
		h = 60,
		layer = 4,
		x = primary_weapon:right() + 10
	})
	secondary_weapon:set_center_y(profile_bg:center_y())
	
	if secondary_bg_texture then
		local secondary_weapon_bg = panel:bitmap({
			texture = secondary_bg_texture,
			w = secondary_weapon:w(),
			h = secondary_weapon:h(),
			layer = 3,
			x = primary_weapon:right() + 10
		})
		secondary_weapon_bg:set_center_y(secondary_weapon:center_y())
	end
	
	-- Skillpoints 1.02 fix by Nexqua
	local function pad(num)
		return string.format("%02d", num)
	end
	
	local skillpoints = self:get_skillpoints_base(profile)
	local mas_skillpoints = "Mas:" .. pad(skillpoints[1]) .. " " .. pad(skillpoints[2]) .. " " .. pad(skillpoints[3])
	local enf_skillpoints = "Enf:" .. pad(skillpoints[4]) .. " " .. pad(skillpoints[5]) .. " " .. pad(skillpoints[6])
	local tec_skillpoints = "Tec:" .. pad(skillpoints[7]) .. " " .. pad(skillpoints[8]) .. " " .. pad(skillpoints[9])
	local gho_skillpoints = "Gho:" .. pad(skillpoints[10]) .. " " .. pad(skillpoints[11]) .. " " .. pad(skillpoints[12])
	local fug_skillpoints = "Fug:" .. pad(skillpoints[13]) .. " " .. pad(skillpoints[14]) .. " " .. pad(skillpoints[15])
	local skillpoint_text = mas_skillpoints .. "   " .. enf_skillpoints .. "   " .. tec_skillpoints .. "   " .. gho_skillpoints .. "   " .. fug_skillpoints
	local skillpoints_text = panel:text({
		vertical = "top",
		font = tweak_data.hud_players.ammo_font,
		text = skillpoint_text,
		font_size = 13,
		layer = 3,
		x = secondary_weapon:left(),
		color = self._profile_skillpoints_text_color
	})		
	local throwable = profile.throwable
	local texture = self:get_projectiles_icon(throwable)
	local projectile = panel:bitmap({
		texture = texture,
		w = 80,
		h = 40,
		layer = 4,
		x = secondary_weapon:right() + 20,
		y = secondary_weapon:top() - 5
	})
	
	local melee_texture = self:get_melee_icon(profile.melee)
	local melee = panel:bitmap({
		texture = melee_texture,
		w = 80,
		h = 40,
		layer = 4,
		x = secondary_weapon:right() + 20,
		y = secondary_weapon:center_y() + 5
	})
	
	local deployable_texture = ProfileReborn:get_deployable_icon(profile.deployable)
	local deployable = panel:bitmap({
		texture = deployable_texture,
		w = 70,
		h = 70,
		layer = 4,
		x = projectile:right() + 25
	})
	deployable:set_center_y(profile_bg:center_y())
		
	if profile.deployable_secondary then
		local deployable_texture = ProfileReborn:get_deployable_icon(profile.deployable_secondary)
		local deployable_secondary = panel:bitmap({
			texture = deployable_texture,
			w = 50,
			h = 50,
			layer = 4,
			x = deployable:left() + 65
		})
		deployable_secondary:set_center_y(profile_bg:center_y())
	end
		
	local slot = profile.mask
	local bm_mask = Global.blackmarket_manager.crafted_items["masks"][slot]

	if not bm_mask then
		return
	end

	local mask_texture = managers.blackmarket:get_mask_icon(bm_mask.mask_id)
	local mask = panel:bitmap({
		texture = mask_texture,
		w = 70,
		h = 70,
		layer = 4,
		x = deployable:right() + deployable:h()
	})
	mask:set_center_y(profile_bg:center_y())
	
	local profile_armor = profile.armor
	local armor_texture = self:get_armor_icon(profile_armor)
	local armor = panel:bitmap({
		texture = armor_texture,
		w = 70,
		h = 70,
		layer = 4,
		x = mask:right() + 15
	})
	armor:set_center_y(profile_bg:center_y())
end

function ProfileReborn:create_side(panel)
	BoxGuiObject:_create_side(panel, "left", 1, false, false)
	BoxGuiObject:_create_side(panel, "right", 1, false, false)
	BoxGuiObject:_create_side(panel, "top", 1, false, false)
	BoxGuiObject:_create_side(panel, "bottom", 1, false, false)
end

function ProfileReborn:profiles_panel()
	return self._controller_cls.profile_list:items()
end

function ProfileReborn:show()
	self._bg:show()
	self._panel:show()
		
	local active_menu = managers.menu:active_menu()
	local is_pc_controller = managers.menu:is_pc_controller()
	if active_menu and not is_pc_controller then
		active_menu.input:activate_controller_mouse()
	end
	
	self._mouse_id = self._mouse_id or managers.mouse_pointer:get_id()
	self._mouse_data = {
		mouse_move = callback(self, self, "mouse_moved"),
		mouse_press = callback(self, self, "mouse_pressed"),
		mouse_release = callback(self, self, "mouse_released"),
		mouse_click = callback(self, self, "mouse_clicked"),
		id = self._mouse_id,
		menu_ui_object = self
	}
	managers.mouse_pointer:use_mouse(self._mouse_data)

	local controller = managers.controller:get_controller_by_name("MenuManager")
	
	if controller then
		controller:set_enabled(false)
	end
	
	managers.menu:active_menu().input:set_back_enabled(false)
	managers.menu:active_menu().input:accept_input(false)
end

function ProfileReborn:hide()
	managers.mouse_pointer:remove_mouse(self._mouse_data)
	
	local active_menu = managers.menu:active_menu()
	local is_pc_controller = managers.menu:is_pc_controller()
	if active_menu and not is_pc_controller then
		active_menu.input:activate_controller_mouse()
	end
	
	self._ws:hide()
	managers.gui_data:destroy_workspace(self._ws)
	
	local controller = managers.controller:get_controller_by_name("MenuManager")
	
	if controller then
		controller:set_enabled(true)
	end
	
	managers.menu:active_menu().input:set_back_enabled(true)
	managers.menu:active_menu().input:accept_input(true)
	
	self:save()
end

function ProfileReborn:reset_panel()
	self:reset_profile_panels()
	
	for name, cls in pairs(self._controller_cls) do
		if not self._reset_ignore[name] and alive(cls:parent()) and alive(cls:panel()) then
			cls:destroy()
			self._controller_cls[name] = nil
		end
	end
	
	self:load()
	self:save()
end

--重置所有和profile列表有关的内容
function ProfileReborn:reset_profile_panels()
	self._controller_cls.profile_list:clear()
	self.profiles = {}
end

function ProfileReborn:mouse_moved(o, x, y)
	if self._editing then
		return
	end

	if not self._panel then
		return
	end

	self._mouse_x = x
	self._mouse_y = y
	self._mouse_inside = false

	for _, cls in pairs(self._controller_cls) do
		if alive(cls:panel()) then
			self._mouse_inside = (cls.mouse_moved and cls:mouse_moved(o, x, y)) and true or self._mouse_inside
		end
	end
	
	-- Profile search box
	self._mouse_inside = self._profile_searchbox:mouse_moved(o, x, y) and true or self._mouse_inside

	if self._mouse_inside then
		managers.mouse_pointer:set_pointer_image("link")
	else
		managers.mouse_pointer:set_pointer_image("arrow")
	end
end

function ProfileReborn:mouse_pressed(o, button, x, y)
	if self._editing then
		return
	end
	
	self._profile_searchbox:mouse_pressed(button, x, y)

	if self._selected then
		return
	end

	local clses = self:table_clone(self._controller_cls)
	for k, cls in pairs(clses) do
		if alive(cls:panel()) then
			cls:mouse_pressed(button, x, y)
		end
	end
end

function ProfileReborn:mouse_released(o, button, x, y)
	for _, cls in pairs(self._controller_cls) do
		local released = cls.mouse_released and cls:mouse_released(button, x, y)
	end
end

function ProfileReborn:mouse_clicked(o, button, x, y)
end

function ProfileReborn:key_press(o, k)
	-- if self._selected then
		-- return
	-- end

	self._key_release_disable = false

	local mouse_callbacks = managers.mouse_pointer._mouse_callbacks
	if mouse_callbacks and mouse_callbacks[#mouse_callbacks] and mouse_callbacks[#mouse_callbacks].id ~= self._mouse_id then
		self._key_release_disable = true
	end
	
	if self._selected then
		self._key_release_disable = true
	end

	if self._editing then
		self:handle_key(k, true)
	end
end

function ProfileReborn:key_release(o, k)
	if self._selected then
		return
	end
	
	if self._key_release_disable then
		self._key_release_disable = false
		return
	end

	if self._editing then
		self:handle_key(k, false)
	elseif k == Idstring("esc") then
		if self._panel:visible() then
			self:hide()
		end
	end
end

function ProfileReborn:set_default_profile()
	for idx, profile in pairs(managers.multi_profile._global._profiles) do
		self:set_profile(idx, profile, idx)
	end
end

function ProfileReborn:set_perk_desk_profile()
	self.perk_deck.perks = {}
	for idx, profile in pairs(managers.multi_profile._global._profiles) do
		self.perk_deck.perks[profile.perk_deck] = self.perk_deck.perks[profile.perk_deck] or {}
		local perk_deck = self.perk_deck.perks[profile.perk_deck]
		perk_deck[#perk_deck + 1] = {
			idx = idx,
			profile = profile
		}
	end
	
	local leftlist_panel = self._ws:panel():panel({
		name = "left_list"
	})

	self._controller_cls.perk_icon = PRebornScrollListSimple:new(leftlist_panel, {
		layer = self._ui_layer + 1,
		w = 50,
		h = self._panel:h(),
		dy = 50,
		selection = true,
		selection_mode = 2
	})

	self._controller_cls.perk_text = PRebornScrollListSimple:new(leftlist_panel, {
		layer = self._ui_layer + 1,
		w = 200,
		h = self._panel:h(),
		dy = 10,
		selection = true,
		selection_mode = 1,
		rect_color = self._leftlist_text_bg_color
	})

	-- 创建文字排序的主panel
	self._controller_cls.perk_text_sort = PRebornScrollListSimple:new(leftlist_panel, {
		layer = self._ui_layer + 1,
		w = 200,
		h = self._panel:h(),
		dy = 10,
		selection = true,
		selection_mode = 1,
		rect_color = self._leftlist_text_bg_color
	})

	self.perk_deck.panels = {
		self._controller_cls.perk_icon,
		self._controller_cls.perk_text,
		self._controller_cls.perk_text_sort
	}
	
	local deck_list_icon = self.perk_deck.panels[1]
	deck_list_icon:panel():set_right(self._panel:left())
	deck_list_icon:panel():set_top(self._panel:top())
	deck_list_icon:set_callback(function(idx)
		self:switch_perk(idx)
		managers.mouse_pointer:set_pointer_image("arrow")
	end)

	local deck_list_text = self.perk_deck.panels[2]
	deck_list_text:panel():set_right(self._panel:left()-1)
	deck_list_text:panel():set_top(self._panel:top())
	deck_list_text:set_callback(function(idx)
		self:switch_perk(idx)
		managers.mouse_pointer:set_pointer_image("arrow")
	end)

	local deck_list_text_sort = self.perk_deck.panels[3]
	deck_list_text_sort:panel():set_right(self._panel:left()-1)
	deck_list_text_sort:panel():set_top(self._panel:top())
	deck_list_text_sort:set_callback(function(idx)
		self:switch_perk(idx)
		managers.mouse_pointer:set_pointer_image("arrow")
	end)
	
	self.perk_deck.display_mode = self.save_data.perk_deck_display_mode or 1
	
	for perk = 1, 30 do if self.perk_deck.perks[perk] then
		local perk_deck = tweak_data.skilltree.specializations[perk]
		if perk_deck then
			-- display_mode 1
			local icon_atlas_texture, texture_rect = self:get_specialization_icon(perk_deck[1])
			
			if perk == 1 then
				icon_atlas_texture, texture_rect = self:get_specialization_icon(perk_deck[9])
			elseif perk == 23 then
				icon_atlas_texture, texture_rect = self:get_specialization_icon(perk_deck[9])
			end
			
				
			local perk_icon = deck_list_icon:canvas():bitmap({
				name = "perk_icon_" .. tostring(perk),
				texture = icon_atlas_texture,
				texture_rect = texture_rect,
				layer = perk,   --借用层级，存取perk编号
				w = deck_list_icon:canvas():w(),
				h = deck_list_icon:canvas():w()
			})
			
			perk_icon:set_center_x(deck_list_icon:canvas():w() / 2 - 2)

			deck_list_icon:add_item(perk_icon, true, perk)

			-- display_mode 2
			local perk_text = self:get_specialization_text(perk)
			
			local text_perk_panel = deck_list_text:canvas():panel({
				name = "perk_text_" .. tostring(perk),
				w = deck_list_text:canvas():w(),
				h = self._filter_list_h,
				layer = perk
			})

			local text_perk_text = text_perk_panel:text({
				name = "text_perk_text",
				vertical = "center",
				valign = "center",
				align = "right",
				halign = "right",
				layer = 2,
				font = tweak_data.hud_players.ammo_font,
				text = string.upper(perk_text),
				font_size = 20,
				color = self._leftlist_font_color
			})	
				
			local center_x = text_perk_panel:w() / 2
			local center_y = text_perk_panel:h() / 2
			text_perk_text:set_center_y(center_y)
			text_perk_text:set_right(text_perk_panel:right())

			deck_list_text:add_item(text_perk_panel, true, perk)
		end
	end end
	
	-- display_mode 3 将天赋文字显示方式为字母排序
	local sorted_perks = {}

	for _, perk_data in pairs(self._controller_cls.perk_text:items()) do
		table.insert(sorted_perks, perk_data)
	end

	table.sort(sorted_perks, function (a, b)
		return a:child("text_perk_text"):text() < b:child("text_perk_text"):text()
	end)

	for key, perk in ipairs(sorted_perks) do
		local perk_text = self:get_specialization_text(perk:layer())
			
		local text_perk_sort_panel = deck_list_text_sort:canvas():panel({
			name = "perk_text_sort_" .. tostring(perk:layer()),
			w = deck_list_text_sort:canvas():w(),
			h = self._filter_list_h,
			layer = perk:layer()
		})

		local text_sort_perk_text = text_perk_sort_panel:text({
			vertical = "center",
			valign = "center",
			align = "right",
			halign = "right",
			layer = 2,
			font = tweak_data.hud_players.ammo_font,
			text = string.upper(perk_text),
			font_size = 20,
			color = self._leftlist_font_color
		})	
			
		local center_x = text_perk_sort_panel:w() / 2
		local center_y = text_perk_sort_panel:h() / 2
		text_sort_perk_text:set_center_y(center_y)
		text_sort_perk_text:set_right(text_perk_sort_panel:right())

		deck_list_text_sort:add_item(text_perk_sort_panel, true, perk:layer())
	end
	------------------------------------

	self._controller_cls.perk_display_mode_panel = PRebornButton:new(self._ws:panel(), {
		layer = self._ui_layer,
		w = 150,
		h = 30,
		active = false,
		bg = false
	})

	local perk_display_mode_panel = self._controller_cls.perk_display_mode_panel:panel()

	perk_display_mode_panel:set_left(self._filter:right())
	perk_display_mode_panel:set_top(self._panel:bottom() + 2)
	
	local menu_arrows_texture = "guis/textures/menu_arrows"

	self._controller_cls.set_perk_display_left = PRebornButton:new(perk_display_mode_panel, {
		name = "arrow_left",
		w = perk_display_mode_panel:h(),
		h = perk_display_mode_panel:h(),
		selection_mode = 2,
		callback = function()
			self:set_perks_display_mode(self.perk_deck.display_mode - 1)
		end
	})

	local arrow_left_panel = self._controller_cls.set_perk_display_left:panel()

	local arrow_left = arrow_left_panel:bitmap({
		texture = menu_arrows_texture,
		layer = 2,
		texture_rect = {
			0,
			0,
			24,
			24
		}
	})

	arrow_left_panel:set_center_y(perk_display_mode_panel:h() / 2)
	arrow_left:set_center_y(arrow_left_panel:h() / 2)

	self._controller_cls.set_perk_display_right = PRebornButton:new(perk_display_mode_panel, {
		name = "arrow_right",
		w = perk_display_mode_panel:h(),
		h = perk_display_mode_panel:h(),
		selection_mode = 2,
		callback = function()
			self:set_perks_display_mode(self.perk_deck.display_mode + 1)
		end
	})

	local arrow_right_panel = self._controller_cls.set_perk_display_right:panel()

	local arrow_right = arrow_right_panel:bitmap({
		texture = menu_arrows_texture,
		layer = 2,
		rotation = 180,
		texture_rect = {
			0,
			0,
			24,
			24
		}
	})

	arrow_right_panel:set_right(perk_display_mode_panel:w())
	arrow_right_panel:set_center_y(perk_display_mode_panel:h() / 2)
	arrow_right:set_right(arrow_right_panel:w())
	arrow_right:set_center_y(arrow_right_panel:h() / 2)

	local display_mode_text = "menu_bp_perk_display_" .. self.perk_deck_display_method[self.perk_deck.display_mode]
	self.perk_display_mode_text = perk_display_mode_panel:text({
		name = "perk_display_mode_text",
		vertical = "center",
		valign = "center",
		align = "center",
		halign = "center",
		font = tweak_data.hud_players.ammo_font,
		text = string.upper(managers.localization:text(display_mode_text)),
		font_size = 18,
		color = self._perk_deck_display_method_text_color
	})

	for key, cls in ipairs(self.perk_deck.panels) do
		if self.perk_deck.display_mode ~= key then
			cls:canvas():hide()
		end
	end

	local current_profile = managers.multi_profile:current_profile()
	self:switch_perk(current_profile.perk_deck)
end

function ProfileReborn:set_custom_profile(base_filter)
	self.custom = {}
	self.custom.filters = {}
	self.custom.panel = self._panel:panel({})
	
	local base_filter = base_filter or (self.save_data and self.save_data.current_custom_filter) or 1
	
	local filters = self.custom.filters

	self._controller_cls.filter_list = PRebornScrollListSimple:new(self._ws:panel(), {
		layer = self._ui_layer,
		w = 200,
		h = self._canvas:h(),
		dy = 10,
		selection = true,
		selection_mode = 1,
		rect_color = self._leftlist_text_bg_color,
		callback = function(num)
			self:switch_custom(num)
		end
	})

	local filter_list = self._controller_cls.filter_list
	filter_list:panel():set_right(self._panel:left() - 1)
	filter_list:panel():set_top(self._panel:top())

	if self.save_data and self.save_data.custom then
		for k1, data in ipairs(self.save_data.custom) do
			filters[data.key] = {
				name = data.name or "CustomFilter#" .. tostring(data.key),
				panel = self:create_filter_ui(filter_list, data.name, data.key),
				key = data.key,
				profiles = {}
			}
			
			for k2, idx in ipairs(self.save_data.custom[data.key].profiles) do
				filters[data.key].profiles[k2] = {
					profile = managers.multi_profile:profile(idx),
					idx = idx
				}
			end
			
			self.custom.current_custom_filter = base_filter
		end
	end

	local ccf = self.custom.current_custom_filter

	if filters[base_filter] then
		for key, data in pairs(filters[base_filter].profiles) do
			self:set_profile(key, data.profile, data.idx, true)
		end

		filter_list:set_selected_solo(base_filter)
	end


	self._controller_cls.first_filter = PRebornButton:new(self.custom.panel, {
		name = "add_first_filter",
		bg = false,
		w = self.custom.panel:w(),
		h = self.custom.panel:h(),
		active = #filters == 0,
		callback = function()
			self:start_input()
			managers.mouse_pointer:set_pointer_image("arrow")
		end
	})
	
	local first_filter_panel = self._controller_cls.first_filter:panel()

	local add_filter_icon = first_filter_panel:bitmap({
		texture = "guis/textures/pd2/none_icon",
		rotation = 45,
	})
	
	local add_filter_text = first_filter_panel:text({
		vertical = "center",
		valign = "center",
		align = "center",
		halign = "center",
		font = tweak_data.hud_players.ammo_font,
		text = string.upper(managers.localization:text("menu_bp_center_text")),
		font_size = 25,
		color = self._new_add_filter_text_color
	})
	
	local center_x = first_filter_panel:w() / 2
	local center_y = first_filter_panel:h() / 2
	add_filter_icon:set_center(center_x, center_y)
	add_filter_text:set_center(center_x, center_y - 50)

	if #self.custom.filters > 0 then
		first_filter_panel:hide()
	end

	self._controller_cls.tool_list = PRebornScrollListSimple:new(self._ws:panel(), {
		layer = self._ui_layer,
		w = 50,
		h = self._canvas:h(),
		dy = 50,
		selection = false,
		selection_mode = -1
	})

	local tool_list = self._controller_cls.tool_list

	tool_list:panel():set_left(self._panel:right())
	tool_list:panel():set_top(self._panel:top())

	-- Custom Filter - Tool list - Add filter icon button
	self._controller_cls.tool_icon_add_filter = PRebornButton:new(tool_list:canvas(), {
		alpha = 0.5,
		layer = 1,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1,
		selection_mode = 2,
		callback = function()
			self:start_input()
			managers.mouse_pointer:set_pointer_image("arrow")
		end
	})

	local tool_icon_add_filter = self._controller_cls.tool_icon_add_filter:panel()

	tool_icon_add_filter:bitmap({
		texture = "guis/textures/pd2/profile_rebvorn_none_icon",
		rotation = 45,
		color = tweak_data.screen_colors.text,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1
	})

	tool_icon_add_filter:set_center_x(tool_list:canvas():w() / 2 - 2)
	tool_list:add_item(tool_icon_add_filter)

	-- Custom Filter - Tool list - Add profile icon button
	self._controller_cls.tool_icon_add_profile = PRebornButton:new(tool_list:canvas(), {
		alpha = 0.5,
		layer = 1,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1,
		selection_mode = 2,
		callback = function()
			if #self.custom.filters <= 0 then
				self:dialog_please_create_a_filter()

				return
			end

			local dialog_data = {
				title = "",
				text = "",
				button_list = {}
			}

			for idx, profile in pairs(managers.multi_profile._global._profiles) do
				local text = profile.name or "Profile " .. idx

				if idx == managers.multi_profile._global._current_profile then
					text = utf8.char(187) .. text
					dialog_data.focus_button = idx
				end

				table.insert(dialog_data.button_list, {
					text = text,
					callback_func = function ()
						self:add_profile_callback(profile, idx)
						self._selected = false
					end,
					focus_callback_func = function ()
					end
				})
			end

			local divider = {
				no_text = true,
				no_selection = true
			}

			table.insert(dialog_data.button_list, divider)

			local no_button = {
				text = managers.localization:text("dialog_cancel"),
				focus_callback_func = function ()
				end,
				callback_func = function ()
					self._selected = false
				end,
				cancel_button = true
			}

			table.insert(dialog_data.button_list, no_button)

			dialog_data.image_blend_mode = "normal"
			dialog_data.text_blend_mode = "add"
			dialog_data.use_text_formating = true
			dialog_data.w = 480
			dialog_data.h = 532
			dialog_data.title_font = tweak_data.menu.pd2_medium_font
			dialog_data.title_font_size = tweak_data.menu.pd2_medium_font_size
			dialog_data.font = tweak_data.menu.pd2_small_font
			dialog_data.font_size = tweak_data.menu.pd2_small_font_size
			dialog_data.text_formating_color = Color.white
			dialog_data.text_formating_color_table = {}
			dialog_data.clamp_to_screen = true
							
			managers.system_menu:show_buttons(dialog_data)
							
			self._selected = true
		end
	})

	local tool_icon_add_profile = self._controller_cls.tool_icon_add_profile:panel()

	tool_icon_add_profile:bitmap({
		texture = "guis/textures/pd2/profile_rebvorn_add_profile_icon",
		color = tweak_data.screen_colors.text,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1
	})

	tool_icon_add_profile:set_center_x(tool_list:canvas():w() / 2 - 2)
	tool_list:add_item(tool_icon_add_profile)

	-- Custom Filter - Tool list - Rename icon button
	self._controller_cls.tool_icon_rename = PRebornButton:new(tool_list:canvas(), {
		alpha = 0.5,
		layer = 1,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1,
		selection_mode = 2,
		callback = function()
			if #self.custom.filters > 0 then
				self:start_input(true)
			else
				self:dialog_please_create_a_filter()
			end
		end
	})

	local tool_icon_rename = self._controller_cls.tool_icon_rename:panel()

	tool_icon_rename:bitmap({
		texture = "guis/textures/pd2/profile_rebvorn_loading_icon",
		color = tweak_data.screen_colors.text,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1
	})

	tool_icon_rename:set_center_x(tool_list:canvas():w() / 2 - 2)
	tool_list:add_item(tool_icon_rename)

	-- Custom Filter - Tool list - Up filter icon button
	self._controller_cls.tool_icon_up = PRebornButton:new(tool_list:canvas(), {
		alpha = 0.5,
		layer = 1,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1,
		selection_mode = 2,
		callback = function()
			if #self.custom.filters > 0 then
				if ccf > 1 then
					self:swap_filter(ccf, ccf - 1)
					self:switch_filter(3, ccf-1)
				end
			else
				self:dialog_please_create_a_filter()
			end
		end
	})

	local tool_icon_up = self._controller_cls.tool_icon_up:panel()

	tool_icon_up:bitmap({
		texture = "guis/textures/pd2/profile_rebvorn_up_icon",
		color = tweak_data.screen_colors.text,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1
	})

	tool_icon_up:set_center_x(tool_list:canvas():w() / 2 - 2)
	tool_list:add_item(tool_icon_up)

	-- Custom Filter - Tool list - Down filter icon button
	self._controller_cls.tool_icon_down = PRebornButton:new(tool_list:canvas(), {
		alpha = 0.5,
		layer = 1,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1,
		selection_mode = 2,
		callback = function()
			if #self.custom.filters > 0 then
				if ccf < #self.custom.filters then
					self:swap_filter(ccf, ccf + 1)
					self:switch_filter(3, ccf + 1)
				end
			else
				self:dialog_please_create_a_filter()
			end
		end
	})

	local tool_icon_down = self._controller_cls.tool_icon_down:panel()

	tool_icon_down:bitmap({
		texture = "guis/textures/pd2/profile_rebvorn_down_icon",
		color = tweak_data.screen_colors.text,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1
	})

	tool_icon_down:set_center_x(tool_list:canvas():w() / 2 - 2)
	tool_list:add_item(tool_icon_down)

	-- Custom Filter - Tool list - Delete filter icon button
	self._controller_cls.tool_icon_remove_filter = PRebornButton:new(tool_list:canvas(), {
		alpha = 0.5,
		layer = 1,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1,
		selection_mode = 2,
		callback = function()
			if #self.custom.filters <= 0 then
				self:dialog_please_create_a_filter()

				return
			end

			local dialog_data = {
				title = managers.localization:text("menu_bp_dialog_remove_filter"),
				text = managers.localization:text("menu_bp_dialog_remove_filter") .. ": " .. self:get_current_custom_filter().name
			}

			local yes_button = {
				text = managers.localization:text("dialog_yes"),
				callback_func = function()
					local max_filters = #self.custom.filters
					table.remove(self.custom.filters, ccf)

					if ccf == max_filters then
						ccf = ccf - 1
					end
						
					for k1, data in ipairs(self.custom.filters) do
						data.key = k1
					end
						
					self:save()
						
					self:switch_filter(3, ccf)
						
					self._selected = false
				end
			}
			local no_button = {
				text = managers.localization:text("dialog_cancel"),
				cancel_button = true,
				callback_func = function()
					self._selected = false
				end
			}
			dialog_data.button_list = {
				yes_button,
				no_button
			}

			managers.system_menu:show(dialog_data)
				
			self._selected = true
		end
	})

	local tool_icon_remove_filter = self._controller_cls.tool_icon_remove_filter:panel()

	tool_icon_remove_filter:bitmap({
		texture = "guis/textures/pd2/profile_rebvorn_none_icon",
		color = tweak_data.screen_colors.text,
		w = tool_list:canvas():w() * 1,
		h = tool_list:canvas():w() * 1
	})

	tool_icon_remove_filter:set_center_x(tool_list:canvas():w() / 2 - 2)
	tool_list:add_item(tool_icon_remove_filter)

	-- Custom Filter - Input Panel
	if not alive(self._input_panel) then
		self._input_panel = self.custom.panel:panel({
			visible = false,
			layer = self._ui_layer + 1,
			w = 300,
			h = 120
		})
		
		self._input_panel:set_center(self.custom.panel:center_x(), self.custom.panel:center_y())
		
		self._name_label = self._input_panel:rect({
			vertical = "center",
			align = "center",
			color = Color("3370ff"),
			layer = 2,
			w = self._input_panel:w(),
			h = 30
		})
		
		self._name_top_text = self._input_panel:text({
			vertical = "center",
			align = "left",
			text = string.upper(managers.localization:text("menu_bp_enter_custom_name")),
			layer = 4,
			font = tweak_data.menu.pd2_small_font,
			font_size = 21,
			color = Color.white,
			x = 10
		})
		
		self._name_top_text:set_center_y(self._name_label:h() / 2)
		
		self._name_rect = self._input_panel:rect({
			vertical = "center",
			align = "center",
			color = Color.black,
			layer = 1,
			alpha = 1,
			w = self._canvas:w(),
			h = self._canvas:h()
		})
		
		self._name_text = self._input_panel:text({
			vertical = "center",
			align = "center",
			text = "",
			layer = 4,
			font = tweak_data.menu.pd2_small_font,
			font_size = tweak_data.menu.pd2_medium_font_size,
			color = Color.white -- tweak_data.screen_colors.button_stage_3
		})

		self._name_input_rect = self._input_panel:rect({
			vertical = "center",
			align = "center",
			color = Color("3370ff"),
			layer = 5,
			alpha = 1,
			w = self._input_panel:w(),
			h = 100
		})
		
		self._name_input_rect:set_center(self._input_panel:center_x(),self._input_panel:center_y())
	end
end

function ProfileReborn:set_perks_display_mode(mode)
	if mode <= 0 then
		mode = 1
	elseif mode >= #self.perk_deck_display_method + 1 then
		mode = #self.perk_deck_display_method
	end
	
	self.perk_deck.display_mode = mode
	
	for key, cls in ipairs(self.perk_deck.panels) do
		local panel = cls:canvas()

		if mode ~= key then
			panel:hide()
		else
			panel:show()
		end
	end
	
	local display_mode_text = "menu_bp_perk_display_" .. self.perk_deck_display_method[mode]
	
	self.perk_display_mode_text:set_text(string.upper(managers.localization:text(display_mode_text)))
end

function ProfileReborn:add_profile_callback(profile, idx)
	local filter = self.custom.filters[self.custom.current_custom_filter]
	local new_profile = #filter.profiles + 1
	
	self:set_profile(new_profile, profile, idx, true)

	filter.profiles[new_profile] = {
		profile = profile,
		idx = idx
	}
end

function ProfileReborn:create_new_filter(name)
	local key = #self.custom.filters + 1
	self.custom.filters[key] = {
		name = name or "CustomFilter#" .. tostring(key),
		panel = self:create_filter_ui(self._controller_cls.filter_list, name, key),
		key = key,
		profiles = {}
	}
	
	local filters = self.custom.filters
	
	self.custom.current_custom_filter = #filters

	self:switch_filter(3, key)
end

function ProfileReborn:create_filter_ui(scroll, name, key)
	local filter = scroll:canvas():panel({
		y = 0,
		w = scroll:canvas():w(),
		h = self._filter_list_h
	})
	
	local custom_filter_text = filter:text({
		vertical = "center",
		valign = "center",
		align = "right",
		halign = "right",
		layer = 2,
		font = tweak_data.hud_players.ammo_font,
		text = name or "CustomFilter#" .. tostring(key),
		font_size = 20,
		color = self._leftlist_font_color
	})	
	
	local center_x = filter:w() / 2
	local center_y = filter:h() / 2
	custom_filter_text:set_center_y(center_y)
	custom_filter_text:set_right(filter:right())
	
	scroll:add_item(filter)

	return filter
end

function ProfileReborn:swap_profile(index1, index2)
	local profiles = self.custom.filters[self.custom.current_custom_filter].profiles
	
	local idx1 = profiles[index1].idx
	local idx2 = profiles[index2].idx
	
	profiles[index1], profiles[index2] = profiles[index2], profiles[index1]
	
	profiles[index1].idx = idx2
	profiles[index2].idx = idx1
end

function ProfileReborn:swap_filter(index1, index2)
	local filters = self.custom.filters
	
	local key1 = filters[index1].key
	local key2 = filters[index2].key
	
	filters[index1], filters[index2] = filters[index2], filters[index1]
	
	filters[index1].key = key1
	filters[index2].key = key2
end

function ProfileReborn:get_current_custom_filter()
	return self.custom.filters[self.custom.current_custom_filter]
end

function ProfileReborn:get_custom_filter(index)
	return self.custom.filters[index]
end

function ProfileReborn:switch_filter(value, base_filter)
	self:save()
	
	if value <= 0 then
		value = 1
	elseif value >= #self.filter_method + 1 then
		value = #self.filter_method
	end
	
	self._current_filter = value
	self:reset_panel()
	
	if value == 1 then
		self:set_default_profile()
	elseif value == 2 then
		self:set_perk_desk_profile()
	elseif value == 3 then
		self:set_custom_profile(base_filter)
	end
	

	if self._bg_h * #self:profiles_panel() >= self._panel:h() then
		local current_ui
		if self._current_filter ~= 1 then
			for k, ui in ipairs(self:profiles_panel()) do
				if ui:layer() == managers.multi_profile._global._current_profile then
					current_ui = k
					break
				end
			end
		else
			current_ui = managers.multi_profile._global._current_profile
		end

		if self:profiles_panel()[current_ui] and self:profiles_panel()[current_ui]:y() > (self._panel:h() / 2 - self._bg_h / 2) then
			local dy = self:profiles_panel()[current_ui]:y() - (self._panel:h() / 2 - self._bg_h / 2)
			self._controller_cls.profile_list:perform_scroll(-dy)
		end
	end
	
	for _, method in ipairs(self.filter_method) do
		local child = self._filter:child("bp_filter_" .. method)
		child:set_visible(child:layer() == self._current_filter)
	end
end

function ProfileReborn:switch_perk(perk)
	local profile = self.perk_deck.perks[perk]
	if profile then
		-- self:reset_panel()
		
		self:reset_profile_panels()

		for i = 1, #profile do
			self:set_profile(i, profile[i].profile, profile[i].idx)
		end

		-- self.perk_deck.panels[self.perk_deck.display_mode]:set_selected(perk)

		for _, cls in ipairs(self.perk_deck.panels) do
			cls:set_selected_solo(perk)
		end

		self.perk_deck.current_perk = perk
	end
end

function ProfileReborn:switch_custom(key)
	local profile = self.custom.filters[key].profiles
	if profile then
		self:reset_profile_panels()
	
		for i = 1, #profile do
			self:set_profile(i, profile[i].profile, profile[i].idx, true)
		end
		
		self.custom.current_custom_filter = key
		managers.mouse_pointer:set_pointer_image("arrow")
	end
end

function ProfileReborn:open_add_profile_confirm()
	if #self.custom.filters > 0 then
		local dialog_data = {
			title = "",
			text = "",
			button_list = {}
		}

		for idx, profile in pairs(managers.multi_profile._global._profiles) do
			local text = profile.name or "Profile " .. idx

			if idx == managers.multi_profile._global._current_profile then
				text = utf8.char(187) .. text
				dialog_data.focus_button = idx
			end

			table.insert(dialog_data.button_list, {
				text = text,
				callback_func = function ()
					self:add_profile_callback(profile, idx)
					self._selected = false
				end,
				focus_callback_func = function ()
				end
			})
		end

		local divider = {
			no_text = true,
			no_selection = true
		}

		table.insert(dialog_data.button_list, divider)

		local no_button = {
			text = managers.localization:text("dialog_cancel"),
			focus_callback_func = function ()
			end,
			callback_func = function ()
				self._selected = false
			end,
			cancel_button = true
		}

		table.insert(dialog_data.button_list, no_button)

		dialog_data.image_blend_mode = "normal"
		dialog_data.text_blend_mode = "add"
		dialog_data.use_text_formating = true
		dialog_data.w = 480
		dialog_data.h = 532
		dialog_data.title_font = tweak_data.menu.pd2_medium_font
		dialog_data.title_font_size = tweak_data.menu.pd2_medium_font_size
		dialog_data.font = tweak_data.menu.pd2_small_font
		dialog_data.font_size = tweak_data.menu.pd2_small_font_size
		dialog_data.text_formating_color = Color.white
		dialog_data.text_formating_color_table = {}
		dialog_data.clamp_to_screen = true
					
		managers.system_menu:show_buttons(dialog_data)
					
		self._selected = true
	else
		self:dialog_please_create_a_filter()
	end
end

function ProfileReborn:rename_filter(index, new_name)
	self.custom.filters[index].name = new_name
	self:save()					
	self:switch_filter(3)
end

function ProfileReborn:dialog_please_create_a_filter()
	local dialog_data = {
		title = managers.localization:text("menu_bp_dialog_please_create_a_filter"),
		text = ""
	}
	
	local ok_button = {
		text = managers.localization:text("dialog_ok"),
		cancel_button = true,
		callback_func = function()
			self._selected = false
		end
	}
	dialog_data.button_list = {
		ok_button
	}

	managers.system_menu:show(dialog_data)
	
	self._selected = true
end

function ProfileReborn:update_items_list(scroll_position, search_list, search_text)
	local profile_scroll = self._controller_cls.profile_list

	if search_text and search_text ~= "" then
		search_text = search_text:lower()
	else
		profile_scroll:clear()

		for i, profile in pairs(self.profiles) do
			self:set_profile(i, profile, i, false, true)
		end

		return
	end

	self._saved_search = search_text and search_text:lower() or nil

	-- for _, panel in ipairs(self:profiles_panel()) do
	-- 	self._scroll_panel:remove(panel)
	-- end

	profile_scroll:clear()

	local i = 1
	for idx, profile in pairs(managers.multi_profile._global._profiles) do
		local profile_name = profile.name or "Profile " .. idx

		if string.is_nil_or_empty(search_text) or 
			string.find(string.lower(profile_name), search_text, nil, true)
		then
			self:set_profile(i, profile, idx, false, true)
			i = i + 1
		end
	end
end

function ProfileReborn:start_input(is_rename)
	self:trigger(is_rename)
end

function ProfileReborn:trigger(is_rename)
	if not self._editing then
		self:set_editing(true)
		
		if is_rename then
			self._is_rename = true
		end
	else
		self:set_editing(false)
	end
end

function ProfileReborn:set_editing(editing)
	if not alive(self._input_panel) then
		return
	end

	self._editing = editing
	self._input_panel:set_visible(editing)
	
	if editing then
		self._input_panel:enter_text(callback(self, self, "enter_text"))

		local n = utf8.len(self._name_text:text())

		self._name_text:set_selection(n, n)

		if _G.IS_VR then
			Input:keyboard():show_with_text(self._name_text:text(), self._max_length)
		end
	else
		self._input_panel:enter_text(nil)
		self._name_text:set_text("")
		
		self._is_rename = false
	end
end

function ProfileReborn:enter_text(o, s)
	if not self._editing then
		return
	end

	if _G.IS_VR then
		self._name_text:set_text(s)
	else
		local s_len = utf8.len(self._name_text:text())
		s = utf8.sub(s, 1, self._max_length - s_len)

		self._name_text:replace_text(s)
	end
end

function ProfileReborn:handle_key(k, pressed)
	local text = self._name_text
	local s, e = text:selection()
	local n = utf8.len(text:text())
	local d = math.abs(e - s)
	
	if pressed then
		if k == Idstring("backspace") then
			if s == e and s > 0 then
				text:set_selection(s - 1, e)
			end

			text:replace_text("")
		elseif k == Idstring("delete") then
			if s == e and s < n then
				text:set_selection(s, e + 1)
			end

			text:replace_text("")
		elseif k == Idstring("left") then
			if s < e then
				text:set_selection(s, s)
			elseif s > 0 then
				text:set_selection(s - 1, s - 1)
			end
		elseif k == Idstring("right") then
			if s < e then
				text:set_selection(e, e)
			elseif s < n then
				text:set_selection(s + 1, s + 1)
			end
		elseif k == Idstring("home") then
			text:set_selection(0, 0)
		elseif k == Idstring("end") then
			text:set_selection(n, n)
		end
	elseif k == Idstring("enter") then
		if self._is_rename then
			self:rename_filter(self.custom.current_custom_filter, text:text())
		else
			self:create_new_filter(text:text())
		end
		
		self:trigger()
	elseif k == Idstring("esc") then
		self:set_editing(false)
	end
end

function ProfileReborn:save()
	local save_filters = {}
	
	if self.custom and self.custom.filters then
		for k, filter in ipairs(self.custom.filters) do
			save_filters[k] = {
				name = filter.name,
				key = filter.key
			}
			
			save_filters[k].profiles = {}
			
			for k2, profile_data in ipairs(filter.profiles) do
				save_filters[k].profiles[k2] = profile_data.idx
			end
		end
	end
	
	local save_data = {
		current_filter = self._current_filter,
		custom = save_filters,
		current_custom_filter = self.custom.current_custom_filter,
		perk_deck_display_mode = self.perk_deck.display_mode or (self.save_data and self.save_data.perk_deck_display_mode or 1)
	}

	io.save_as_json(save_data, self.save_path)
end

function ProfileReborn:load()
	self.save_data = io.load_as_json(self.save_path)
end

-- GETING

function ProfileReborn:get_specialization_icon(item, perk_deck_choices)
	local guis_catalog = "guis/"

	if item.texture_bundle_folder then
		guis_catalog = guis_catalog .. "dlcs/" .. tostring(item.texture_bundle_folder) .. "/"
	end
	
	local atlas_name = item.icon_atlas or "icons_atlas"
	local icon_atlas_texture = guis_catalog .. "textures/pd2/specialization/" .. atlas_name
	
	local icon_texture_rect = item.icon_texture_rect or {
		64,
		64,
		64,
		64
	}
	
	local texture_rect_x = item.icon_xy and item.icon_xy[1] or 0
	local texture_rect_y = item.icon_xy and item.icon_xy[2] or 0	
	local texture_rect = {
		texture_rect_x * icon_texture_rect[1],
		texture_rect_y * icon_texture_rect[2],
		icon_texture_rect[3],
		icon_texture_rect[4]
	}

	local multi_choice_data = item.multi_choice
	local multi_choice_icon = {}
	
	if multi_choice_data then
		multi_choice_data = multi_choice_data[perk_deck_choices] or nil

		if multi_choice_data then
			local atlas_name = multi_choice_data.icon_atlas or multi_choice_data.texture_bundle_folder and "icons_atlas"

			if atlas_name then
				local choice_guis_catalog = "guis/"

				if multi_choice_data.texture_bundle_folder then
					choice_guis_catalog = choice_guis_catalog .. "dlcs/" .. tostring(multi_choice_data.texture_bundle_folder) .. "/"
				end

				local choice_icon_atlas_texture = choice_guis_catalog .. "textures/pd2/specialization/" .. atlas_name
				local choice_texture_rect_x = multi_choice_data.icon_xy and multi_choice_data.icon_xy[1] or 0
				local choice_texture_rect_y = multi_choice_data.icon_xy and multi_choice_data.icon_xy[2] or 0
				local choice_icon_texture_rect = multi_choice_data.icon_texture_rect or {
					64,
					64,
					64,
					64
				}
				
				multi_choice_icon = {
					texture = choice_icon_atlas_texture,
					texture_rect = {
						choice_texture_rect_x * choice_icon_texture_rect[1],
						choice_texture_rect_y * choice_icon_texture_rect[2],
						choice_icon_texture_rect[3],
						choice_icon_texture_rect[4]
					}
				}
			end
		end
	end

	return icon_atlas_texture, texture_rect, multi_choice_icon
end

function ProfileReborn:get_projectiles_icon(grenade)
	local guis_catalog = "guis/"
	local bundle_folder = tweak_data.blackmarket.projectiles[grenade] and tweak_data.blackmarket.projectiles[grenade].texture_bundle_folder

	if bundle_folder then
		guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
	end

	local grenade_texture = guis_catalog .. "textures/pd2/blackmarket/icons/grenades/" .. tostring(grenade)
	return grenade_texture
end

function ProfileReborn:get_melee_icon(melee_weapon)
	local guis_catalog = "guis/"
	local bundle_folder = tweak_data.blackmarket.melee_weapons[melee_weapon] and tweak_data.blackmarket.melee_weapons[melee_weapon].texture_bundle_folder

	if bundle_folder then
		guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
	end

	local melee_weapon_texture = guis_catalog .. "textures/pd2/blackmarket/icons/melee_weapons/" .. tostring(melee_weapon)
	return melee_weapon_texture
end

function ProfileReborn:get_skillpoints_base(profile)
	local skillpoints = {}
	local skillset = profile.skillset
	local skill_switches = managers.skilltree._global.skill_switches[skillset]
	for i = 1, 15 do
		local point = managers.skilltree:get_tree_progress_new(i, skill_switches)
		skillpoints[i] = point
	end
	
	return skillpoints
end

function ProfileReborn:get_deployable_icon(deployable)
	local deployable_texture
	
	if deployable then
		local guis_catalog = "guis/"
		local bundle_folder = tweak_data.blackmarket.deployables[deployable] and tweak_data.blackmarket.deployables[deployable].texture_bundle_folder

		if bundle_folder then
			guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
		end

		deployable_texture = guis_catalog .. "textures/pd2/blackmarket/icons/deployables/" .. tostring(deployable)
	else
		deployable_texture = "guis/textures/pd2/add_icon"
	end
	
	return deployable_texture
end

function ProfileReborn:get_armor_icon(armor)
	local guis_catalog = "guis/"
	local bundle_folder = tweak_data.blackmarket.armors[armor].texture_bundle_folder

	if bundle_folder then
		guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
	end

	armor_texture = guis_catalog .. "textures/pd2/blackmarket/icons/armors/" .. tostring(armor)

	return armor_texture
end

function ProfileReborn:get_specialization_text(perk)
	local specialization_data = tweak_data.skilltree.specializations[perk]
	local specialization_text = specialization_data and managers.localization:text(specialization_data.name_id) or " "
	
	return string.gsub(specialization_text, "^[%s]*(.-)[%s]*$", "%1")
end

--将Color函数的颜色饱和度增高
---@param color:userdata
function ProfileReborn:Saturation(color)
	local r = color.r
	local g = color.g
	local b = color.b
	local max = math.max(r, g, b)
	
	r = max ~= r and r / 3 or r * 2
	g = max ~= g and g / 3 or g * 2
	b = max ~= b and b / 3 or b * 2

	return Color(r, g, b)
end

--复制table而不是引用
---@param tb:table
function ProfileReborn:table_clone(tb)
	local new_tb = {}

	for k, cls in pairs(tb) do
		new_tb[k] = cls
	end

	return new_tb
end
