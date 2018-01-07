
-- Rewrite any and all objects that have a specialized shared object template to use
-- that template (if they don't already).

-- Use only with untemplated raws!

function guts(name, contents, prefix, tags, postfix, tagprefix, extras)
	rubble.print("    "..name.."\n")
	
	local foundfirst = false
	local file = rubble.rparse.parse(contents)
	
	local nextextra = ""
	
	for i, tag in ipairs(file) do
		for ti, typ in ipairs(tags) do
			if tag.ID == tagprefix..typ then
				if #tag.Params == 1 then
					if file[i - 1] ~= nil and foundfirst then
						if string.find(file[i - 1].Comments, "\n") == nil then
							file[i - 1].Comments = file[i - 1].Comments.."\n}"..nextextra.."\n"
						else
							file[i - 1].Comments = string.replace(file[i - 1].Comments, "\n", "\n"..nextextra.."}\n", 1)
						end
					end
					
					foundfirst = true
					if extras and extras[ti] then
						nextextra = extras[ti]
					else
						nextextra = ""
					end
					tag.Comments = "{"..prefix..typ..";"..tag.Params[1]..postfix..";"..tag.Comments
					tag.CommentsOnly = true
				else
					rubble.abort("      Error: invalid param count to "..typ.." raw tag in last file.")
				end
			end
		end
	end
	
	if foundfirst then
		local tag = file[#file]
		if string.find(tag.Comments, "\n") == nil then
			tag.Comments = tag.Comments.."\n}"..nextextra.."\n"
		else
			tag.Comments = string.replace(tag.Comments, "\n", "\n}"..nextextra.."\n", 1)
		end
	end
	axis.write("rubble/dev_so_insert/"..name, rubble.rparse.format(file))
end

local objects = {
	{rubble.filters.item, "!SHARED_ITEM;", {
		"AMMO",
		"ARMOR",
		"DIGGER",
		"GLOVES",
		"HELM",
		"INSTRUMENT",
		"PANTS",
		"SHIELD",
		"SHOES",
		"SIEGEAMMO",
		"TOOL",
		"TOY",
		"TRAPCOMP",
		"WEAPON",
	}, "", "ITEM_", {
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE;COMMON}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE;COMMON}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE;COMMON}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE;COMMON}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE;COMMON}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE}",
		"{!ITEM_CLASS;ADDON_HOOK_PLAYABLE}",
	}},
	{rubble.filters.creature, "!SHARED_", {"CREATURE"}, "", ""},
	{rubble.filters.inorganic, "!SHARED_", {"INORGANIC"}, "", ""},
	{rubble.filters.material_template, "!SHARED_", {"MATERIAL_TEMPLATE"}, "", ""},
	{rubble.filters.plant, "!SHARED_", {"PLANT"}, "", ""},
	{rubble.filters.c_variation, "!SHARED_", {"CREATURE_VARIATION"}, "", ""},
	{rubble.filters.tissue_template, "!SHARED_", {"TISSUE_TEMPLATE"}, "", ""},
	{rubble.filters.b_detail_plan, "!SHARED_", {"BODY_DETAIL_PLAN"}, "", ""},
	{rubble.filters.interaction, "!SHARED_", {"INTERACTION"}, "", ""},
	{rubble.filters.body, "!SHARED_", {"BODY"}, "", ""},
	{rubble.filters.reaction, "!SHARED_", {"REACTION"}, ";ADDON_HOOK_PLAYABLE", ""},
	{rubble.filters.building, "!SHARED_", {"BUILDING_WORKSHOP", "BUILDING_FURNACE"}, ";ADDON_HOOK_PLAYABLE", ""},
	{rubble.filters.entity, "!SHARED_", {"ENTITY"}, ";false;false", ""},
	{rubble.filters.language, "!SHARED_", {"TRANSLATION", "SYMBOL", "WORD"}, "", ""},
	{rubble.filters.descriptor, "!SHARED_", {"COLOR", "COLOR_PATTERN", "SHAPE"}, "", ""},
}

for _, v in ipairs(objects) do	
	rubble.fileaction(v[1], function(file)
		guts(file.Name, file.Content, v[2], v[3], v[4], v[5])
	end)
end

rubble.abort "Finished exporting changed files (this is not an error)."
