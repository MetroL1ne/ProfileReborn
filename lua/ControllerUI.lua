-- 触发按钮Lib
PRebornButton = PRebornButton or class()

function PRebornButton:init(panel, data)
	self.class = "button"
	self._panel = panel:panel(data)
	self._parent = panel

	self._can_press = not (tostring(data.can_press) == "false") and true or false
	self._bg = not (tostring(data.can_press) == "false") and data.selection_mode == 1 or false
	self._selection_mode = data.selection_mode or 1

	local rect = self._panel:rect({
		name = "rect",
		visible = false,
		w = self._panel:w(),
		h = self._panel:h(),
		layer = -1,
		color = Color.black,
		alpha = 0.7
	})

	local text = self._panel:text({
		name = "text",
		color = data.text_color or Color.white,
		vertical = "center",
		valign = "left",
		align = "left",
		halign = "center",
		font = tweak_data.hud_players.ammo_font,
		text = data.text,
		font_size = data.font_size and size.font_size or 20
	})

	text:set_left(self._panel:left())
	text:set_center_y(self._panel:h() / 2)

	if data.selection_mode == 4 then
		self._side = {}

		self._side[1] = BoxGuiObject:_create_side(self._panel, "left", 1, false, false)
		self._side[2] = BoxGuiObject:_create_side(self._panel, "right", 1, false, false)
		self._side[3] = BoxGuiObject:_create_side(self._panel, "top", 1, false, false)
		self._side[4] = BoxGuiObject:_create_side(self._panel, "bottom", 1, false, false)
	elseif data.selection_mode == 5 then
		self._line = {}

		self._line[1] = self._panel:rect({
			visible = false,
			w = self._panel:w(),
			h = 2
		})
		
		self._line[2] = self._panel:rect({
			visible = false,
			w = self._panel:w(),
			h = 2
		})
		
		self._line[3] = self._panel:rect({
			visible = false,
			w = 2,
			h = self._panel:h()
		})
		
		self._line[4] = self._panel:rect({
			visible = false,
			w = 2,
			h = self._panel:h()
		})
			
		self._line[1]:set_top(0)
		self._line[2]:set_bottom(self._panel:h())
		self._line[3]:set_left(0)
		self._line[4]:set_right(self._panel:w())
	end

	self._callback = data.callback
end

function PRebornButton:panel()
	return self._panel
end

function PRebornButton:parent()
	return self._parent
end

function PRebornButton:destroy()
	self:parent():remove(self._panel)
end

function PRebornButton:callback()
	return self._callback
end

function PRebornButton:set_callback(clbk)
	self._callback = clbk
end

function PRebornButton:mouse_moved(o, x, y)
	if not self._can_press then
		return false
	end

	local mouse_inside = false
	if self._selection_mode == 1 or self._bg then
		if self:inside(x, y) then
			if self._bg then
				self._panel:child("rect"):set_visible(true)
			end

			if self._selection_mode == 1 then
				mouse_inside = true
			end
		else
			if self._bg then
				self._panel:child("rect"):set_visible(false)
			end
		end
	end

	if self._selection_mode == 2 then
		if self:inside(x, y) then
			self._panel:set_alpha(1)
		else
			self._panel:set_alpha(0.5)
		end
	elseif self._selection_mode == 3 then
		if self:inside(x, y) then
			self._panel:set_alpha(0.5)
		else
			self._panel:set_alpha(1)
		end
	elseif self._selection_mode == 4 then
		for _ , side_panel in pairs(self._side) do
			if self:inside(x, y) then
				managers.mission._fading_debug_output:script().log(tostring(true), Color.white)
				side_panel:set_visible(true)
			else
				side_panel:set_visible(false)
			end
		end
	elseif self._selection_mode == 5 then
		for _ , line_panel in pairs(self._line) do
			if self:inside(x, y) then
				line_panel:set_visible(true)
			else
				line_panel:set_visible(false)
			end
		end
	end

	return mouse_inside
end

function PRebornButton:mouse_pressed(button, x, y)
	if button == Idstring("0") then
		if self:inside(x, y) then
			if self:callback() then
				self:callback()()
			end
		end
	end
end

function PRebornButton:mouse_released(button, x, y)
end

function PRebornButton:inside(x, y)
	if self._panel:visible() and self._panel:inside(x, y) then
		return true, "link"
	end

	return false, "arrow"
end

-- 切换按钮Lib
PRebornToggleButton = PRebornToggleButton or class()

function PRebornToggleButton:init(panel, data)
	self.class = "toggle"
	self._parent = panel
	self._state = data.state or false

	self._panel = panel:panel(data)

	local rect = self._panel:rect({
		name = "rect",
		visible = false,
		w = self._panel:w(),
		h = self._panel:h(),
		layer = -1,
		color = Color.black,
		alpha = 0.7
	})

	local tickbox_toggle = self._panel:bitmap({
		name = "tickbox_toggle",
		color = data.box_color or Color.white,
		texture = "guis/textures/menu_tickbox",
		texture_rect = {
			self._state and 24 or 0,
			0,
			24,
			24
		},
		w = data.box_size,
		h = data.box_size
	})

	tickbox_toggle:set_right(self._panel:right() - 4)
	tickbox_toggle:set_center_y(self._panel:h() / 2)

	local tickbox_text = self._panel:text({
		name = "tickbox_text",
		color = data.text_color or Color.white,
		vertical = "center",
		valign = "left",
		align = "left",
		halign = "center",
		font = tweak_data.hud_players.ammo_font,
		text = data.text,
		font_size = data.font_size and size.font_size or 20
	})

	tickbox_text:set_left(self._panel:left())
	tickbox_text:set_center_y(self._panel:h() / 2)

	self._callback = data.callback
end

function PRebornToggleButton:panel()
	return self._panel
end

function PRebornToggleButton:parent()
	return self._parent
end

function PRebornToggleButton:destroy()
	self:parent():remove(self._panel)
end

function PRebornToggleButton:callback()
	return self._callback
end

function PRebornToggleButton:set_callback(clbk)
	self._callback = clbk
end

function PRebornToggleButton:mouse_moved(o, x, y)
	local mouse_inside = false

	if self:inside(x, y) then
		self._panel:child("rect"):set_visible(true)
		mouse_inside = true
	else
		self._panel:child("rect"):set_visible(false)
	end

	return mouse_inside
end

function PRebornToggleButton:mouse_pressed(button, x, y)
	if button == Idstring("0") then
		if self:inside(x, y) then
			if self:callback() then
				self:callback()(self:toggle())
			end
		end
	end
end

function PRebornToggleButton:mouse_released(button, x, y)
end

function PRebornToggleButton:inside(x, y)
	if self._panel:inside(x, y) then
		return true, "link"
	end

	return false, "arrow"
end

function PRebornToggleButton:toggle()
	local new_state = not self._state
	self:set_state(new_state)

	return new_state
end

function PRebornToggleButton:set_state(state)
	self._state = state
	local box = self._panel:child("tickbox_toggle")

	box:set_texture_rect(
		state and 24 or 0,
		0,
		24,
		24
	)
end

-- 输入框Lib
PRebornInputBox = PRebornInputBox or class()

function PRebornInputBox:init(panel, ws, data)
	self.class = "input"
	self._ws = ws
	self._parent = panel
	self._max_length = data.max_length or 100
	self._num_only = data.num_only

	self._panel = panel:panel(data)

	self._name_text = self._panel:text({
		name = "name_text",
		vertical = "center",
		valign = "right",
		align = "right",
		halign = "center",
		text = data.text,
		alpha = 0.7,
		font = data.font or tweak_data.hud_players.ammo_font,
		font_size = data.font_size and size.font_size or 20,
		color = data.text_color
	})

	self._name_text:set_right(self._panel:right() - 5)
	self._name_text:set_center_y(self._panel:center_y())

	self._input_text = self._panel:text({
		name = "name_text",
		vertical = "center",
		valign = "left",
		align = "left",
		halign = "center",
		text = data.value,
		font = data.font or tweak_data.hud_players.ammo_font,
		font_size = data.font_size and size.font_size or 20,
		color = data.input_text_color
	})

	self._input_text:set_left(self._panel:left())
	self._input_text:set_center_y(self._panel:center_y())

	local bottom_line = self._panel:rect({
		name = "bottom_line",
		vertical = "center",
		align = "center",
		color = data.line_color,
		w = self._panel:w(),
		h = 1
	})

	bottom_line:set_bottom(self._panel:bottom())

	self._caret = self._panel:rect({
		name = "caret",
		w = 0,
		h = 0,
		x = 0,
		y = 0,
		layer = 2,
		color = Color(1, 1, 1, 1)
	})

	self._callback = data.callback
end

function PRebornInputBox:panel()
	return self._panel
end

function PRebornInputBox:parent()
	return self._parent
end

function PRebornInputBox:destroy()
	self:parent():remove(self._panel)
end

function PRebornInputBox:mouse_moved(o, x, y)
	local mouse_inside = false

	if self:inside(x, y) then
		mouse_inside = true
	end

	return mouse_inside
end

function PRebornInputBox:mouse_pressed(button, x, y)
	if button == Idstring("0") then
		if self:inside(x, y) then
			self:set_editing(true)
			self:click()
		elseif self._editing then
			self:set_editing(false)
		end
	end
end

function PRebornInputBox:mouse_released(button, x, y)
end

function PRebornInputBox:key_press(o, k)
	if self._editing then
		self:handle_key(k, true)
	end
end

function PRebornInputBox:key_release(o, k)
	if self._editing then
		self:handle_key(k, false)
	end
end


function PRebornInputBox:inside(x, y)
	if self._panel:inside(x, y) then
		return true, "link"
	end

	return false, "arrow"
end

function PRebornInputBox:enter()
	self:enter_callback()()
end

function PRebornInputBox:enter_callback()
	return self._enter_callback
end

function PRebornInputBox:set_enter_callback(callback)
	self._enter_callback = callback
end

function PRebornInputBox:click()
	if self:click_callback() then
		self:click_callback()()
	end
end

function PRebornInputBox:click_callback()
	return self._click_callback
end

function PRebornInputBox:set_click_callback(callback)
	self._click_callback = callback
end

function PRebornInputBox:clickout()
	if self:clickout_callback() then
		self:clickout_callback()(self._num_only and tonumber(self._input_text:text()) or self._input_text:text())
	end
end

function PRebornInputBox:clickout_callback()
	return self._clickout_callback
end

function PRebornInputBox:set_clickout_callback(callback)
	self._clickout_callback = callback
end

function PRebornInputBox:editing()
	return self._editing
end

function PRebornInputBox:connect_search_input()
	self._ws:connect_keyboard(Input:keyboard())

	if _G.IS_VR then
		Input:keyboard():show_with_text(self._input_text:text())
	end

	self._panel:key_press(callback(self, self, "key_press"))
	self._panel:key_release(callback(self, self, "key_release"))

	self:update_caret()
	managers.menu_component:post_event("menu_enter")
end

function PRebornInputBox:disconnect_search_input()
	self._ws:disconnect_keyboard()
	self._panel:key_press(nil)
	self._panel:key_release(nil)

	self:update_caret()
	managers.menu_component:post_event("menu_exit")

	if self._disconnect_callback then
		self._disconnect_callback(self._input_text:text())
	end
end

function PRebornInputBox:update_caret()
	local text = self._input_text
	local caret = self._caret
	local s, e = text:selection()
	local x, y, w, h = text:selection_rect()
	local text_s = text:text()

	if #text_s == 0 then
		x = text:world_x()
		y = text:world_y()
	end

	h = text:h()

	if w < 3 then
		w = 3
	end

	if not self._editing then
		w = 0
		h = 0
	end

	caret:set_world_shape(x, y + 2, w, h - 4)
	self:set_blinking(s == e and self._editing)
end

function PRebornInputBox.blink(o)
	while true do
		o:set_color(Color(0, 1, 1, 1))
		wait(0.3)
		o:set_color(Color.white)
		wait(0.3)
	end
end

function PRebornInputBox:set_blinking(b)
	local caret = self._caret

	if b == self._blinking then
		return
	end

	if b then
		caret:animate(self.blink)
	else
		caret:stop()
	end

	self._blinking = b

	if not self._blinking then
		caret:set_color(Color.white)
	end
end

function PRebornInputBox:start_input()
	self:trigger()
end

function PRebornInputBox:trigger()
	if not self._editing then
		self:set_editing(true)
	else
		self:set_editing(false)
	end
end

function PRebornInputBox:set_editing(editing)
	self._editing = editing

	if editing then
		self:connect_search_input()

		self._panel:enter_text(callback(self, self, "enter_text"))

		local n = utf8.len(self._input_text:text())

		self._input_text:set_selection(n, n)

		if _G.IS_VR then
			Input:keyboard():show_with_text(self._input_text:text(), self._max_length)
		end

		self._org_text = self._input_text:text()
		self:update_caret()
	else
		if self._num_only and not tonumber(self._input_text:text()) then
			self._input_text:set_text(self._org_text)
		end

		self._panel:enter_text(nil)
		self:disconnect_search_input()
		self:clickout()
	end
end

function PRebornInputBox:enter_text(o, s)
	if not self._editing then
		return
	end

	if self._num_only and not tonumber(s) and not tonumber("0"..s.."1") then
		s = ""
	end

	if _G.IS_VR then
		self._input_text:set_text(s)
	else
		local s_len = utf8.len(self._input_text:text())
		s = utf8.sub(s, 1, self._max_length - s_len)

		self._input_text:replace_text(s)
	end

	self:update_caret()
end

function PRebornInputBox:handle_key(k, pressed)
	local text = self._input_text
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
		self:trigger()
	elseif k == Idstring("esc") then
		text:set_text(self._org_text)
		self:set_editing(false)
	end

	self:update_caret()
end

PRebornScrollList = PRebornScrollList or class(ScrollItemList)

function PRebornScrollList:init(panel, data, canvas_config, ...)
	PRebornScrollList.super.init(self, panel, data, canvas_config, ...)
	
	self.class = "list"
	self._panel = self._panel
	self._parent = panel
	self._h = data.h or panel:h() / 2
	self._dy = data.dy or 1

	if data.items then
		for _, item in ipairs(data.items) do
			self:add_item(item)
		end
	end

	local title = self:canvas():text({
		name = "title",
		color = Color.white,
		vertical = "top",
		valign = "right",
		align = "right",
		halign = "top",
		font = tweak_data.hud_players.ammo_font,
		text = data.title or "",
		alpha = 0.6,
		font_size = data.title_font_size or 50
	})

	title:set_right(self:canvas():w())
	title:set_top(self:canvas():top())

	self._callback = data.callback
end

function PRebornScrollList:panel()
	return self._panel
end

function PRebornScrollList:parent()
	return self._parent
end

function PRebornScrollList:destroy()
	self:parent():remove(self._panel)
end

function PRebornScrollList:mouse_pressed(button, x, y)
	if button == Idstring("mouse wheel up") then
		return self:mouse_wheel_up(x, y)
	elseif button == Idstring("mouse wheel down") then
		return self:mouse_wheel_down(x, y)
	end

	self.super.mouse_pressed(self, button, x, y)
end

function PRebornScrollList:mouse_wheel_up(x, y)
	if not alive(self._scroll) then
		return
	end

	self._scroll:scroll(x, y, self._dy)

	if not self._scroll:panel():inside(x, y) then
		return
	end

	return PRebornScrollList.super.super.super.mouse_wheel_up(self, x, y)
end

function PRebornScrollList:mouse_wheel_down(x, y)
	if not alive(self._scroll) then
		return
	end

	self._scroll:scroll(x, y, -self._dy)

	if not self._scroll:panel():inside(x, y) then
		return
	end

	return PRebornScrollList.super.super.super.mouse_wheel_down(self, x, y)
end

PRebornScrollListSimple = PRebornScrollListSimple or class()

function PRebornScrollListSimple:init(panel, data)
	self._parent = panel
	self._panel = panel:panel(data)
	self._data = data

	self._dy = data.dy or 1

	self._current_items = {}
	self._all_items = {}

	self._selection = data.selection
	self._selection_mode = data.selection_mode or 1
	self._rects = {}

	self._canvas = self._panel:panel({
		w = self._panel:w(),
		h = 0
	})

	self._callback = data.callback
end

function PRebornScrollListSimple:panel()
	return self._panel
end

function PRebornScrollListSimple:canvas()
	return self._canvas
end

function PRebornScrollListSimple:add_item(item, force_visible, at_index, selected)
	if force_visible ~= nil then
		item:set_visible(force_visible)
	end

	if item:visible() then
		if at_index then
			self._current_items[at_index] = item
		else
			table.insert(self._current_items, item)
		end

		local item_key = at_index or #self._current_items

		self._canvas:set_size(self._panel:w(), self._canvas:h() + item:h())

		item:set_y(self._canvas:h() - item:h())

		self._selected = selected and item_key or self._selected

		if self._selection_mode == 1 then
			self._rects[item_key] = item:parent():rect({
				visible = selected == true and true or false,
				color = self._data.rect_color,
				alpha = 0.8,
				w = item:w(),
				h = item:h()
			})

			self._rects[item_key]:set_center(item:center_x(), item:center_y())
		elseif self._selection_mode == 2 then
			if selected then
				item:set_alpha(0.5)
			end
		end

	end

	table.insert(self._all_items, item)

	return item
end

function PRebornScrollListSimple:set_selected_solo(key)
	for k, item in pairs(self._current_items) do
		if k == key then
			self:set_selected(k)
		else
			self:set_unselected(k)
		end
	end
end

function PRebornScrollListSimple:set_selected(key)
	self._selected = key

	if self._selection_mode == 1 then
		self._rects[key]:set_visible(true)
	elseif self._selection_mode == 2 then
		self._current_items[key]:set_alpha(0.5)
	end
end

function PRebornScrollListSimple:set_unselected(key)
	if self._selection_mode == 1 then
		self._rects[key]:set_visible(false)
	elseif self._selection_mode == 2 then
		self._current_items[key]:set_alpha(1)
	end
end

function PRebornScrollListSimple:items()
	return self._current_items
end

function PRebornScrollListSimple:all_items()
	return self._all_items
end

function PRebornScrollListSimple:perform_scroll(speed, direction)
	if self:canvas():h() <= self:panel():h() then
		return
	end

	local scroll_amount = speed * (direction or 1)
	local max_h = self:canvas():h() - self:panel():h()
	max_h = max_h * -1
	local new_y = math.clamp(self:canvas():y() + scroll_amount, max_h, 0)

	self:canvas():set_y(new_y)
end

function PRebornScrollListSimple:scroll(x, y, dy)
	if self:panel():inside(x, y) then
		self:perform_scroll(dy, 1)

		return true
	end
end

function PRebornScrollListSimple:set_callback(callback)
	self._callback = callback
end

function PRebornScrollListSimple:callback()
	return self._callback
end

function PRebornScrollListSimple:mouse_moved(o, x, y)
	if not self._panel:visible() or not self._canvas:visible() then
		return false
	end
	
	if not self._canvas:inside(x, y) then
		return false
	end

	local mouse_inside = false

	for k, item in pairs(self._current_items) do
		if item:inside(x, y) and k ~= self._selected then
			mouse_inside = true
			
			break
		end
	end

	return mouse_inside
end

function PRebornScrollListSimple:mouse_pressed(button, x, y)
	if not self._panel:visible() or not self._canvas:visible() then
		return
	end

	if not self._panel:inside(x, y) then
		return
	end

	if button == Idstring("0") then
		if self._selection then
			for k, item in pairs(self._current_items) do
				if item:inside(x, y) then
					self:set_selected(k)

					if self:callback() then
						self:callback()(k)
					end
				else
					self:set_unselected(k)
				end
			end
		end
	elseif button == Idstring("mouse wheel up") then
		return self:mouse_wheel_up(x, y)
	elseif button == Idstring("mouse wheel down") then
		return self:mouse_wheel_down(x, y)
	end
end

function PRebornScrollListSimple:mouse_wheel_up(x, y)
	self:scroll(x, y, self._dy)
end

function PRebornScrollListSimple:mouse_wheel_down(x, y)
	self:scroll(x, y, -self._dy)
end

function PRebornScrollListSimple:mouse_released(button, x, y)
end
