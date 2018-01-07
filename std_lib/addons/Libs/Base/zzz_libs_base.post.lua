
axis.write("out/init.lua", '\n-- DFHack init.lua script file\n-- Automatically generated, DO NOT EDIT!\n'..
rubble.files["loader_libs_base.lua"].Content..'\ndfhack.gui.showAnnouncement("This region\'s raws were generated with Rubble v'..
rubble.version..'!", COLOR_LIGHTGREEN)\n')

local write = false
local base = "\n# DFHack onLoad.init file\n# Automatically generated, DO NOT EDIT!\n"

local reactions = rubble.registry["Libs/Base:DFHack Reactions"]
if #reactions.list > 0 then
	write = true
	base = base.."\n# Reactions:\n"
	for _, id in ipairs(reactions.list) do
		base = base.."modtools/reaction-trigger -reactionName \""..id.."\" -command [ "..reactions.table[id].." ]\n"
	end
end

local commands = rubble.registry["Libs/Base:DFHack Commands"]
if #commands.list > 0 then
	write = true
	base = base.."\n# Commands:\n"
	for _, action in ipairs(commands.list) do
		base = base..action.."\n"
	end
end

local extras = rubble.registry["Libs/Base:DFHack Init Extras"]
if #extras.list > 0 then
	write = true
	base = base.."\n# Extras:\n"
	for _, txt in ipairs(extras.list) do
		base = base..txt.."\n"
	end
end

if write then
	axis.write("out/onLoad.init", base)
end
