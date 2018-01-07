
function rubble.entity_playable(id, key)
	key = string.upper(key)
	
	local valid = {["FORT"] = true, ["ADV"] = true}
	if valid[key] == nil then
		return nil
	end
	
	return rubble.registry["Libs/Base:!ENTITY_PLAYABLE:"..key].table[id] == "t"
end

-- {!ENTITY_PLAYABLE;MOUNTAIN;true;true;false}
rubble.template("!ENTITY_PLAYABLE", [[
	local id, fort, adv = rubble.targs({...}, {"", "false", "false"})
	
	rubble.registry["Libs/Base:!ENTITY_PLAYABLE:FORT"].table[id] = rubble.tobool(fort, "t", "f")
	rubble.registry["Libs/Base:!ENTITY_PLAYABLE:ADV"].table[id] = rubble.tobool(adv, "t", "f")
	
	return "{#_ENTITY_PLAYABLE;"..id.."}"
]])

-- For internal use only!
rubble.template("#_ENTITY_PLAYABLE", [[
	local id = rubble.targs({...}, {""})
	
	local fort = rubble.registry["Libs/Base:!ENTITY_PLAYABLE:FORT"].table
	local adv = rubble.registry["Libs/Base:!ENTITY_PLAYABLE:ADV"].table
	
	if adv[id] ~= "t" and fort[id] ~= "t" then
		return "# Entity is Not Playable."
	end
	
	local out = ""
	if fort[id] == "t" then
		out = out.."[SITE_CONTROLLABLE]"
	end
	
	if adv[id] == "t" then
		out = out.."[ALL_MAIN_POPS_CONTROLLABLE]"
	end
	
	return out
]])

rubble.template("ENTITY_PLAYABLE_EDIT", [[
	local id, key, value = rubble.targs({...}, {"", "", "false"})
	value = rubble.tobool(value, "t", "f")
	key = string.upper(key)
	
	local valid = {["FORT"] = true, ["ADV"] = true}
	if valid[key] == nil then
		rubble.abort "Invalid playability key in call to ENTITY_PLAYABLE_EDIT."
	end
	
	rubble.registry["Libs/Base:!ENTITY_PLAYABLE:"..key].table[id] = value
]])

rubble.template("@IF_ENTITY_PLAYABLE", [[
	local id, key, t, e = rubble.targs({...}, {"", "", "", ""})
	key = string.upper(key)
	
	local valid = {["FORT"] = true, ["ADV"] = true}
	if valid[key] == nil then
		rubble.abort "Invalid playability key in call to @IF_ENTITY_PLAYABLE."
	end
	
	if rubble.registry["Libs/Base:!ENTITY_PLAYABLE:"..key].table[id] == "t" then
		return rubble.parse(t, -1)
	end
	return rubble.parse(e, -1)
]])

rubble.template("#ENTITY_NOBLES", [[
	local id, default = rubble.targs({...}, {"", ""})
	
	local nobles = rubble.registry["Libs/Base:#ENTITY_NOBLES"].table
	local add = rubble.registry["Libs/Base:ENTITY_ADD_NOBLE"].table
	add = add[id] or ""
	
	if nobles[id] == nil then
		return string.trimspace(rubble.parse(default.."\n\t"..add, -1))
	else
		return string.trimspace(rubble.parse(nobles[id].."\n\t"..add, -1))
	end
]])

rubble.template("ENTITY_ADD_NOBLE", [[
	local id, noble = rubble.targs({...}, {"", ""})
	
	local add = rubble.registry["Libs/Base:ENTITY_ADD_NOBLE"].table
	
	if add[id] == nil then
		add[id] = rubble.parse(noble)
	else
		add[id] = add[id].."\n\t"..rubble.parse(noble)
	end
]])

rubble.template("ENTITY_REPLACE_NOBLES", [[
	local id, nobles = rubble.targs({...}, {"", ""})
	
	rubble.registry["Libs/Base:#ENTITY_NOBLES"].table[id] = rubble.parse(nobles)
]])
