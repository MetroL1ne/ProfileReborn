local mpath = ModPath

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_ProfileReborn", function(loc)
	local lang, path = SystemInfo and SystemInfo:language(), "loc/english.json"
	if lang == Idstring("schinese") then
		path = "loc/schinese.json"
	end
	loc:load_localization_file(mpath .. path)
end)