
-- Adds the templates, commands and variables that make up the automatic DFHack init script support

function rubble.libs_base.dfhack_runcommand(com)
	local commands = rubble.registry["Libs/Base:DFHack Commands"]
	if commands.table[com] == nil then
		commands:listappend(com)
		commands.table[com] = ""
	end
end

-- Run a command when the world is loaded.
rubble.template("DFHACK_RUNCOMMAND", [[
	rubble.libs_base.dfhack_runcommand(rubble.targs({...}, {""}))
]])

-- The DFHACK_REACTION and DFHACK_REACTION_BIND templates are with the tech templates.
-- The onload.init and init.lua files are written in zzz_libs_base.post.lua
