
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local preact = rubble.require "reaction_libs_powered"

preact.AddRecipe("DFHACK_POWERED_JEWELER", {
	validate = pfilter.Item("ROUGH:NONE"),
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras)
		local mat = dfhack.matinfo.decode(items[1])
		
		local product = nil
		if math.random(10) == 1 then
			product = "item_gemst"
		else
			product = "item_smallgemst"
		end
		
		local item = pitems.CreateItem(mat, product, nil, 0)
		pitems.Eject(wshop, item)
	end,
})

preact.AddRecipe("DFHACK_POWERED_JEWELER", {
	validate = pfilter.Item("BOULDER:NONE", pfilter.MatFlag("IS_STONE")),
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras)
		local mat = dfhack.matinfo.decode(items[1])
		
		local product = nil
		if math.random(10) == 1 then
			product = "item_gemst"
		else
			product = "item_smallgemst"
		end
		
		local item = pitems.CreateItem(mat, product, nil, 0)
		pitems.Eject(wshop, item)
	end,
})

pwshops.Register("DFHACK_POWERED_JEWELER", nil, 20, 0, 500, preact.MakeHandler("DFHACK_POWERED_JEWELER", {
	mangle_item = pdisaster.Switch({
		-- If the item is not hard then 1% chance of damage and rot it if possible, else pass it.
		{pfilter.Not(pfilter.MatFlag("ITEMS_HARD")), pdisaster.Damage(1, pdisaster.RotItem(pdisaster.PassItem))},
		
		-- Any other (invalid) item gives a 10% chance of damage, and the item is passed.
		{pfilter.Dummy, pdisaster.Damage(10, pdisaster.PassItem)},
	}),
	mangle_unit = pdisaster.MangleCreature,
}))
