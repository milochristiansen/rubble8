
-- Announcement Templates

-- Example:
-- Right after a reaction:
-- {DFHACK_ANNOUNCE;You have unleashed a dragon!;COLOR_LIGHTRED}
-- (the color defaults to white)

-- Use this template as a replacement for the REACTION template
rubble.template("DFHACK_REACTION_ANNOUNCE", [[
	local id, class, text, color = rubble.targs({...}, {"", "", "", "COLOR_WHITE"})
	
	local reactions = rubble.registry["Libs/Base:DFHack Reactions"]
	if reactions.table[id] == nil then
		reactions:listappend(id)
	end
	reactions.table[id] = 'libs_announcement "'..text..'" '..color
	
	return rubble.libs_base.reaction(id, class)
]])

rubble.template("DFHACK_ANNOUNCE", [[
	local text, color, id = rubble.targs({...}, {"", "COLOR_WHITE", rubble.registry["Libs/Base:REACTION"].table["last"]})
	
	local reactions = rubble.registry["Libs/Base:DFHack Reactions"]
	if reactions.table[id] == nil then
		reactions:listappend(id)
	end
	reactions.table[id] = 'libs_announcement "'..text..'" '..color
]])
