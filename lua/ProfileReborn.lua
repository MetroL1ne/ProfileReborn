--代码写的很烂，分几年写的，别在意
ProfileReborn = ProfileReborn or {}
ProfileReborn.save_path = SavePath .. "ProfileReborn.txt"

function ProfileReborn:active()
	self._ws = managers.gui_data:create_fullscreen_workspace()
	self._ui_layer = 100
	self._panel = self._ws:panel():panel({
		layer = self._ui_layer,	
		w = 800,
		h = 500
	})
	self._panel:set_center(self._ws:panel():center_x(), self._ws:panel():center_y())
	
	self._ui_panel = self._panel:panel()
	
	local save_data = io.load_as_json(self.save_path)

	self._current_filter = save_data and save_data.filter or 1
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
		layer = -2,
		w = self._filter:w(),
		h = self._filter:h()
	})
	
	self._bg = self._ws:panel():bitmap({
		render_template = "VertexColorTexturedBlur3D",
		texture = "guis/textures/test_blur_df",
		w = 1000,
		h = 1000,
		layer = self._ui_layer - 1,
		color = Color.white
	})
	
	self._rect = self._panel:rect({
		color = Color.black,
		alpha = 0.9,
		layer = -1,
		w = self._panel:w(),
		h = self._panel:h()
	})
	
	self:create_side(self._panel)
	self:create_side(self._filter)
	
	self._ui = {}
	self.profile = {}
	self._bg_h = 100
	
	self:switch_filter(self._current_filter)

	self._mouse_x = 0
	self._mouse_y = 0
	self._ws:connect_keyboard(Input:keyboard())
	self._panel:key_press(callback(self, self, "key_press"))
	self._panel:key_release(callback(self, self, "key_release"))
	
	self:show()
end

function ProfileReborn:set_profile(ui_panel, idx, profile, profile_idx)
	local text = profile.name or "Profile " .. idx

	if (profile_idx or idx) == managers.multi_profile._global._current_profile then
		text = utf8.char(187) .. text
	end
	
	ui_panel[idx] = self._ui_panel:panel({
		layer = profile_idx or 0, --借用层级，存取profile编号
		w = self._rect:w(),
		h = self._bg_h,
		y = self._rect:top() + self._bg_h * idx - self._bg_h
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
		local icon_atlas_texture, texture_rect = self:get_specialization_icon(perk_deck[1])
		local profile_icon_bg = panel:bitmap({
			texture = icon_atlas_texture,
			texture_rect = texture_rect,
			alpha = 0.3,
			layer = 2,
			w = profile_bg:h() * 0.5,
			h = profile_bg:h() * 0.5
		})
		profile_icon_bg:set_right(profile_bg:right())
	end
	
	local top_line = panel:rect({
		name = "top_line_" .. idx,
		visible = false,
		w = panel:w(),
		h = 2
	})
	
	local bottom_line = panel:rect({
		name = "bottom_line_" .. idx,
		visible = false,
		w = panel:w(),
		h = 2
	})
	
	local left_line = panel:rect({
		name = "left_line_" .. idx,
		visible = false,
		w = 2,
		h = panel:h()
	})
	
	local right_line = panel:rect({
		name = "right_line_" .. idx,
		visible = false,
		w = 2,
		h = panel:h()
	})
		
	top_line:set_top(0)
	bottom_line:set_bottom(panel:h())
	left_line:set_left(0)
	right_line:set_right(panel:w())
		
	local profile_text = panel:text({
		font = tweak_data.hud_players.ammo_font,
		text = text,
		font_size = 12,
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
		font_size = 12,
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
	
	if game_state_machine then
		game_state_machine:current_state():set_controller_enabled(not managers.player:player_unit())
	end
		
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
end

function ProfileReborn:hide()
	managers.mouse_pointer:remove_mouse(self._mouse_data)
	
    if game_state_machine then
		game_state_machine:current_state():set_controller_enabled(true)
    end
	
	local active_menu = managers.menu:active_menu()
	local is_pc_controller = managers.menu:is_pc_controller()
	if active_menu and not is_pc_controller then
		active_menu.input:activate_controller_mouse()
	end
	
	self._ws:hide()
	managers.gui_data:destroy_workspace(self._ws)

	--^^--
	
	local save_data = {
		filter = self._current_filter
	}
	
	io.save_as_json(save_data, self.save_path)
end

function ProfileReborn:reset_panel()
	self._panel:remove(self._ui_panel)
	
	self._ui_panel = self._panel:panel()
	self._ui.profile = {}
	self.profile = {}
	
	--remove PerkDeck filter
	if self.deck_list and self._current_filter ~= 2 then
		self._ws:panel():remove(self.deck_list)
		self.deck_list = nil
	end
	
	--remove Custom Profile
	if self.custom and self.custom.panel then
		self._panel:remove(self.custom.panel)
		self._ws:panel():remove(self.custom.filter_list)
		self.custom.panel = nil
		self.custom.filters = {}
	end
end

function ProfileReborn:set_default_profile()
	for idx, profile in pairs(managers.multi_profile._global._profiles) do
		self.profile[idx] = profile
		self:set_profile(self._ui.profile, idx, profile)
	end
end

function ProfileReborn:set_perk_desk_profile()
	if not self.perk_deck then
		self.perk_deck = {}
		
		for idx, profile in pairs(managers.multi_profile._global._profiles) do
			self.perk_deck[profile.perk_deck] = self.perk_deck[profile.perk_deck] or {}
			local perk_deck = self.perk_deck[profile.perk_deck]
			perk_deck[#perk_deck + 1] = {
				idx = idx,
				profile = profile
			}
		end
	end
	
	self.deck_list = self._ws:panel():panel({
		layer = 100,
		w = 50,
		h = self._panel:h()
	})
	
	local deck_list = self.deck_list
	deck_list:set_right(self._panel:left())
	deck_list:set_top(self._panel:top())
	
	deck_list:rect({
		name = "deck_list_rect",
		color = Color.black,
		layer = -2,
		alpha = 0.6,
		w = deck_list:w(),
		h = deck_list:h()
	})
	
	local last_perk
	self.LeftList = {}
	for perk = 1, 30 do if self.perk_deck[perk] then
		local perk_deck = tweak_data.skilltree.specializations[perk]
		if perk_deck then
			local icon_atlas_texture, texture_rect = self:get_specialization_icon(perk_deck[1])
			local last_panel = deck_list:child("perk_icon_" .. tostring(last_perk))
			
			local perk_icon = deck_list:bitmap({
				name = "perk_icon_" .. tostring(perk),
				texture = icon_atlas_texture,
				texture_rect = texture_rect,
				layer = 1,
				y = last_panel and last_panel:bottom() or 0,
				w = deck_list:w(),
				h = deck_list:w()
			})
			
			perk_icon:set_center_x(deck_list:w() / 2)
			last_perk = perk
			
			self.LeftList[#self.LeftList+1] = {
				bitmap = perk_icon,
				id = perk
			}
		end
	end end
	
	-- local selected = deck_list:rect({
		-- visible = true,
		-- w = 5,
		-- h = deck_list:h()
	-- })
	
	local current_profile = managers.multi_profile:current_profile()
	self:switch_perk(current_profile.perk_deck)
end

function ProfileReborn:set_custom_profile()
	self.custom = {}
	self.custom.filters = {}
	self.custom.panel = self._panel:panel({})
	if #self.custom.filters <= 0 then
		local add_filter_icon = self.custom.panel:bitmap({
			texture = "guis/textures/pd2/none_icon",
			rotation = 45,
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
		add_filter_text:set_center(center_x, center_y - 50)
		
		self.custom.first_panel = {
			add_filter_icon,
			add_filter_text
		}
	end
	
	self.custom.filter_list = self._ws:panel():panel({
		layer = 100,
		w = 200,
		h = self._panel:h()
	})
	
	local filter_list = self.custom.filter_list
	filter_list:set_right(self._panel:left())
	filter_list:set_top(self._panel:top())
	
	filter_list:rect({
		namc = "filter_list_rect",
		color = Color.black,
		layer = -2,
		alpha = 0,
		w = filter_list:w(),
		h = filter_list:h()
	})
	
	self.custom.tool_list = self._ws:panel():panel({
		layer = self._ui_layer,
		w = 50,
		h = self._panel:h()
	})
	
	local tool_list = self.custom.tool_list
	
	tool_list:set_left(self._panel:right())
	tool_list:set_top(self._panel:top())

	local tool_icon_add_filter = tool_list:bitmap({
		name = "tool_icon_add_filter",
		texture = "guis/textures/pd2/none_icon",
		rotation = 45,
		layer = 1,
		y = 0,
		w = tool_list:w(),
		h = tool_list:w()
	})
			
	tool_icon_add_filter:set_center_x(tool_list:w() / 2)
end

function ProfileReborn:create_new_filter(name)
	local idx = #self.custom.filters + 1
	self.custom.filters[idx] = {
		name = name or "CustomFilter",
		panel = self:create_filter_ui(name, idx),
		idx = idx,
		profiles = {}
	}
	
	local filters = self.custom.filters
	
	self.custom.current_custom_filter = #filters
	
	filters[idx].panel:child("custom_filter_rect"):set_alpha(0.75)
	
	for cidx, filter in ipairs(filters) do
		if cidx ~= idx then
			filter.panel:child("custom_filter_rect"):set_alpha(0)
		end
	end
end

function ProfileReborn:create_filter_ui(name, idx)
	local last_filter = self.custom.filters[idx-1]
	local filter = self.custom.filter_list:panel({
		y = last_filter and last_filter.panel:bottom() or 0,
		w = self.custom.filter_list:w(),
		h = 30		
	})
	
	local custom_filter = filter:rect({
		name = "custom_filter_rect",
		color = Color(173 / 255,216 / 255,230 / 255),
		layer = 1,
		alpha = 0,
		w = self.custom.filter_list:w(),
		h = 30
	})
	
	custom_filter:set_center_x(self.custom.filter_list:w() / 2)
	
	local custom_filter_text = filter:text({
		vertical = "center",
		valign = "center",
		align = "right",
		halign = "right",
		layer = 2,
		font = tweak_data.hud_players.ammo_font,
		text = name or "CustomFilter#" .. tostring(idx) ,
		font_size = 20
	})	
	
	local center_x = filter:w() / 2
	local center_y = filter:h() / 2
	custom_filter_text:set_center_y(center_y)
	custom_filter_text:set_right(filter:right())
	
	return filter
end

function ProfileReborn:mouse_moved(o, x, y)
	if not self._panel then
		return
	end
	
	self._mouse_x = x
	self._mouse_y = y
	self._mouse_inside = false
	self._touch_profile = false	
	
	if self._panel:inside(self._mouse_x, self._mouse_y) then
		for idx, box in pairs(self._ui.profile) do
			local profile = self._ui.profile[idx]
			if box:inside(self._mouse_x, self._mouse_y) and self._mouse_y > self._panel:y() and self._mouse_y < (self._panel:y() + self._panel:h()) then
				self._mouse_inside = true
				self._touch_profile = box:layer() == 0 and idx or box:layer()
				profile:child("top_line_" .. idx):show()
				profile:child("bottom_line_" .. idx):show()
				profile:child("left_line_" .. idx):show()
				profile:child("right_line_" .. idx):show()
			else
				profile:child("top_line_" .. idx):hide()
				profile:child("bottom_line_" .. idx):hide()
				profile:child("left_line_" .. idx):hide()
				profile:child("right_line_" .. idx):hide()
			end
		end
	end
	
	-- filter arrow
	if self._filter:child("arrow_left"):inside(x, y) or self._filter:child("arrow_right"):inside(x, y) then
		self._mouse_inside = true
	end
	
	-- deck list
	if self.deck_list and self.deck_list:child("deck_list_rect"):inside(x, y) then
		for _, data in ipairs(self.LeftList) do
			if data.bitmap:inside(x, y) then
				self._mouse_inside = true
				break
			end
		end
	end
	
	-- #CustomProfile
	
	-- ##NewFilter
	if self._current_filter == 3 then
		if #self.custom.filters <=0 and self._ui_panel:inside(x, y) then
			self._mouse_inside = true
		end
		
		if self.custom.tool_list:child("tool_icon_add_filter"):inside(x, y) then
			self._mouse_inside = true
		end
		
		-- filterList
		for idx, data in ipairs(self.custom.filters) do
			if data.idx == self.custom.current_custom_filter then
				data.panel:child("custom_filter_rect"):set_alpha(0.75)
			elseif data.panel:inside(x, y) then
				self._mouse_inside = true
				data.panel:child("custom_filter_rect"):set_alpha(0.5)
			else
				data.panel:child("custom_filter_rect"):set_alpha(0)
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
	if self._rect:inside(x, y) then
		if button == Idstring("mouse wheel down") then
			self:wheel_scroll_bd(-30)
		elseif button == Idstring("mouse wheel up") then
			self:wheel_scroll_bd(30)
		end
	end
	
	if button == Idstring("mouse wheel down") then
		if self._rect:inside(x, y) then
			self:wheel_scroll_bd(-30)
		end
		
		if self.deck_list and self.deck_list:inside(x, y) then
			self:wheel_scroll_perk(-self.deck_list:w())
		end
	elseif button == Idstring("mouse wheel up") then
		if self._rect:inside(x, y) then
			self:wheel_scroll_bd(30)
		end
		
		if self.deck_list and self.deck_list:inside(x, y) then
			self:wheel_scroll_perk(self.deck_list:w())
		end
	end
	
	if button == Idstring("0") then
		if self._touch_profile then
			managers.multi_profile:set_current_profile(self._touch_profile)
			self:hide()
		elseif self._filter:child("arrow_left"):inside(x, y) then		
			self:switch_filter(self._current_filter - 1)
		elseif self._filter:child("arrow_right"):inside(x, y) then
			self:switch_filter(self._current_filter + 1)
		end
		
		if self.deck_list and self.deck_list:child("deck_list_rect"):inside(x, y) then
			for _, data in ipairs(self.LeftList) do
				if data.bitmap:inside(x, y) then
					self:switch_perk(data.id)
					break
				end
			end
		end

		-- #CustomProfile
		
		if self._current_filter == 3 then
			--##NewCustom
			if #self.custom.filters <=0 and self._ui_panel:inside(x, y) then
				self:create_new_filter()
				managers.mouse_pointer:set_pointer_image("arrow")
				
				for _, panel in ipairs(self.custom.first_panel) do
					self.custom.panel:remove(panel)
				end
			end
			
			if self.custom.tool_list:child("tool_icon_add_filter"):inside(x, y) then
				self:create_new_filter()
				managers.mouse_pointer:set_pointer_image("arrow")			
			end
			
			--##SetCustom
			for idx, filter in ipairs(self.custom.filters) do
				if filter.panel:inside(x, y) then
					self.custom.filters[self.custom.current_custom_filter].panel:child("custom_filter_rect"):set_alpha(0)
					filter.panel:child("custom_filter_rect"):set_alpha(0.75)
					self.custom.current_custom_filter = idx
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
end

function ProfileReborn:key_release(o, k)
	if k == Idstring("esc") then
		if self._panel:visible() then
			self:hide()
		end
	end
end

function ProfileReborn:switch_filter(value)
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
		self:set_custom_profile()
	end
	
	if self._bg_h * #self._ui.profile >= self._panel:h() then
		local current_ui
		if self._current_filter ~= 1 then
			for idx, ui in ipairs(self._ui.profile) do
				if ui:layer() == managers.multi_profile._global._current_profile then
					current_ui = idx
					break
				end
			end
		else
			current_ui = managers.multi_profile._global._current_profile
		end

		if self._ui.profile[current_ui]:y() > (self._panel:h() / 2 - self._bg_h / 2) then
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
	local profile = self.perk_deck[perk]
	if profile then
		self:reset_panel()
	
		for i = 1, #profile do
			self.profile[i] = profile[i]
			self:set_profile(self._ui.profile, i, profile[i].profile, profile[i].idx)
		end
		
		for _, data in ipairs(self.LeftList) do
			data.bitmap:set_color(Color.white)
		end
		
		self.deck_list:child("perk_icon_" .. perk):set_color(Color(88 / 255, 87 / 255, 86 / 255))
	end
end

function ProfileReborn:wheel_scroll_bd(dy)
	local profiles = self._ui.profile
	
	if self._bg_h * #profiles >= self._panel:h() then
		if dy > 0 then
			dy = profiles[1]:top() >= 0 and -profiles[1]:top() or dy
		else
			if profiles[#profiles]:bottom() <= self._panel:h() then
				dy = self._panel:h() - profiles[#profiles]:bottom()
			end
		end
		
		for idx, panel in ipairs(profiles) do
			panel:set_y(panel:top() + dy)
		end
	end
end

function ProfileReborn:wheel_scroll_perk(dy)
	if self.deck_list:w() * #self.LeftList >= self.deck_list:h() then
		local minimum_perk
		local last_perk
		for _, child in ipairs(self.LeftList) do
			minimum_perk = self.LeftList[1].bitmap
			break
		end
		
		for _, child in ipairs(self.LeftList) do
			last_perk = self.LeftList[#self.LeftList].bitmap
			break
		end
		
		if dy > 0 then
			if minimum_perk:y() >= 0 then
				dy = -minimum_perk:y()
			end
		else
			if last_perk:bottom() <= self._panel:h() then
				dy = self.deck_list:h() - last_perk:bottom()
			end			
		end
		
		for _, data in ipairs(self.LeftList) do
			data.bitmap:set_y(data.bitmap:y() + dy)
		end
	end
end

-- GETING

function ProfileReborn:get_specialization_icon(item)
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
	
	return icon_atlas_texture, texture_rect
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