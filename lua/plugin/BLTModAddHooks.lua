local plugins_path = ModPath.. "plugins/"
for _, file_name in pairs(file.GetDirectories(plugins_path)) do
	local file = io.open(plugins_path .. file_name .. "/plugin.txt")
	if file then
		local file_contents = file:read("*all")
		file:close()
		
		local plugin_content = json.decode(file_contents)
		if plugin_content then
			local pr_mod = BLT.Mods:GetModByName("Profile Reborn")  -- Mod Name
			local destination = BLT.hook_tables.post
			local wildcards_destination = BLT.hook_tables.wildcards
			local base_path = "plugins/" .. file_name .. "/"
			
			for _, hook_data in ipairs(plugin_content["hooks"] or {}) do
				local script_path = base_path .. hook_data.script_path
				pr_mod:AddHook("hooks", hook_data.hook_id, script_path, destination, wildcards_destination)
			end
			
			for _, hook_data in ipairs(plugin_content["pre_hooks"] or {}) do
				local script_path = base_path .. hook_data.script_path
				pr_mod:AddHook("pre_hooks", hook_data.hook_id, script_path, destination, wildcards_destination)
			end
		end
	end
end