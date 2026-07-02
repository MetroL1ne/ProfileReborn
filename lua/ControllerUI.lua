-- 触发按钮Lib
PRebornButton = PRebornButton or class()

function PRebornButton:init(panel, data)
	self.class = "button"
	data.alpha = data.selection_mode == 2 and (data.min_alpha or 0.5) or data.alpha
	self._panel = panel:panel(data)
	self._parent = panel
	self._data = data

	self._active = not (tostring(data.active) == "false") and true or false
	self._selection_mode = data.selection_mode or 1

	if self._selection_mode == 1 then
		self._bg = not (tostring(data.bg) == "false") and true or false
	else
		self._bg = data.bg
	end

	local rect = self._panel:rect({
		name = "rect",
		visible = (self._selection_mode == 1 and not self._active) and self._bg,
		w = self._panel:w(),
		h = self._panel:h(),
		color = data.bg_color or Color.black,
		alpha = data.bg_alpha or 0.7,
		layer = (data.bg_layer and data.bg_layer or 1) - (self._active and 0 or 2)
	})

	local text = self._panel:text({
		name = "text",
		color = data.text_color or Color.white,
		vertical = data.text_vertical or "center",
		valign = data.text_valign or "left",
		align = data.text_align or "left",
		halign = data.text_halign or "center",
		font = tweak_data.hud_players.ammo_font,
		text = data.text,
		font_size = data.font_size or 20
	})

	text:set_left(self._panel:left())
	text:set_center_y(self._panel:h() / 2)

	if data.selection_mode == 4 then
		self._side = {}

		self._side[1] = PRebornBoxGuiObject:_create_side(self._panel, "left", 1, false, false)
		self._side[2] = PRebornBoxGuiObject:_create_side(self._panel, "right", 1, false, false)
		self._side[3] = PRebornBoxGuiObject:_create_side(self._panel, "top", 1, false, false)
		self._side[4] = PRebornBoxGuiObject:_create_side(self._panel, "bottom", 1, false, false)
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
	self._right_callback = data.right_callback
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


function PRebornButton:right_callback()
	return self._right_callback
end

function PRebornButton:set_right_callback(clbk)
	self._right_callback = clbk
end

function PRebornButton:set_active(state)
	self._active = state
end

function PRebornButton:active()
	return self._active
end

function PRebornButton:mouse_moved(o, x, y)
	local mouse_inside = self:inside(x, y)

	if not self._panel:visible() or not self._active then
		return false
	end

	if self._selection_mode == 1 or self._bg then
		if mouse_inside then
			if self._bg then
				self._panel:child("rect"):set_visible(true)
			end

			if self._active and self._selection_mode == 1 then
				mouse_inside = true
			end
		else
			if self._bg then
				self._panel:child("rect"):set_visible(false)
			end
		end
	end

	if self._selection_mode == 2 then
		if mouse_inside then
			self._panel:set_alpha(self._data.max_align or 1)
		else
			self._panel:set_alpha(self._data.min_alpha or 0.5)
		end
	elseif self._selection_mode == 3 then
		if mouse_inside then
			self._panel:set_alpha(self._data.min_alpha or 0.5)
		else
			self._panel:set_alpha(self._data.max_align or 1)
		end
	elseif self._selection_mode == 4 then
		for _ , side_panel in pairs(self._side) do
			if mouse_inside then
				side_panel:set_visible(true)
			else
				side_panel:set_visible(false)
			end
		end
	elseif self._selection_mode == 5 then
		for _ , line_panel in pairs(self._line) do
			if mouse_inside then
				line_panel:set_visible(true)
			else
				line_panel:set_visible(false)
			end
		end
	end

	return mouse_inside
end

function PRebornButton:mouse_pressed(button, x, y)
	if not self._active then
		return false
	end
	
	if self:inside(x, y) then
		if button == Idstring("0") then
			if self:callback() then
				self:callback()()
			end
		elseif button == Idstring("1") then
			if self:right_callback() then
				self:right_callback()()

				return true
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
PRebornToggle = PRebornToggle or class()

function PRebornToggle:init(panel, data)
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
		font_size = data.font_size or 20
	})

	tickbox_text:set_left(self._panel:left())
	tickbox_text:set_center_y(self._panel:h() / 2)

	self._callback = data.callback
end

function PRebornToggle:panel()
	return self._panel
end

function PRebornToggle:parent()
	return self._parent
end

function PRebornToggle:destroy()
	self:parent():remove(self._panel)
end

function PRebornToggle:callback()
	return self._callback
end

function PRebornToggle:set_callback(clbk)
	self._callback = clbk
end

function PRebornToggle:mouse_moved(o, x, y)
	local mouse_inside = false

	if self:inside(x, y) then
		self._panel:child("rect"):set_visible(true)
		mouse_inside = true
	else
		self._panel:child("rect"):set_visible(false)
	end

	return mouse_inside
end

function PRebornToggle:mouse_pressed(button, x, y)
	if button == Idstring("0") then
		if self:inside(x, y) then
			if self:callback() then
				self:callback()(self:toggle())
			end
		end
	end
end

function PRebornToggle:mouse_released(button, x, y)
end

function PRebornToggle:inside(x, y)
	if self._panel:inside(x, y) then
		return true, "link"
	end

	return false, "arrow"
end

function PRebornToggle:toggle()
	local new_state = not self._state
	self:set_state(new_state)

	return new_state
end

function PRebornToggle:set_state(state)
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

function PRebornInputBox:init(panel, data, ws)
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
		font_size = data.font_size or 20,
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
		font_size = data.font_size or 20,
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

	self._click_callback = data.click_callback
	self._enter_callback = data.enter_callback
	self._clickout_callback = data.clickout_callback
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

PRebornVerticalScrollItemList = PRebornVerticalScrollItemList or class(ScrollItemList)

function PRebornVerticalScrollItemList:init(panel, data, canvas_config, ...)
	PRebornVerticalScrollItemList.super.init(self, panel, data, canvas_config, ...)
	
	self.class = "vertical_list"
	self._panel = self._panel
	self._parent = panel
	self._data = data
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

	-- Style Change

	local scroll_bar = self._scroll:panel():child("scroll_bar")
	local scroll_bar_BoxGuiObject0 = scroll_bar:child("scroll_bar_inside_panel")

	if not scroll_bar_BoxGuiObject0 then
		scroll_bar_BoxGuiObject0 = scroll_bar:child("BoxGuiObject0")
	end

	if not scroll_bar_BoxGuiObject0 then
		return
	end

	for k, panel in ipairs(scroll_bar_BoxGuiObject0:children()) do
		panel:set_visible(false)
	end

	local canvas_bg = scroll_bar_BoxGuiObject0:rect({
		color = data.main_color,
		alpha = 1,
		w = scroll_bar_BoxGuiObject0:w(),
		h = scroll_bar_BoxGuiObject0:h()
	})

	self:panel():set_w(self:canvas():w() + scroll_bar:w() + 3)

	scroll_bar:set_left(self:canvas():right())
	self._scroll:panel():child("scroll_up_indicator_arrow"):set_center_x(scroll_bar:center_x())
	self._scroll:panel():child("scroll_down_indicator_arrow"):set_center_x(scroll_bar:center_x())

	-- local widget_panel = nil

	-- self._child_classes = {}
	-- for _, widget in ipairs(data.widgets or {}) do
	-- 	if widget.type then
	-- 		local widget_class = rawget(_G, widget.type):new(self:canvas(), widget, unpack(widget.params or {}))
	-- 		widget_panel = widget_class:panel()
	-- 		self._child_classes[#self._child_classes + 1] = widget_class
	-- 	else
	-- 		widget_panel = self:canvas():panel(widget)
	-- 	end

	-- 	widget_panel:set_w(widget.w or self:canvas():w())
	-- 	widget_panel:set_h(widget.h or self:canvas():h())

	-- 	self:add_item(widget_panel)
	-- end
end

function PRebornVerticalScrollItemList:panel()
	return self._panel
end

function PRebornVerticalScrollItemList:parent()
	return self._parent
end

function PRebornVerticalScrollItemList:destroy()
	self:parent():remove(self._panel)
end

-- function PRebornVerticalScrollItemList:mouse_moved(o, x, y)
-- 	if not self._panel:visible() then
-- 		return false
-- 	end

-- 	local mouse_inside = PRebornVerticalScrollItemList.super.mouse_moved(o, x, y)

-- 	for _, class in ipairs(self._child_classes) do
-- 		mouse_inside = class:mouse_moved(o, x, y) or mouse_inside
-- 	end

-- 	return mouse_inside
-- end

function PRebornVerticalScrollItemList:mouse_pressed(button, x, y)
	if not self._panel:visible() then
		return
	end

	-- for _, class in ipairs(self._child_classes) do
	-- 	class:mouse_pressed(button, x, y)
	-- end

	if button == Idstring("mouse wheel up") then
		return self:mouse_wheel_up(x, y)
	elseif button == Idstring("mouse wheel down") then
		return self:mouse_wheel_down(x, y)
	end

	self.super.mouse_pressed(self, button, x, y)
end

function PRebornVerticalScrollItemList:mouse_wheel_up(x, y)
	if not alive(self._scroll) then
		return
	end

	self._scroll:scroll(x, y, self._dy)

	if not self._scroll:panel():inside(x, y) then
		return
	end

	return PRebornVerticalScrollItemList.super.super.super.mouse_wheel_up(self, x, y)
end

function PRebornVerticalScrollItemList:mouse_wheel_down(x, y)
	if not alive(self._scroll) then
		return
	end

	self._scroll:scroll(x, y, -self._dy)

	if not self._scroll:panel():inside(x, y) then
		return
	end

	return PRebornVerticalScrollItemList.super.super.super.mouse_wheel_down(self, x, y)
end

function PRebornVerticalScrollItemList:add_lines_and_static_down_indicator(layer)
	local box = PRebornBoxGuiObject:new(self:scroll_item():scroll_panel(), {
		w = self:canvas():w(),
		sides = {
			1,
			1,
			2,
			0
		},
		layer = layer,
		color = self._data.main_color
	})
	local down_no_scroll = PRebornBoxGuiObject:new(box._panel, {
		sides = {
			0,
			0,
			0,
			1
		},
		layer = layer,
		color = self._data.main_color
	})
	local down_scroll = PRebornBoxGuiObject:new(box._panel, {
		sides = {
			0,
			0,
			0,
			2
		},
		layer = layer,
		color = self._data.main_color
	})

	local function update_down_indicator()
		local indicate = self:scroll_item()._scroll_bar:visible()

		down_no_scroll:set_visible(not indicate)
		down_scroll:set_visible(indicate)
	end

	update_down_indicator()

	self._scroll.on_canvas_resized = update_down_indicator
end

function PRebornVerticalScrollItemList:swap_item_by_index(item_1, item_2)
	local item_1_x, item_1_y = self._current_items[item_1]:position()
	self._current_items[item_1]:set_position(self._current_items[item_2]:position())
	self._current_items[item_2]:set_position(item_1_x, item_1_y)

	self._current_items[item_1], self._current_items[item_2] = self._current_items[item_2], self._current_items[item_1]
end

PRebornHorizontalScrollItemList = PRebornHorizontalScrollItemList or class(HorizontalScrollItemList)

function PRebornHorizontalScrollItemList:init(panel, data, canvas_config, ...)
	PRebornVerticalScrollItemList.super.init(self, panel, data, canvas_config, ...)
	
	self.class = "horizontal_list"
	self._panel = self._panel
	self._parent = panel
	self._data = data
	self._h = data.h or panel:h() / 2
	self._dy = data.dy or 1

	if data.items then
		for _, item in ipairs(data.items) do
			self:add_item(item)
		end
	end

	-- local title = self:canvas():text({
	-- 	name = "title",
	-- 	color = Color.white,
	-- 	vertical = "top",
	-- 	valign = "right",
	-- 	align = "right",
	-- 	halign = "top",
	-- 	font = tweak_data.hud_players.ammo_font,
	-- 	text = data.title or "",
	-- 	alpha = 0.6,
	-- 	font_size = data.title_font_size or 50
	-- })

	-- title:set_right(self:canvas():w())
	-- title:set_top(self:canvas():top())

	-- Style Change

	-- local scroll_bar = self._scroll:panel():child("scroll_bar")
	-- local scroll_bar_BoxGuiObject0 = scroll_bar:child("scroll_bar_inside_panel")

	-- if not scroll_bar_BoxGuiObject0 then
	-- 	scroll_bar_BoxGuiObject0 = scroll_bar:child("BoxGuiObject0")
	-- end

	-- if not scroll_bar_BoxGuiObject0 then
	-- 	return
	-- end

	-- for k, panel in ipairs(scroll_bar_BoxGuiObject0:children()) do
	-- 	panel:set_visible(false)
	-- end

	-- local canvas_bg = scroll_bar_BoxGuiObject0:rect({
	-- 	color = data.main_color,
	-- 	alpha = 1,
	-- 	w = scroll_bar_BoxGuiObject0:w(),
	-- 	h = scroll_bar_BoxGuiObject0:h()
	-- })

	-- self:panel():set_w(self:canvas():w() + scroll_bar:w() + 3) 

	-- scroll_bar:set_left(self:canvas():right())
	-- self._scroll:panel():child("scroll_up_indicator_arrow"):set_center_x(scroll_bar:center_x())
	-- self._scroll:panel():child("scroll_down_indicator_arrow"):set_center_x(scroll_bar:center_x())

	-- local widget_panel = nil

	-- self._child_classes = {}

	-- local function add_child(widget)
	-- 	if widget.type then
	-- 		local widget_class = rawget(_G, widget.type):new(self:canvas(), widget, unpack(widget.params or {}))
	-- 		widget_panel = widget_class:panel()
	-- 		self._child_classes[#self._child_classes + 1] = widget_class
	-- 	else
	-- 		widget_panel = self:canvas():panel(widget)
	-- 	end

	-- 	widget_panel:set_w(widget.w or self:canvas():w())
	-- 	widget_panel:set_h(widget.h or self:canvas():h())

	-- 	self:add_item(widget_panel)
	-- end

	-- for _, d_widget in ipairs(data.widgets or {}) do
	-- 	add_child(d_widget)
	-- end
	
	-- if data.widgets_table then
	-- 	for key, index_data in pairs(data.widgets_table.indices) do
	-- 		local widget_data = data.widgets_table.callback_return(key, index_data)
	-- 		add_child(widget_data)
	-- 	end
	-- end
end

function PRebornHorizontalScrollItemList:panel()
	return self._panel
end

function PRebornHorizontalScrollItemList:parent()
	return self._parent
end

function PRebornHorizontalScrollItemList:destroy()
	self:parent():remove(self._panel)
end

function PRebornHorizontalScrollItemList:mouse_moved(o, x, y)
	if not self._panel:visible() then
		return false
	end

	local mouse_inside = false

	for _, class in ipairs(self._child_classes) do
		mouse_inside = class:mouse_moved(o, x, y) or mouse_inside
	end

	return mouse_inside
end

function PRebornHorizontalScrollItemList:mouse_pressed(button, x, y)
	if not self._panel:visible() then
		return
	end

	for _, class in ipairs(self._child_classes) do
		class:mouse_pressed(button, x, y)
	end

	if button == Idstring("mouse wheel up") then
		return self:mouse_wheel_up(x, y)
	elseif button == Idstring("mouse wheel down") then
		return self:mouse_wheel_down(x, y)
	end

	self.super.mouse_pressed(self, button, x, y)
end

function PRebornHorizontalScrollItemList:mouse_wheel_up(x, y)
	if not alive(self._scroll) then
		return
	end

	self._scroll:scroll(x, y, self._dy)

	if not self._scroll:panel():inside(x, y) then
		return
	end

	return PRebornHorizontalScrollItemList.super.super.super.super.mouse_wheel_up(self, x, y)
end

function PRebornHorizontalScrollItemList:mouse_wheel_down(x, y)
	if not alive(self._scroll) then
		return
	end

	self._scroll:scroll(x, y, -self._dy)

	if not self._scroll:panel():inside(x, y) then
		return
	end

	return PRebornHorizontalScrollItemList.super.super.super.super.mouse_wheel_down(self, x, y)
end

PRebornVerticalScrollItemListSimple = PRebornVerticalScrollItemListSimple or class()

function PRebornVerticalScrollItemListSimple:init(panel, data)
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

function PRebornVerticalScrollItemListSimple:panel()
	return self._panel
end

function PRebornVerticalScrollItemListSimple:parent()
	return self._parent
end

function PRebornVerticalScrollItemListSimple:destroy()
	self:parent():remove(self._panel)
end

function PRebornVerticalScrollItemListSimple:canvas()
	return self._canvas
end

function PRebornVerticalScrollItemListSimple:add_item(item, force_visible, at_index, selected)
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

function PRebornVerticalScrollItemListSimple:set_selected_solo(key)
	for k, item in pairs(self._current_items) do
		if k == key then
			self:set_selected(k)
		else
			self:set_unselected(k)
		end
	end
end

function PRebornVerticalScrollItemListSimple:set_selected(key)
	self._selected = key

	if self._selection_mode == 1 then
		self._rects[key]:set_visible(true)
	elseif self._selection_mode == 2 then
		self._current_items[key]:set_alpha(0.5)
	end
end

function PRebornVerticalScrollItemListSimple:set_unselected(key)
	if self._selection_mode == 1 then
		self._rects[key]:set_visible(false)
	elseif self._selection_mode == 2 then
		self._current_items[key]:set_alpha(1)
	end
end

function PRebornVerticalScrollItemListSimple:items()
	return self._current_items
end

function PRebornVerticalScrollItemListSimple:all_items()
	return self._all_items
end

function PRebornVerticalScrollItemListSimple:perform_scroll(speed, direction)
	if self:canvas():h() <= self:panel():h() then
		return
	end

	local scroll_amount = speed * (direction or 1)
	local max_h = self:canvas():h() - self:panel():h()
	max_h = max_h * -1
	local new_y = math.clamp(self:canvas():y() + scroll_amount, max_h, 0)

	self:canvas():set_y(new_y)
end

function PRebornVerticalScrollItemListSimple:scroll(x, y, dy)
	if self:panel():inside(x, y) then
		self:perform_scroll(dy, 1)

		return true
	end
end

function PRebornVerticalScrollItemListSimple:set_callback(callback)
	self._callback = callback
end

function PRebornVerticalScrollItemListSimple:callback()
	return self._callback
end

function PRebornVerticalScrollItemListSimple:mouse_moved(o, x, y)
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

function PRebornVerticalScrollItemListSimple:mouse_pressed(button, x, y)
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

function PRebornVerticalScrollItemListSimple:mouse_wheel_up(x, y)
	self:scroll(x, y, self._dy)
end

function PRebornVerticalScrollItemListSimple:mouse_wheel_down(x, y)
	self:scroll(x, y, -self._dy)
end

function PRebornVerticalScrollItemListSimple:mouse_released(button, x, y)
end

PRebornSearchBox = PRebornSearchBox or class(SearchBoxGuiObject)

PRebornBoxGuiObject = PRebornBoxGuiObject or class(BoxGuiObject)

function PRebornBoxGuiObject:_create_side(panel, side, type, texture, one_two_align)
	local mvector_tl = Vector3()
	local mvector_tr = Vector3()
	local mvector_bl = Vector3()
	local mvector_br = Vector3()

	local ids_side = Idstring(side)
	local ids_left = Idstring("left")
	local ids_right = Idstring("right")
	local ids_top = Idstring("top")
	local ids_bottom = Idstring("bottom")
	local left_or_right = false
	local w, h

	if ids_side == ids_left or ids_side == ids_right then
		left_or_right = true
		w = 2
		h = panel:h()
	else
		w = panel:w()
		h = 2
	end

	local side_panel = panel:panel({
		name = side,
		w = w,
		h = h,
		halign = left_or_right and side or "scale",
		valign = left_or_right and "scale" or side
	})

	if type == 0 then
		return
	elseif type == 1 or type == 3 or type == 4 then
		local one = side_panel:rect({
			wrap_mode = "wrap",
			color = self._color
		})
		local two = side_panel:rect({
			wrap_mode = "wrap",
			color = self._color
		})
		local x = math.random(1, 255)
		local y = 1
		local tw = math.min(10, w)
		local th = math.min(10, h)

		if left_or_right then
			one:set_halign(side)
			two:set_halign(side)
			one:set_valign(one_two_align and "top" or "scale")
			two:set_valign(one_two_align and "bottom" or "scale")
			mvector3.set_static(mvector_tl, x, y + tw, 0)
			mvector3.set_static(mvector_tr, x, y, 0)
			mvector3.set_static(mvector_bl, x + th, y + tw, 0)
			mvector3.set_static(mvector_br, x + th, y, 0)

			x = math.random(1, 255)
			y = 1

			mvector3.set_static(mvector_tl, x, y + tw, 0)
			mvector3.set_static(mvector_tr, x, y, 0)
			mvector3.set_static(mvector_bl, x + th, y + tw, 0)
			mvector3.set_static(mvector_br, x + th, y, 0)
			one:set_size(2, th)
			two:set_size(2, th)
			two:set_bottom(h)
		else
			one:set_halign(one_two_align and "left" or "scale")
			two:set_halign(one_two_align and "right" or "scale")
			one:set_valign(side)
			two:set_valign(side)
			mvector3.set_static(mvector_tl, x, y, 0)
			mvector3.set_static(mvector_tr, x + tw, y, 0)
			mvector3.set_static(mvector_bl, x, y + th, 0)
			mvector3.set_static(mvector_br, x + tw, y + th, 0)

			x = math.random(1, 255)
			y = 1

			mvector3.set_static(mvector_tl, x, y, 0)
			mvector3.set_static(mvector_tr, x + tw, y, 0)
			mvector3.set_static(mvector_bl, x, y + th, 0)
			mvector3.set_static(mvector_br, x + tw, y + th, 0)
			one:set_size(tw, 2)
			two:set_size(tw, 2)
			two:set_right(w)
		end

		one:set_visible(type == 1 or type == 3)
		two:set_visible(type == 1 or type == 4)
	elseif type == 2 then
		local full = side_panel:rect({
			wrap_mode = "wrap",
			w = side_panel:w(),
			h = side_panel:h(),
			color = self._color
		})
		local x = math.random(1, 255)
		local y = 1

		if left_or_right then
			full:set_halign(side)
			full:set_valign("scale")
			mvector3.set_static(mvector_tl, x, y + w, 0)
			mvector3.set_static(mvector_tr, x, y, 0)
			mvector3.set_static(mvector_bl, x + h, y + w, 0)
			mvector3.set_static(mvector_br, x + h, y, 0)
		else
			full:set_halign("scale")
			full:set_valign(side)
			mvector3.set_static(mvector_tl, x, y, 0)
			mvector3.set_static(mvector_tr, x + w, y, 0)
			mvector3.set_static(mvector_bl, x, y + h, 0)
			mvector3.set_static(mvector_br, x + w, y + h, 0)
		end
	else
		Application:error("[PRebornBoxGuiObject] Type", type, "is not supported")
		Application:stack_dump()

		return
	end

	side_panel:set_position(0, 0)

	if ids_side == ids_right then
		side_panel:set_right(panel:w())
	elseif ids_side == ids_bottom then
		side_panel:set_bottom(panel:h())
	end

	return side_panel
end

-- 切换按钮Lib
PRebornMultipleToggle = PRebornMultipleToggle or class()

function PRebornMultipleToggle:init(panel, data)
	self.class = "multiple_toggle"
	self._parent = panel
	self._state = data.state or false

	self._panel = panel:panel(data)

	self.items = data.items or {}

	if #self.items == 0 then
		error("MultipleToggle must include (items)")
	end

	self.index = data.index or 1

	self._controllers = {}

	self._controllers.bg_button = PRebornButton:new(self._panel, {
		w = self._panel:w(),
		h = self._panel:h(),
		bg_color = data.bg_color or Color.white,
		bg_alpha = data.bg_alpha or 0,
		bg_layer = data.bg_layer or 1,
		active = false
	})

	local filter_panel = self._panel

	local menu_arrows_texture = "guis/textures/menu_arrows"

	self._controllers.set_filter_left = PRebornButton:new(filter_panel, {
		w = filter_panel:h(),
		h = filter_panel:h(),
		selection_mode = 2,
		callback = function()
			if (self.index - 1) >= 1 then
				self:toggle(self.index - 1)
			end
		end
	})

	local arrow_left_panel = self._controllers.set_filter_left:panel()

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

	arrow_left_panel:set_center_y(filter_panel:h() / 2)
	arrow_left:set_center_y(arrow_left_panel:h() / 2)

	self._controllers.set_filter_right = PRebornButton:new(filter_panel, {
		w = filter_panel:h(),
		h = filter_panel:h(),
		selection_mode = 2,
		callback = function()
			if (self.index + 1) <= #self.items then
				self:toggle(self.index + 1)
			end
		end
	})

	local arrow_right_panel = self._controllers.set_filter_right:panel()

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

	arrow_right_panel:set_right(filter_panel:w())
	arrow_right_panel:set_center_y(filter_panel:h() / 2)
	arrow_right:set_right(arrow_right_panel:w())
	arrow_right:set_center_y(arrow_right_panel:h() / 2)

	local filter_bg = filter_panel:rect({
		color = Color.black,
		alpha = 0.9,
		layer = -50,
		w = filter_panel:w(),
		h = filter_panel:h()
	})

	for layer, method in ipairs(self.items) do
		filter_panel:text({
			name = "bp_filter_" .. tostring(layer),
			visible = layer == self.index,
			vertical = "center",
			valign = "center",
			align = "center",
			halign = "center",
			font = tweak_data.hud_players.ammo_font,
			text = method,
			font_size = 18,
			layer = layer,
			color = data.text_color
		})
	end

	self:create_side(filter_panel)

	self._filter_panel = filter_panel

	self._callback = data.callback
end

function PRebornMultipleToggle:panel()
	return self._panel
end

function PRebornMultipleToggle:parent()
	return self._parent
end

function PRebornMultipleToggle:destroy()
	self:parent():remove(self._panel)
end

function PRebornMultipleToggle:callback()
	return self._callback
end

function PRebornMultipleToggle:set_callback(clbk)
	self._callback = clbk
end

function PRebornMultipleToggle:mouse_moved(o, x, y)
	local mouse_inside = false

	for _, cls in pairs(self._controllers) do
		mouse_inside = cls:mouse_moved(o, x, y) and true or mouse_inside
	end

	return mouse_inside
end

function PRebornMultipleToggle:mouse_pressed(button, x, y)
	if button == Idstring("0") then
		if self:inside(x, y) then
			for _, cls in pairs(self._controllers) do
				cls:mouse_pressed(button, x, y)
			end
		end
	end
end

function PRebornMultipleToggle:mouse_released(button, x, y)
	if button == Idstring("0") then
		if self:inside(x, y) then
			for _, cls in pairs(self._controllers) do
				cls:mouse_released(button, x, y)
			end
		end
	end
end

function PRebornMultipleToggle:inside(x, y)
	if self._panel:inside(x, y) then
		return true, "link"
	end

	return false, "arrow"
end

function PRebornMultipleToggle:toggle(index)
	local new_index = index
	self:set_state(new_index)

	return new_index
end

function PRebornMultipleToggle:set_state(index)
	self.index = index

	for layer, method in ipairs(self.items) do
		local child = self._filter_panel:child("bp_filter_" .. layer)
		child:set_visible(child:layer() == self.index)
	end

	self._callback(index)
end

function PRebornMultipleToggle:create_side(panel)
	BoxGuiObject:_create_side(panel, "left", 1, false, false)
	BoxGuiObject:_create_side(panel, "right", 1, false, false)
	BoxGuiObject:_create_side(panel, "top", 1, false, false)
	BoxGuiObject:_create_side(panel, "bottom", 1, false, false)
end