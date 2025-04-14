ProfileReborn = ProfileReborn or {}
ProfileReborn.save_path = SavePath .. "ProfileReborn.txt"

local MPath = ModPath
DB:create_entry(Idstring("texture"), Idstring("guis/textures/pd2/profile_rebvorn_none_icon"), MPath .. "assets/profile_rebvorn_none_icon.texture")
DB:create_entry(Idstring("texture"), Idstring("guis/textures/pd2/profile_rebvorn_add_profile_icon"), MPath .. "assets/profile_rebvorn_add_profile_icon.texture")
DB:create_entry(Idstring("texture"), Idstring("guis/textures/pd2/profile_rebvorn_loading_icon"), MPath .. "assets/profile_rebvorn_loading_icon.texture")
DB:create_entry(Idstring("texture"), Idstring("guis/textures/pd2/profile_rebvorn_up_icon"), MPath .. "assets/profile_rebvorn_up_icon.texture")
DB:create_entry(Idstring("texture"), Idstring("guis/textures/pd2/profile_rebvorn_down_icon"), MPath .. "assets/profile_rebvorn_down_icon.texture")

function ProfileReborn:active()
	self._ws = managers.gui_data:create_fullscreen_workspace()
	self._ui_layer = 500
	self._wheel_scroll_value = 60
	self._wheel_scroll_value_custom = 15
	self._filter_list_h = 30
	self._normal_color = Color.white
	self._highlight_color = Color.yellow
	
	self._panel = self._ws:panel():panel({
		layer = self._ui_layer,	
		w = 800,
		h = 500
	})
	self._panel:set_center(self._ws:panel():center_x(), self._ws:panel():center_y())
	
	self._ui_panel = self._panel:panel()
	
	self:load()

	self._current_filter = self.save_data and self.save_data.current_filter or 1
	self._filter = self._ws:panel():panel({
		layer = self._ui_layer,
		w = 150,
		h = 30
	})
	
	self._filter:set_left(self._panel:left())
	self._filter:set_top(self._panel:bottom() + 2)
	local menu_arrows_texture = "guis/textures/menu_arrows"
	local arrow_left = self._filter:bitmap({
		name = "arrow_left",
		texture = menu_arrows_texture,
		layer = 2,
		texture_rect = {
			0,
			0,
			24,
			24
		}
	})
	
	local arrow_right = self._filter:bitmap({
		name = "arrow_right",
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
	
	self.filter_method = {
		"default",
		"perk_deck",
		"custom"
	}
	
	self.perk_deck_display_method = {
		"icon_1",
		"text"
	}
	
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
			layer = layer
		})
	end
	
	arrow_left:set_center_y(self._filter:h() / 2)
	arrow_right:set_center_y(self._filter:h() / 2)
	arrow_right:set_right(self._filter:w())
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
		layer = -50,
		w = self._panel:w(),
		h = self._panel:h()
	})
	
	self:create_side(self._panel)
	self:create_side(self._filter)
	
	self._ui = {}
	self._ui.profile = {}
	self.profile = {}
	self._bg_h = 100
	self._max_length = 15
	self.perk_deck = {}
	self.perk_deck.perks = {}
	self.perk_deck.deck_list = {}
	
	if not self.custom then
		self:set_custom_profile()
	end
	
	self:switch_filter(self._current_filter)

	self._mouse_x = 0
	self._mouse_y = 0
	self._ws:connect_keyboard(Input:keyboard())
	self._panel:key_press(callback(self, self, "key_press"))
	self._panel:key_release(callback(self, self, "key_release"))
	
	self:show()
end

function ProfileReborn:set_profile(ui_panel, idx, profile, profile_idx)
	if not profile then
		return
	end
	
	self.profile[idx] = profile
	
	local text = profile.name or "Profile " .. idx

	if (profile_idx or idx) == managers.multi_profile._global._current_profile then
		text = text
	end
	
	ui_panel[idx] = self._ui_panel:panel({
		layer = profile_idx or 0, --借用层级，存取profile编号
		w = self._rect:w(),
		h = self._bg_h,
		y = self._rect:top() + self._bg_h * idx - self._bg_h + (ui_panel[1] and ui_panel[1]:y() or 0)
	})
	
	local panel = ui_panel[idx]
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
		
		if profile.perk_deck == 23 then
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
	
	local top_line = panel:rect({
		name = "top_line" .. idx,
		visible = false,
		w = panel:w(),
		h = 2
	})
	
	local bottom_line = panel:rect({
		name = "bottom_line" .. idx,
		visible = false,
		w = panel:w(),
		h = 2
	})
	
	local left_line = panel:rect({
		name = "left_line" .. idx,
		visible = false,
		w = 2,
		h = panel:h()
	})
	
	local right_line = panel:rect({
		name = "right_line" .. idx,
		visible = false,
		w = 2,
		h = panel:h()
	})
		
	top_line:set_top(0)
	bottom_line:set_bottom(panel:h())
	left_line:set_left(0)
	right_line:set_right(panel:w())

	local remove_icon = panel:bitmap({
		name = "remove_icon" .. idx,
		visible = false,
		texture = "guis/textures/pd2/profile_rebvorn_none_icon",
		alpha = 0.5,
		w = 40,
		h = 40,
		layer = 3
	})
	
	remove_icon:set_bottom(panel:h()-5)
	remove_icon:set_right(panel:right())
	
	local down_icon = panel:bitmap({
		name = "down_icon" .. idx,
		visible = false,
		texture = "guis/textures/pd2/profile_rebvorn_down_icon",
		alpha = 0.5,
		w = 40,
		h = 40,
		layer = 3
	})
	
	down_icon:set_bottom(panel:h()-5)
	down_icon:set_right(remove_icon:left())
	
	local up_icon = panel:bitmap({
		name = "up_icon" .. idx,
		visible = false,
		texture = "guis/textures/pd2/profile_rebvorn_up_icon",
		alpha = 0.5,
		w = 40,
		h = 40,
		layer = 3
	})
	
	up_icon:set_bottom(panel:h()-5)
	up_icon:set_right(down_icon:left())
	
	local text_color = self._normal_color
	
	if profile_idx == managers.multi_profile._global._current_profile then
		text_color = self._highlight_color
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
	
	local skillpoints = self:get_skillpoints_base(idx)
	local mas_skillpoints = "Mas:" .. skillpoints[1] .. " " .. skillpoints[2] .. " " .. skillpoints[3]
	local enf_skillpoints = "Enf:" .. skillpoints[4] .. " " .. skillpoints[5] .. " " .. skillpoints[6]
	local tec_skillpoints = "Tec:" .. skillpoints[7] .. " " .. skillpoints[8] .. " " .. skillpoints[9]
	local gho_skillpoints = "Gho:" .. skillpoints[10] .. " " .. skillpoints[11] .. " " .. skillpoints[12]
	local fug_skillpoints = "Fug:" .. skillpoints[13] .. " " .. skillpoints[14] .. " " .. skillpoints[15]
	local skillpoint_text = mas_skillpoints .. "   " .. enf_skillpoints .. "   " .. tec_skillpoints .. "   " .. gho_skillpoints .. "   " .. fug_skillpoints
	local skillpoints_text = panel:text({
		vertical = "top",
		font = tweak_data.hud_players.ammo_font,
		text = skillpoint_text,
		font_size = 13,
		layer = 3,
		x = secondary_weapon:left()
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
	local mask_texture = managers.blackmarket:get_mask_icon(Global.blackmarket_manager.crafted_items["masks"][slot].mask_id)
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
	self._panel:remove(self._ui_panel)
	
	self._ui_panel = self._panel:panel()
	self._ui.profile = {}
	self.profile = {}
	
	--remove PerkDeck filter
	if self._current_filter ~= 2 then
		if self.perk_deck.deck_list.icon then
			self._ws:panel():remove(self.perk_deck.deck_list.icon)
			self.perk_deck.deck_list.icon = nil
		end
		
		if self.perk_deck.deck_list.text then
			self._ws:panel():remove(self.perk_deck.deck_list.text)
			self.perk_deck.deck_list.text = nil
		end
		
		self.perk_deck.current_perk = nil
		
		if self.perk_display_mode_panel then
			self._ws:panel():remove(self.perk_display_mode_panel)
			self.perk_display_mode_panel = nil
		end
	end
	
	--remove Custom Profile
	if self.custom and self.custom.panel then
		self._panel:remove(self.custom.panel)
		self._ws:panel():remove(self.custom.filter_list)
		self._ws:panel():remove(self.custom.tool_list)
	end
	
	self:load()
	self:save()
end

function ProfileReborn:mouse_moved(o, x, y)
	if not self._panel then
		return
	end
	
	self._mouse_x = x
	self._mouse_y = y
	self._mouse_inside = false
	self._touch_profile = nil	
	self._touch_ui = nil
	
	-- if self._panel:inside(self._mouse_x, self._mouse_y) then
	for idx, box in pairs(self._ui.profile) do
		local profile = self._ui.profile[idx]
		if box:inside(self._mouse_x, self._mouse_y) and self._mouse_y > self._panel:y() and self._mouse_y < (self._panel:y() + self._panel:h()) then
			self._mouse_inside = true
			self._touch_profile = box:layer() == 0 and idx or box:layer()
			self._touch_ui = idx
			profile:child("top_line" .. idx):show()
			profile:child("bottom_line" .. idx):show()
			profile:child("left_line" .. idx):show()
			profile:child("right_line" .. idx):show()
			
			if self._current_filter == 3 then
				profile:child("remove_icon" .. idx):show()
				profile:child("up_icon" .. idx):show()
				profile:child("down_icon" .. idx):show()
			end
		else
			profile:child("top_line" .. idx):hide()
			profile:child("bottom_line" .. idx):hide()
			profile:child("left_line" .. idx):hide()
			profile:child("right_line" .. idx):hide()
			profile:child("remove_icon" .. idx):hide()
			profile:child("up_icon" .. idx):hide()
			profile:child("down_icon" .. idx):hide()
		end
	end
	-- end
	
	-- filter arrow
	if self._filter:child("arrow_left"):inside(x, y) or self._filter:child("arrow_right"):inside(x, y) then
		self._mouse_inside = true
	end
	
	-- deck list
	if self._current_filter == 2 then
		if self.perk_deck.display_mode == 1 then
			if self.perk_deck.deck_list.icon and self.perk_deck.deck_list.icon:inside(x, y) then
				for _, data in ipairs(self.perk_deck.LeftList) do
					if data.bitmap:inside(x, y) and data.id ~= self.perk_deck.current_perk then
						self._mouse_inside = true
						break
					end
				end
			end
		elseif self.perk_deck.display_mode == 2 then
			for _, child in pairs(self.perk_deck.deck_list.text:children()) do
				if child:layer() == self.perk_deck.current_perk then
					child:child("text_perk_rect"):set_alpha(0.75)
				elseif child:inside(x, y) then
					child:child("text_perk_rect"):set_alpha(0.5)
					self._mouse_inside = true
				else
					child:child("text_perk_rect"):set_alpha(0)
				end
			end
		end
		
		if self.perk_display_mode_panel:child("arrow_left"):inside(x, y) or self.perk_display_mode_panel:child("arrow_right"):inside(x, y) then
			self._mouse_inside = true
		end
	end
	
	-- #CustomProfile
	
	-- ##NewFilter
	if self._current_filter == 3 then
		if #self.custom.filters <=0 and self.custom.panel:child("add_first_filter"):inside(x, y) then
			self._mouse_inside = true
		end

		-- filterList

		for _, data in ipairs(self.custom.filters) do
			if data.key == self.custom.current_custom_filter then
				data.panel:child("custom_filter_rect"):set_alpha(0.75)
			elseif data.panel:inside(x, y) then
				self._mouse_inside = true
				data.panel:child("custom_filter_rect"):set_alpha(0.5)
			else
				data.panel:child("custom_filter_rect"):set_alpha(0)
			end
		end
		
		-- toolList
		
		for _, panel in ipairs(self._tool_list) do
			if panel:inside(x, y) then
				self._mouse_inside = true
				panel:set_alpha(1)
			else
				panel:set_alpha(0.5)
			end
		end
		
		local profile = self._ui.profile[self._touch_ui]
		
		if profile and profile:inside(x, y) then
			local little_icons = {
				profile:child("remove_icon" .. self._touch_ui),
				profile:child("up_icon" .. self._touch_ui),
				profile:child("down_icon" .. self._touch_ui)
			}
			
			for _, icon in ipairs(little_icons) do
				if icon:inside(x, y) then
					icon:set_alpha(1)
				else
					icon:set_alpha(0.5)
				end
			end
		end
	end
	
	if self._mouse_inside then
		managers.mouse_pointer:set_pointer_image("link")
	else
		managers.mouse_pointer:set_pointer_image("arrow")
	end
	
	-- filter bg color
	if self._filter:inside(x, y) then
		self._filter_bg:set_color(Color(40, 30, 105, 100) / 255)
	else
		self._filter_bg:set_color(Color.black)
	end
end

function ProfileReborn:mouse_pressed(o, button, x, y)
	if self._selected then
		return
	end
	
	local ccf = self.custom.current_custom_filter

	if button == Idstring("mouse wheel down") then
		if self._rect:inside(x, y) then
			self:wheel_scroll_bd(-self._wheel_scroll_value)
		end
		
		if self.perk_deck.display_mode == 1 then
			if self.perk_deck.deck_list.icon and self.perk_deck.deck_list.icon:inside(x, y) then
				self:wheel_scroll_perk(-self.perk_deck.deck_list.icon:w())
			end
		elseif self.perk_deck.display_mode == 2 then
			if self.perk_deck.deck_list.text and self.perk_deck.deck_list.text:inside(x, y) then
				self:wheel_scroll_perk(-self._wheel_scroll_value_custom)
			end			
		end
		
		if self._current_filter == 3 and self.custom.filter_list:inside(x, y) then
			self:wheel_scroll_custom(-self._wheel_scroll_value_custom)
		end
	elseif button == Idstring("mouse wheel up") then
		if self._rect:inside(x, y) then
			self:wheel_scroll_bd(self._wheel_scroll_value)
		end
		
		if self.perk_deck.display_mode == 1 then
			if self.perk_deck.deck_list.icon and self.perk_deck.deck_list.icon:inside(x, y) then
				self:wheel_scroll_perk(self.perk_deck.deck_list.icon:w())
			end
		elseif self.perk_deck.display_mode == 2 then
			if self.perk_deck.deck_list.text and self.perk_deck.deck_list.text:inside(x, y) then
				self:wheel_scroll_perk(self._wheel_scroll_value_custom)
			end			
		end
		if self._current_filter == 3 and self.custom.filter_list:inside(x, y) then
			self:wheel_scroll_custom(self._wheel_scroll_value_custom)
		end
	end
	
	if button == Idstring("0") then
		if self._touch_profile then
			local profile = self._ui.profile[self._touch_ui]
			if self._current_filter == 3 then
				if profile:child("remove_icon" .. self._touch_ui):inside(x, y) then
					local current_filter = self:get_current_custom_filter()
					local profiles = current_filter.profiles

					table.remove(profiles, self._touch_ui)
					self:switch_filter(3, ccf)
				elseif profile:child("up_icon" .. self._touch_ui):inside(x, y) then
					if self._touch_ui > 1 then
						local f = self._touch_ui
						local t = self._touch_ui - 1
						
						self:swap_profile(f, t)
						self:switch_filter(3, ccf)
					end
				elseif profile:child("down_icon" .. self._touch_ui):inside(x, y) then
					if self._touch_ui < #self._ui.profile then
						local f = self._touch_ui
						local t = self._touch_ui + 1
						
						self:swap_profile(f, t)
						self:switch_filter(3, ccf)
					end
				else
					managers.multi_profile:set_current_profile(self._touch_profile)
					self:hide()
				end
			else
				managers.multi_profile:set_current_profile(self._touch_profile)
				self:hide()			
			end
		elseif self._filter:child("arrow_left"):inside(x, y) then		
			self:switch_filter(self._current_filter - 1)
		elseif self._filter:child("arrow_right"):inside(x, y) then
			self:switch_filter(self._current_filter + 1)
		end
		
		if self._current_filter == 2 then
			if self.perk_deck.display_mode == 1 then
				if self.perk_deck.deck_list.icon and self.perk_deck.deck_list.icon:inside(x, y) then
					for _, data in ipairs(self.perk_deck.LeftList) do
						if data.bitmap:inside(x, y) then
							self:switch_perk(data.id)
							break
						end
					end
				end
			elseif self.perk_deck.display_mode == 2 then
				if self.perk_deck.deck_list.text and self.perk_deck.deck_list.text:inside(x, y) then
					for key, panel in pairs(self.perk_deck.deck_list.text:children()) do
						if panel:inside(x, y) then
							if panel:layer() ~= self.perk_deck.current_perk then
								self:switch_perk(panel:layer())
							end
						end
					end
				end
			end
			
			if self.perk_display_mode_panel:child("arrow_left"):inside(x, y) then		
				self:set_perks_display_mode(self.perk_deck.display_mode - 1)
			elseif self.perk_display_mode_panel:child("arrow_right"):inside(x, y) then
				self:set_perks_display_mode(self.perk_deck.display_mode + 1)
			end
		end
		-- #CustomProfile
		
		if self._current_filter == 3 then
			--##NewCustom
			if #self.custom.filters <= 0 and self.custom.panel:child("add_first_filter"):inside(x, y) then
				self:start_input()
				managers.mouse_pointer:set_pointer_image("arrow")
				
				-- for _, panel in ipairs(self.custom.first_panel) do
					-- self.custom.panel:remove(panel)
				-- end
			end
			
			if self.custom.tool_list:child("tool_icon_add_filter"):inside(x, y) then
				if #self.custom.filters <=0 then
					for _, panel in ipairs(self.custom.first_panel) do
						self.custom.panel:remove(panel)
					end
				end
				
				self:start_input()
				managers.mouse_pointer:set_pointer_image("arrow")
			elseif self.custom.tool_list:child("tool_icon_add_profile"):inside(x, y) then
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
					
					if #self.custom.filters > 0 then
						for _, panel in ipairs(self.custom.first_panel) do
							panel:hide()
						end
					end
				else
					self:dialog_please_create_a_filter()
				end
			elseif self.custom.tool_list:child("tool_icon_rename"):inside(x, y) then
				if #self.custom.filters > 0 then
					self:start_input(true)
				else
					self:dialog_please_create_a_filter()
				end
			elseif self.custom.tool_list:child("tool_icon_up"):inside(x, y) then
				if #self.custom.filters > 0 then
					if ccf > 1 then
						self:swap_filter(ccf, ccf - 1)
						self:switch_filter(3, ccf-1)
					end
				else
					self:dialog_please_create_a_filter()
				end
			elseif self.custom.tool_list:child("tool_icon_down"):inside(x, y) then
				if #self.custom.filters > 0 then
					if ccf < #self.custom.filters then
						self:swap_filter(ccf, ccf + 1)
						self:switch_filter(3, ccf + 1)
					end
				else
					self:dialog_please_create_a_filter()
				end
			elseif self.custom.tool_list:child("tool_icon_remove_filter"):inside(x, y) then
				if #self.custom.filters > 0 then
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
					
					if #self.custom.filters <= 0 then
						for _, panel in ipairs(self.custom.first_panel) do
							panel:show()
						end
					end
				else
					self:dialog_please_create_a_filter()
				end
			end
			
			--##SetCustom
			for num, filter in ipairs(self.custom.filters) do
				if filter.panel:inside(x, y) then
					self:switch_filter(3, num)
					break
				end
			end
		end
	end
end

function ProfileReborn:mouse_released(o, button, x, y)
end

function ProfileReborn:mouse_clicked(o, button, x, y)
end

function ProfileReborn:key_press(o, k)
	-- if self._selected then
		-- return
	-- end
	
	local mouse_callbacks = managers.mouse_pointer._mouse_callbacks
	if mouse_callbacks and mouse_callbacks[#mouse_callbacks] and mouse_callbacks[#mouse_callbacks].id ~= self._mouse_id then
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
		self:set_profile(self._ui.profile, idx, profile, idx)
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
	
	
	self.perk_deck.deck_list.icon = self._ws:panel():panel({
		layer = self._ui_layer + 1,
		w = 50,
		h = self._panel:h()
	})
	
	self.perk_deck.deck_list.text = self._ws:panel():panel({
		layer = self._ui_layer + 1,
		w = 200,
		h = self._panel:h()
	})
	
	self.perk_deck.panels = {
		self.perk_deck.deck_list.icon,
		self.perk_deck.deck_list.text
	}
	
	local deck_list_icon = self.perk_deck.deck_list.icon
	deck_list_icon:set_right(self._panel:left())
	deck_list_icon:set_top(self._panel:top())
	
	local deck_list_text = self.perk_deck.deck_list.text
	deck_list_text:set_right(self._panel:left()-1)
	deck_list_text:set_top(self._panel:top())
	
	-- deck_list_icon:rect({
		-- name = "deck_list_rect",
		-- color = Color.black,
		-- layer = -50,
		-- alpha = 0.6,
		-- w = deck_list_icon:w(),
		-- h = deck_list_icon:h()
	-- })
	
	local last_perk
	self.perk_deck.LeftList = {}
	self.perk_deck.LeftListText = {}
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
			
			local last_panel = deck_list_icon:child("perk_icon_" .. tostring(last_perk))
				
			local perk_icon = deck_list_icon:bitmap({
				name = "perk_icon_" .. tostring(perk),
				texture = icon_atlas_texture,
				texture_rect = texture_rect,
				layer = 1,
				y = last_panel and last_panel:bottom() or 0,
				w = deck_list_icon:w(),
				h = deck_list_icon:w()
			})
				
			perk_icon:set_center_x(deck_list_icon:w() / 2 - 2)
				
			self.perk_deck.LeftList[#self.perk_deck.LeftList+1] = {
				bitmap = perk_icon,
				id = perk
			}
			
			-- display_mode 2
			local perk_text = self:get_specialization_text(perk)
			local last_panel = deck_list_text:child("perk_text_" .. tostring(last_perk))
				
			local text_perk_panel = self.perk_deck.deck_list.text:panel({
				name = "perk_text_" .. tostring(perk),
				y = last_panel and last_panel:bottom() or 0,
				w = deck_list_text:w(),
				h = self._filter_list_h,
				layer = perk
			})

			
			local text_perk_rect = text_perk_panel:rect({
				name = "text_perk_rect",
				color = Color(173 / 255,216 / 255,230 / 255),
				layer = 1,
				alpha = 0,
				w = text_perk_panel:w(),
				h = self._filter_list_h
			})
				
			text_perk_rect:set_center_x(text_perk_panel:w() / 2)
				
			local text_perk_text = text_perk_panel:text({
				vertical = "center",
				valign = "center",
				align = "right",
				halign = "right",
				layer = 2,
				font = tweak_data.hud_players.ammo_font,
				text = string.upper(perk_text),
				font_size = 20
			})	
				
			local center_x = text_perk_panel:w() / 2
			local center_y = text_perk_panel:h() / 2
			text_perk_text:set_center_y(center_y)
			text_perk_text:set_right(text_perk_panel:right())
			
			self.perk_deck.LeftListText[#self.perk_deck.LeftListText+1] = {
				bitmap = text_perk_panel,
				id = perk
			}
			
			last_perk = perk
		end
	end end
	
	self.perk_display_mode_panel = self._ws:panel():panel({
		layer = self._ui_layer,
		w = 150,
		h = 30
	})
	
	self.perk_display_mode_panel:set_right(self._filter:left())
	self.perk_display_mode_panel:set_top(self._panel:bottom() + 2)
	
	local menu_arrows_texture = "guis/textures/menu_arrows"
	local arrow_left = self.perk_display_mode_panel:bitmap({
		name = "arrow_left",
		texture = menu_arrows_texture,
		layer = 2,
		texture_rect = {
			0,
			0,
			24,
			24
		}
	})
	
	local arrow_right = self.perk_display_mode_panel:bitmap({
		name = "arrow_right",
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
	
	local display_mode_text = "menu_bp_perk_display_" .. self.perk_deck_display_method[self.perk_deck.display_mode]
	self.perk_display_mode_text = self.perk_display_mode_panel:text({
		name = "perk_display_mode_text",
		vertical = "center",
		valign = "center",
		align = "center",
		halign = "center",
		font = tweak_data.hud_players.ammo_font,
		text = string.upper(managers.localization:text(display_mode_text)),
		font_size = 18
	})
		
	arrow_left:set_center_y(self.perk_display_mode_panel:h() / 2)
	arrow_right:set_center_y(self.perk_display_mode_panel:h() / 2)
	arrow_right:set_right(self.perk_display_mode_panel:w())	
	for key, panel in ipairs(self.perk_deck.panels) do
		if self.perk_deck.display_mode ~= key then
			panel:hide()
		end
	end
	-- local selected = deck_list_icon:rect({
		-- visible = true,
		-- w = 5,
		-- h = deck_list_icon:h()
	-- })
	
	local current_profile = managers.multi_profile:current_profile()
	self:switch_perk(current_profile.perk_deck)
end

function ProfileReborn:set_custom_profile(base_filter)
	self.custom = {}
	self.custom.filters = {}
	self.custom.panel = self._panel:panel({})
	
	local base_filter = base_filter or (self.save_data and self.save_data.current_custom_filter) or 1
	
	local filters = self.custom.filters
	
	self.custom.filter_list = self._ws:panel():panel({
		layer = self._ui_layer,
		w = 200,
		h = self._panel:h()
	})
	
	local filter_list = self.custom.filter_list
	filter_list:set_right(self._panel:left() - 1)
	filter_list:set_top(self._panel:top())
	
	filter_list:rect({
		name = "filter_list_rect",
		color = Color.black,
		layer = -2,
		alpha = 0,
		w = filter_list:w(),
		h = filter_list:h()
	})
	
	if self.save_data and self.save_data.custom then
		for k1, data in ipairs(self.save_data.custom) do
			filters[data.key] = {
				name = data.name or "CustomFilter#" .. tostring(data.key),
				panel = self:create_filter_ui(data.name, data.key),
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
	
	if filters[base_filter] then
		filters[base_filter].panel:child("custom_filter_rect"):set_alpha(0.75)
		
		for key, data in pairs(filters[base_filter].profiles) do
			self:set_profile(self._ui.profile, key, data.profile, data.idx)
		end
	end

	local add_filter_icon = self.custom.panel:bitmap({
		texture = "guis/textures/pd2/none_icon",
		rotation = 45,
	})
	
	local add_first_filter= self.custom.panel:text({
		name = "add_first_filter",
		color = Color.black,
		alpha = 0,
		w = self._panel:w() * 0.8,
		h = self._panel:h() * 0.8
	})
	
	local add_filter_text = self.custom.panel:text({
		vertical = "center",
		valign = "center",
		align = "center",
		halign = "center",
		font = tweak_data.hud_players.ammo_font,
		text = string.upper(managers.localization:text("menu_bp_center_text")),
		font_size = 25
	})
	
	local center_x = self._panel:w() / 2
	local center_y = self._panel:h() / 2
	add_filter_icon:set_center(center_x, center_y)
	add_first_filter:set_center(center_x, center_y)
	add_filter_text:set_center(center_x, center_y - 50)
	
	self.custom.first_panel = {
		add_filter_icon,
		add_filter_text
	}
	
	if #self.custom.filters > 0 then
		for _, panel in ipairs(self.custom.first_panel) do
			panel:hide()
		end
	end
	
	self.custom.tool_list = self._ws:panel():panel({
		layer = self._ui_layer,
		w = 50,
		h = self._panel:h()
	})
	
	local tool_list = self.custom.tool_list
	
	tool_list:set_left(self._panel:right())
	tool_list:set_top(self._panel:top())

	tool_list:rect({
		name = "tool_list_rect",
		color = Color.black,
		layer = -50,
		alpha = 0.3,
		w = tool_list:w(),
		h = tool_list:h()
	})
	
	local tool_icon_add_filter = tool_list:bitmap({
		name = "tool_icon_add_filter",
		texture = "guis/textures/pd2/profile_rebvorn_none_icon",
		rotation = 45,
		color = tweak_data.screen_colors.text,
		alpha = 0.5,
		layer = 1,
		y = 0,
		w = tool_list:w() * 1,
		h = tool_list:w() * 1
	})
	
	local tool_icon_add_profile = tool_list:bitmap({
		name = "tool_icon_add_profile",
		texture = "guis/textures/pd2/profile_rebvorn_add_profile_icon",
		color = tweak_data.screen_colors.text,
		alpha = 0.5,
		layer = 1,
		y = tool_icon_add_filter:bottom(),
		w = tool_list:w() * 1,
		h = tool_list:w() * 1
	})
	
	local tool_icon_rename = tool_list:bitmap({
		name = "tool_icon_rename",
		texture = "guis/textures/pd2/profile_rebvorn_loading_icon",
		color = tweak_data.screen_colors.text,
		alpha = 0.5,
		layer = 1,
		y = tool_icon_add_profile:bottom(),
		w = tool_list:w() * 1,
		h = tool_list:w() * 1
	})
	
	local tool_icon_up = tool_list:bitmap({
		name = "tool_icon_up",
		texture = "guis/textures/pd2/profile_rebvorn_up_icon",
		color = tweak_data.screen_colors.text,
		alpha = 0.5,
		layer = 1,
		y = tool_icon_rename:bottom(),
		w = tool_list:w() * 1,
		h = tool_list:w() * 1
	})
	
	local tool_icon_down = tool_list:bitmap({
		name = "tool_icon_down",
		texture = "guis/textures/pd2/profile_rebvorn_down_icon",
		color = tweak_data.screen_colors.text,
		alpha = 0.5,
		layer = 1,
		y = tool_icon_up:bottom(),
		w = tool_list:w() * 1,
		h = tool_list:w() * 1
	})
	
	local tool_icon_remove_filter = tool_list:bitmap({
		name = "tool_icon_remove_filter",
		texture = "guis/textures/pd2/profile_rebvorn_none_icon",
		layer = 1,
		color = tweak_data.screen_colors.text,
		alpha = 0.5,
		y = tool_icon_down:bottom(),
		w = tool_list:w() * 1,
		h = tool_list:w() * 1
	})
	
	self._tool_list = {
		tool_icon_add_filter,
		tool_icon_add_profile,
		tool_icon_rename,
		tool_icon_up,
		tool_icon_down,
		tool_icon_remove_filter
	}
	
	tool_icon_add_filter:set_center_x(tool_list:w() / 2 + 0.5)
	tool_icon_add_profile:set_center_x(tool_list:w() / 2)
	tool_icon_rename:set_center_x(tool_list:w() / 2)
	tool_icon_up:set_center_x(tool_list:w() / 2)
	tool_icon_down:set_center_x(tool_list:w() / 2)
	tool_icon_remove_filter:set_center_x(tool_list:w() / 2)
	
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
		w = self._panel:w(),
		h = self._panel:h()
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

function ProfileReborn:set_perks_display_mode(mode)
	if mode <= 0 then
		mode = 1
	elseif mode >= #self.perk_deck_display_method + 1 then
		mode = #self.perk_deck_display_method
	end
	
	self.perk_deck.display_mode = mode
	
	for key, panel in ipairs(self.perk_deck.panels) do
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
	
	self:set_profile(self._ui.profile, new_profile, profile, idx)

	filter.profiles[new_profile] = {
		profile = profile,
		idx = idx
	}
end

function ProfileReborn:create_new_filter(name)
	local key = #self.custom.filters + 1
	self.custom.filters[key] = {
		name = name or "CustomFilter#" .. tostring(key),
		panel = self:create_filter_ui(name, key),
		key = key,
		profiles = {}
	}
	
	local filters = self.custom.filters
	
	self.custom.current_custom_filter = #filters
	
	filters[key].panel:child("custom_filter_rect"):set_alpha(0.75)
	
	for cidx, filter in ipairs(filters) do
		if cidx ~= key then
			filter.panel:child("custom_filter_rect"):set_alpha(0)
		end
	end
	
	self:switch_filter(3, key)
end

function ProfileReborn:create_filter_ui(name, key)
	local last_filter = self.custom.filters[key-1]
	local filter = self.custom.filter_list:panel({
		y = last_filter and last_filter.panel:bottom() or 0,
		w = self.custom.filter_list:w(),
		h = self._filter_list_h
	})
	
	local custom_filter = filter:rect({
		name = "custom_filter_rect",
		color = Color(173 / 255,216 / 255,230 / 255),
		layer = 1,
		alpha = 0,
		w = self.custom.filter_list:w(),
		h = self._filter_list_h
	})
	
	custom_filter:set_center_x(self.custom.filter_list:w() / 2)
	
	local custom_filter_text = filter:text({
		vertical = "center",
		valign = "center",
		align = "right",
		halign = "right",
		layer = 2,
		font = tweak_data.hud_players.ammo_font,
		text = name or "CustomFilter#" .. tostring(key),
		font_size = 20
	})	
	
	local center_x = filter:w() / 2
	local center_y = filter:h() / 2
	custom_filter_text:set_center_y(center_y)
	custom_filter_text:set_right(filter:right())
	
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
	

	if self._bg_h * #self._ui.profile >= self._panel:h() then
		local current_ui
		if self._current_filter ~= 1 then
			for k, ui in ipairs(self._ui.profile) do
				if ui:layer() == managers.multi_profile._global._current_profile then
					current_ui = k
					break
				end
			end
		else
			current_ui = managers.multi_profile._global._current_profile
		end

		if self._ui.profile[current_ui] and self._ui.profile[current_ui]:y() > (self._panel:h() / 2 - self._bg_h / 2) then
			local dy = self._ui.profile[current_ui]:y() - (self._panel:h() / 2 - self._bg_h / 2)
			self:wheel_scroll_bd(-dy)
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
		self:reset_panel()
	
		for i = 1, #profile do
			self:set_profile(self._ui.profile, i, profile[i].profile, profile[i].idx)
		end
		
		for _, data in ipairs(self.perk_deck.LeftList) do
			data.bitmap:set_color(Color.white)
		end
		
		if self.perk_deck.deck_list.icon then
			local perk_icon = self.perk_deck.deck_list.icon:child("perk_icon_" .. perk)
			
			if perk_icon then
				perk_icon:set_color(Color(88 / 255, 87 / 255, 86 / 255))
			end
		end
		
		if self.perk_deck.deck_list.text then
			local perk_text = self.perk_deck.deck_list.text:child("perk_text_" .. perk)
			
			if perk_text then
				perk_text:child("text_perk_rect"):set_alpha(0.75)
			end
			
			if self.perk_deck.current_perk then
				self.perk_deck.deck_list.text:child("perk_text_" .. self.perk_deck.current_perk):child("text_perk_rect"):set_alpha(0)
			end
		end
		
		self.perk_deck.current_perk = perk
		managers.mouse_pointer:set_pointer_image("arrow")
	end
end

function ProfileReborn:rename_filter(index, new_name)
	self.custom.filters[index].name = new_name
	self:save()					
	self:switch_filter(3)
end

function ProfileReborn:wheel_scroll_bd(dy)
	local profiles = self._ui.profile

	if self._bg_h * #profiles >= self._panel:h() then
		if dy > 0 then
			dy = profiles[1]:top() + dy >= 0 and -profiles[1]:top() or dy
		else
			if profiles[#profiles]:bottom() + dy <= self._panel:h() then
				dy = self._panel:h() - profiles[#profiles]:bottom()
			end
		end

		for idx, panel in ipairs(profiles) do
			panel:set_y(panel:top() + dy)
		end
	end
end

function ProfileReborn:wheel_scroll_perk(dy)
	if self.perk_deck.display_mode == 1 then
		if self.perk_deck.deck_list.icon:w() * #self.perk_deck.LeftList >= self.perk_deck.deck_list.icon:h() then
			local minimum_perk
			local last_perk
			for _, child in ipairs(self.perk_deck.LeftList) do
				minimum_perk = self.perk_deck.LeftList[1].bitmap
				break
			end
			
			for _, child in ipairs(self.perk_deck.LeftList) do
				last_perk = self.perk_deck.LeftList[#self.perk_deck.LeftList].bitmap
				break
			end
			
			if dy > 0 then
				if minimum_perk:y() + dy >= 0 then
					dy = -minimum_perk:y()
				end
			else
				if last_perk:bottom() + dy <= self._panel:h() then
					dy = self.perk_deck.deck_list.icon:h() - last_perk:bottom()
				end			
			end
			
			for _, data in ipairs(self.perk_deck.LeftList) do
				data.bitmap:set_y(data.bitmap:y() + dy)
			end
		end
	elseif self.perk_deck.display_mode == 2 then
		if self._filter_list_h * #self.perk_deck.LeftListText >= self.perk_deck.deck_list.text:h() then
			local minimum
			local last
			
			minimum = self.perk_deck.LeftListText[1].bitmap
			last = self.perk_deck.LeftListText[#self.perk_deck.LeftListText].bitmap
			
			if dy > 0 then
				if minimum:y() + dy >= 0 then
					dy = -minimum:y()
				end
			else
				if last:bottom() + dy <= self._panel:h() then
					dy = self.perk_deck.deck_list.text:h() - last:bottom()
				end
			end
			
			for _, data in ipairs(self.perk_deck.LeftListText) do
				data.bitmap:set_y(data.bitmap:y() + dy)
			end
		end	
	end
end

function ProfileReborn:wheel_scroll_custom(dy)
	if self._filter_list_h * #self.custom.filters >= self.custom.filter_list:h() then
		local minimum_filter
		local last_filter
		for _, child in ipairs(self.custom.filters) do
			minimum_filter = self.custom.filters[1].panel
			break
		end
		
		for _, child in ipairs(self.custom.filters) do
			last_filter = self.custom.filters[#self.custom.filters].panel
			break
		end
		
		if dy > 0 then
			if minimum_filter:y() + dy >= 0 then
				dy = -minimum_filter:y()
			end
		else
			if last_filter:bottom() + dy <= self._panel:h() then
				dy = self._panel:h() - last_filter:bottom()
			end			
		end
		
		for _, data in ipairs(self.custom.filters) do
			data.panel:set_y(data.panel:y() + dy)
		end
	end
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
	self._editing = editing
	self._input_panel:set_visible(editing)
	
	if editing then
		managers.menu:active_menu().input:set_force_input(false)
		managers.menu:active_menu().input:deactivate_mouse()
		managers.mouse_pointer:remove_mouse(self._mouse_data)
		self._input_panel:enter_text(callback(self, self, "enter_text"))

		local n = utf8.len(self._name_text:text())

		self._name_text:set_selection(n, n)

		if _G.IS_VR then
			Input:keyboard():show_with_text(self._name_text:text(), self._max_length)
		end
	else
		managers.menu:active_menu().input:activate_mouse()
		managers.mouse_pointer:use_mouse(self._mouse_data)
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

function ProfileReborn:get_skillpoints_base(idx)
	local skillpoints = {}
	local skillset = self.profile[idx].skillset
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
