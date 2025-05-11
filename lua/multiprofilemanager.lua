Hooks:PostHook(MultiProfileManager, "init", "ProfileRebornSetup", function(self)
	self.profile_reborn = ProfileReborn:new()
end)

Hooks:OverrideFunction(MultiProfileManager, "open_quick_select", function(self)
	if self.profile_reborn then
		self:save_current()
		-- self:load_current()
		self.profile_reborn:active()
	end
end)
