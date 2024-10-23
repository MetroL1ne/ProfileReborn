Hooks:OverrideFunction(MultiProfileManager, "open_quick_select", function(self)
	if ProfileReborn then
		self:save_current()
		-- self:load_current()
		ProfileReborn:active()
	end
end)