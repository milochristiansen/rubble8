
local event = require "plugins.eventful"

function resize(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
	call_native.value=false
	
	in_items[0]:setMakerRace(unit.race)
end

event.registerReaction("RESIZE_CLOTHING_ADV", resize)
