
local melt = rubble.require "libs_melt_item"
local eventful = require 'plugins.eventful'

-- Register all melt reactions with eventful.
for _, r in ipairs(melt.reactions) do
	eventful.registerReaction(r, melt.meltMetalItemHook)
end

-- This finds the melt reactions and sets them to only accept melt designated items.
for _, reaction in ipairs(df.global.world.raws.reactions) do
	for _, r in ipairs(melt.reactions) do
		if reaction.code == r then
			for i = 0, #reaction.reagents - 1, 1 do
				if string.match(reaction.reagents[i].code, '%_melt$') then
					reaction.reagents[i].flags2.melt_designated = true
					reaction.reagents[i].flags2.allow_melt_dump = true
				end
			end
		end
	end
end

