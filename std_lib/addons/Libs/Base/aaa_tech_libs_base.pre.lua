
-- Tech Templates

function rubble.libs_base.buildingregister(id, class)
	rubble.registry["Libs/Base:BUILDING_XYZ:"..class]:listappend(id)
end

rubble.template("BUILDING_WORKSHOP", [[
	local id, class = rubble.targs({...}, {"", ""})
	rubble.registry["Libs/Base:BUILDING_XYZ"].table["last"] = id
	rubble.libs_base.buildingregister(id, class)
	return "[BUILDING_WORKSHOP:"..id.."]"
]])
rubble.template("BUILDING_FURNACE", [[
	local id, class = rubble.targs({...}, {"", ""})
	rubble.registry["Libs/Base:BUILDING_XYZ"].table["last"] = id
	rubble.libs_base.buildingregister(id, class)
	return "[BUILDING_FURNACE:"..id.."]"
]])

rubble.template("BUILDING_ADD_CLASS", [[
	local class, id = rubble.targs({...}, {"", rubble.registry["Libs/Base:BUILDING_XYZ"].table["last"]})
	rubble.libs_base.buildingregister(id, class)
]])

rubble.template("REMOVE_BUILDING", [[
	local id, class = rubble.targs({...}, {"", ""})
	
	rubble.registry["Libs/Base:REMOVE_BUILDING:"..class].table[id] = "t"
]])

rubble.template("REMOVE_BUILDING_FROM_PLAYABLES", [[
	local id = rubble.targs({...}, {""})
	
	local fort = rubble.registry["Libs/Base:!ENTITY_PLAYABLE:FORT"].table
	
	for ent, flag in pairs(fort) do
		if flag == "t" then
			local class = "ADDON_HOOK_"..ent
			rubble.registry["Libs/Base:REMOVE_BUILDING:"..class].table[id] = "t"
		end
	end
	
	local class = "ADDON_HOOK_PLAYABLE"
	rubble.registry["Libs/Base:REMOVE_BUILDING:"..class].table[id] = "t"
]])

function rubble.libs_base.uses_buildings(class)
	local out = ""
	if rubble.registry.exists["Libs/Base:BUILDING_XYZ:"..class] then
		local building_data = rubble.registry["Libs/Base:BUILDING_XYZ:"..class].list
		
		for _, building in ipairs(building_data) do
			if rubble.registry.exists["Libs/Base:REMOVE_BUILDING:"..class] then
				if rubble.registry["Libs/Base:REMOVE_BUILDING:"..class].table[building] == "t" then
					goto continue
				end
			end
			out = out.."\n\t[PERMITTED_BUILDING:"..building.."]"
			::continue::
		end
	end
	return string.trimspace(out)
end

rubble.template("#USES_BUILDINGS", [[
	return rubble.libs_base.uses_buildings(rubble.targs{...})
]])

function rubble.libs_base.reactionregister(id, class)
	rubble.registry["Libs/Base:REACTION:"..class]:listappend(id)
end

function rubble.libs_base.reaction(id, class)
	rubble.registry["Libs/Base:REACTION"].table["last"] = id
	rubble.libs_base.reactionregister(id, class)
	return "[REACTION:"..id.."]"
end

rubble.template("REACTION", [[
	local id, class = rubble.targs({...}, {"", ""})
	return rubble.libs_base.reaction(id, class)
]])

rubble.template("!REACTION_NEW_CATEGORY", [[
	local id, name, description, key, parent = rubble.targs({...}, {"", "", "", "", ""})
	local data = rubble.registry["Libs/Base:REACTION_CATEGORY"].table
	
	if data[id] ~= nil then
		rubble.abort("Reaction category: \""..id.."\" defined twice")
	end
	
	data[id] = "t"
	out = "[REACTION:_REACTION_CATEGORY_"..id.."_]\n\t[CATEGORY:"..id.."]\n\t\t[CATEGORY_NAME:"..name.."]\n\t\t[CATEGORY_DESCRIPTION:"..description.."]"
	if key ~= "" then
		out = out.."\n\t\t[CATEGORY_KEY:"..key.."]"
	end
	if parent ~= "" then
		if data[parent] ~= nil then
			out = out.."\n\t\t[CATEGORY_PARENT:"..parent.."]"
		else
			rubble.abort("Reaction category: \""..id.."\" parent: \""..parent.."\" not defined.")
		end
	end
	return out
]])

rubble.template("REACTION_CATEGORY", [[
	local id = rubble.targs({...}, {""})
	local data = rubble.registry["Libs/Base:REACTION_CATEGORY"].table
	
	if data[id] ~= "t" then
		rubble.abort("Reaction category: \""..id.."\" not defined")
	end
	
	return "[CATEGORY:"..id.."]"
]])

rubble.template("DFHACK_REACTION", [[
	local id, action, class = rubble.targs({...}, {"", "", ""})
	
	local reactions = rubble.registry["Libs/Base:DFHack Reactions"]
	if reactions.table[id] == nil then
		reactions:listappend(id)
	end
	reactions.table[id] = action
	
	return rubble.libs_base.reaction(id, class)
]])

rubble.template("DFHACK_REACTION_BIND", [[
	local action, id = rubble.targs({...}, {"", rubble.registry["Libs/Base:REACTION"].table["last"]})
	
	local reactions = rubble.registry["Libs/Base:DFHack Reactions"]
	if reactions.table[id] == nil then
		reactions:listappend(id)
	end
	reactions.table[id] = action
]])

rubble.template("REACTION_ADD_CLASS", [[
	local class, id = rubble.targs({...}, {"", rubble.registry["Libs/Base:REACTION"].table["last"]})
	rubble.libs_base.reactionregister(id, class)
]])

rubble.template("REMOVE_REACTION", [[
	local id, class = rubble.targs({...}, {"", ""})
	
	rubble.registry["Libs/Base:REMOVE_REACTION:"..class].table[id] = "t"
]])

rubble.template("REMOVE_REACTION_FROM_PLAYABLES", [[
	local id = rubble.targs({...}, {""})
	
	local fort = rubble.registry["Libs/Base:!ENTITY_PLAYABLE:FORT"].table
	
	for ent, flag in pairs(fort) do
		if flag == "t" then
			local class = "ADDON_HOOK_"..ent
			rubble.registry["Libs/Base:REMOVE_REACTION:"..class].table[id] = "t"
		end
	end
	
	local class = "ADDON_HOOK_PLAYABLE"
	rubble.registry["Libs/Base:REMOVE_REACTION:"..class].table[id] = "t"
]])


function rubble.libs_base.uses_reactions(class)
	local out = ""
	if rubble.registry.exists["Libs/Base:REACTION:"..class] then
		local reaction_data = rubble.registry["Libs/Base:REACTION:"..class].list
		
		for _, reaction in ipairs(reaction_data) do
			if rubble.registry.exists["Libs/Base:REMOVE_REACTION:"..class] then
				if rubble.registry["Libs/Base:REMOVE_REACTION:"..class].table[reaction] == "t" then
					goto continue
				end
			end
			out = out.."\n\t[PERMITTED_REACTION:"..reaction.."]"
			::continue::
		end
	end
	return string.trimspace(out)
end


rubble.template("#USES_REACTIONS", [[
	return rubble.libs_base.uses_reactions(rubble.targs({...}, {""}))
]])

rubble.template("#USES_TECH", [[
	local class = rubble.targs({...}, {""})
	return string.trimspace(rubble.libs_base.uses_buildings(class).."\n\t"..rubble.libs_base.uses_reactions(class))
]])

-- combination of #USES_TECH and #USES_ITEMS.
rubble.template("#ADDON_HOOK", [[
	local class = rubble.targs({...}, {""})
	class = "ADDON_HOOK_"..class
	local out = "# Hook: "..class.."\n"
	
	local items = rubble.libs_base.uses_items(class)
	if items ~= "" then
		out = out.."\t"..items.."\n"
	end
	
	local buildings = rubble.libs_base.uses_buildings(class)
	if buildings ~= "" then
		out = out.."\t"..buildings.."\n"
	end
	
	local reactions = rubble.libs_base.uses_reactions(class)
	if reactions ~= "" then
		out = out.."\t"..reactions.."\n"
	end
	
	return string.trimspace(out)
]])

rubble.usertemplate("ADDON_HOOKS", {{"id", ""}}, string.trimspace([[
	{#ADDON_HOOK;%{id}}
	{#ADDON_HOOK;GENERIC}
	{#ECHO;{@IF_ENTITY_PLAYABLE;%{id};FORT;
		{#ADDON_HOOK;PLAYABLE}
	;
		# Entity Not Playable in Fortress Mode.
	}}
]]))
