
local howmany = tonumber(rubble.configvar("DEV_DUMMY_REACTION_COUNT"))
if howmany == nil then
	howmany = 5
end

local out = '[OBJECT:REACTION]\n\nThe following are "dummy" reactions used to add content after worldgen.\n'

for count = 1, howmany, 1 do
	out = out.."\n{REACTION;DUMMY_REACTION_"..count..";ADDON_HOOK_PLAYABLE}\n"..
		"\tAdd your reaction body here\n"
end

rubble.files["reaction_dev_dummy_reactions.txt"].Content = out
