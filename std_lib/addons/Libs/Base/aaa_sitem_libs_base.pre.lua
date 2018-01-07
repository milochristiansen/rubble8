
-- Item templates

rubble.template("!SHARED_ITEM", [[
	local typ, id, def = rubble.targs({...}, {"", "", ""})
	
	if typ == "FOOD" then
		-- FOOD doesn't need to be registered in an entity, so translate it directly to a normal SHARED_OBJECT call.
		return rubble.parse("{!SHARED_OBJECT;"..id..";\n[ITEM_FOOD:"..id.."]\n\t"..def.."\n}{!SHARED_OBJECT_CATEGORY;"..id..";ITEM_FOOD}")
	end
	
	local types = {
		["AMMO"] = true,
		["ARMOR"] = true,
		["DIGGER"] = true,
		["GLOVES"] = true,
		["HELM"] = true,
		["INSTRUMENT"] = true,
		["PANTS"] = true,
		["SHIELD"] = true,
		["SHOES"] = true,
		["SIEGEAMMO"] = true,
		["TOOL"] = true,
		["TOY"] = true,
		["TRAPCOMP"] = true,
		["WEAPON"] = true,
	}
	
	if not types[typ] then
		rubble.abort "Error: Invalid item type passed to !SHARED_ITEM."
	end
	
	local current = rubble.registry["Libs/Base:!SHARED_ITEM"].table
	current["id"] = id
	current["type"] = typ
	
	if typ == "DIGGER" then
		typ = "WEAPON"
	end
	
	return rubble.parse("{!SHARED_OBJECT;ITEM_"..typ..":"..id..";\n[ITEM_"..typ..":"..id.."]\n\t"..def.."\n}"..
		"{!SHARED_OBJECT_CATEGORY;ITEM_"..typ..":"..id..";ITEM_"..typ.."}")
]])

rubble.template("!ITEM_CLASS", [[
	local current = rubble.registry["Libs/Base:!SHARED_ITEM"].table
	
	local typ, id, class, rarity
	args = {...}
	if #args > 2 then
		typ, id, class, rarity = rubble.targs(args, {"", "", "", "COMMON"})
	else
		typ, id = current["type"], current["id"]
		class, rarity = rubble.targs(args, {"", "COMMON"})
	end
	
	local valid = {["RARE"] = true, ["UNCOMMON"] = true, ["COMMON"] = true, ["FORCED"] = true}
	if not valid[rarity] then
		rubble.abort "Error: Invalid item rarity passed to !ITEM_CLASS."
	end
	
	local item_data = rubble.registry["Libs/Base:!SHARED_ITEM:"..class]
	item_data:listappend(id)
	item_data:listappend(rarity)
	item_data:listappend(typ)
]])

rubble.template("REMOVE_ITEM", [[
	local id, class = rubble.targs({...}, {"", ""})
	
	rubble.registry["Libs/Base:REMOVE_ITEM:"..class].table[id] = "t"
]])

rubble.template("REMOVE_ITEM_FROM_PLAYABLES", [[
	local id = rubble.targs({...}, {""})
	
	local fort_playability = rubble.registry["Libs/Base:!ENTITY_PLAYABLE:FORT"].table
	
	for ent, ok in pairs(fort_playability) do
		if ok == "t" then
			local class = "ADDON_HOOK_"..ent
			
			local ban_data = rubble.registry["Libs/Base:REMOVE_ITEM:"..class].table
			ban_data[id] = "t"
		end
	end
	
	local class = "ADDON_HOOK_PLAYABLE"
	local ban_data = rubble.registry["Libs/Base:REMOVE_ITEM:"..class].table
	ban_data[id] = "t"
]])

local has_rarity = {
	["AMMO"] = false,
	["ARMOR"] = true,
	["DIGGER"] = false,
	["GLOVES"] = true,
	["HELM"] = true,
	["INSTRUMENT"] = false,
	["PANTS"] = true,
	["SHIELD"] = false,
	["SHOES"] = true,
	["SIEGEAMMO"] = false,
	["TOOL"] = false,
	["TOY"] = false,
	["TRAPCOMP"] = false,
	["WEAPON"] = false,
}

function rubble.libs_base.uses_items(class)
	local out = ""
	if rubble.registry.exists["Libs/Base:!SHARED_ITEM:"..class] then
		local item_data = rubble.registry["Libs/Base:!SHARED_ITEM:"..class].list
		
		local i = 1
		while i + 2 <= #item_data do
			local id, rarity, typ = item_data[i], item_data[i + 1], item_data[i + 2]
			
			local ok = true
			
			if rubble.registry.exists["Libs/Base:REMOVE_ITEM:"..class] then
				local ban_data = rubble.registry["Libs/Base:REMOVE_ITEM:"..class].table
				if ban_data[id] == "t" then
					ok = false
				end
			end
			if ok then
				if has_rarity[typ] then
					out = out.."\n\t["..typ..":"..id..":"..rarity.."]"
				else
					out = out.."\n\t["..typ..":"..id.."]"
				end
			end
			
			i = i + 3
		end
	end
	return string.trimspace(out)
end

rubble.template("#USES_ITEMS", [[
	return rubble.libs_base.uses_items(rubble.targs({...}, {""}))
]])
