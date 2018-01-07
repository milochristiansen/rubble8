
rubble.template("DFHACK_REACTION_CASTE_TRANSFORM", [[
	local id, class, race, caste, delay = rubble.targs({...}, {"", "", "", "", 0})
	delay = tonumber(delay)
	if delay == nil then
		rubble.error("Delay value must be a number")
	end
	
	local action = nil
	if delay > 0 then
		action = 'libs_castes_dfhack_transform -unit \\\\WORKER_ID -race '..race..' -caste '..caste..' -delay '..delay
	else
		action = 'libs_castes_dfhack_transform -unit \\\\WORKER_ID -race '..race..' -caste '..caste
	end
	
	local reactions = rubble.registry["Libs/Base:DFHack Reactions"]
	if reactions.table[id] == nil then
		reactions:listappend(id)
	end
	reactions.table[id] = action
	
	return rubble.libs_base.reaction(id, class)
]])

rubble.template("DFHACK_CASTE_TRANSFORM", [[
	local race, caste, delay, id = rubble.targs({...}, {"", "", 0, rubble.libs_base.reaction_last})
	delay = tonumber(delay)
	if delay == nil then
		rubble.error("Delay value must be a number")
	end
	
	local action = nil
	if delay > 0 then
		action = 'libs_castes_dfhack_transform -unit \\\\WORKER_ID -race '..race..' -caste '..caste..' -delay '..delay
	else
		action = 'libs_castes_dfhack_transform -unit \\\\WORKER_ID -race '..race..' -caste '..caste
	end
	
	local reactions = rubble.registry["Libs/Base:DFHack Reactions"]
	if reactions.table[id] == nil then
		reactions:listappend(id)
	end
	reactions.table[id] = action
]])
