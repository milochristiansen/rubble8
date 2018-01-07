
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local preact = rubble.require "reaction_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"

function makeliquid(liquid)
	return function(items, wshop, extra)
		local mat = pitems.GetMRP(liquid, dfhack.matinfo.decode(items[1]))
		local nitem = pitems.CreateItem(mat, 'item_liquid_miscst', nil, 0)
		nitem:setDimension(150)
		nitem.stack_size = items[1].stack_size
		
		dfhack.items.moveToContainer(nitem, extra.jug)
		pitems.Eject(wshop, extra.jug)
	end
end

function pressAndEject(items, wshop, extra)
	items[1]:makePressed()
	pitems.Eject(wshop, items[1])
end

preact.AddRecipe("DFHACK_POWERED_SCREW_PRESS", {
	validate = pfilter.Item("GLOB:NONE", pfilter.MRP("PRESS_LIQUID_MAT")),
	input_item = pressAndEject,
	output_item = makeliquid("PRESS_LIQUID_MAT"),
})

preact.AddRecipe("DFHACK_POWERED_SCREW_PRESS", {
	validate = pfilter.Item("PLANT_GROWTH:NONE", pfilter.MRP("PRESS_LIQUID_MAT")),
	input_item = function(items, wshop, extra)
		local nitem = pitems.CreateItem(dfhack.matinfo.decode(items[1]), 'item_globst', nil, 0)
		nitem:setDimension(150)
		nitem.stack_size = items[1].stack_size
		nitem:makePressed()
		dfhack.items.remove(items[1])
		pitems.Eject(wshop, nitem)
	end,
	output_item = makeliquid("PRESS_LIQUID_MAT"),
})

preact.AddRecipe("DFHACK_POWERED_SCREW_PRESS", {
	validate = pfilter.Item("TOOL:ITEM_TOOL_HONEYCOMB", pfilter.MRP("HONEYCOMB_PRESS_MAT")),
	input_item = pressAndEject,
	output_item = makeliquid("HONEYCOMB_PRESS_MAT"),
})

pwshops.Register("DFHACK_POWERED_SCREW_PRESS", nil, 20, 0, 500, preact.MakeHandler("DFHACK_POWERED_SCREW_PRESS", {
	validate = function(wshop, extra)
		local jug = pitems.FindItemAtInput(wshop, pfilter.Jug(pfilter.Empty()))
		if jug == nil then
			return false
		end
		return true
	end,
	
	pre = function(wshop, extra)
		return {
			jug = pitems.FindItemAtInput(wshop, pfilter.Jug(pfilter.Empty())),
		}
	end,
	
	mangle_item = pdisaster.Switch{
		-- If the item is not hard then 1% chance of damage and rot it if possible, else pass it.
		{pfilter.Not(pfilter.MatFlag("ITEMS_HARD")), pdisaster.Damage(1, pdisaster.RotItem(pdisaster.PassItem))},
		
		-- Any other (invalid) item gives a 10% chance of damage, and the item is passed.
		{pfilter.Dummy, pdisaster.Damage(10, pdisaster.PassItem)},
	},
	
	mangle_unit = pdisaster.MangleCreature,
	
	black_list = pfilter.Jug()
}))
