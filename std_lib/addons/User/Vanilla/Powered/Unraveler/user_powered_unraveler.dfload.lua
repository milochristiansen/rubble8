
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local preact = rubble.require "reaction_libs_powered"

preact.AddRecipe("DFHACK_POWERED_UNRAVELER", {
	validate = pfilter.Item("CLOTH:NONE"),
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras)
		-- Cloth unraveling has a 25% chance to fail
		if math.random(4) == 1 then
			return
		end
		
		local mat = dfhack.matinfo.decode(items[1])
		
		local item = pitems.CreateItem(mat, 'item_threadst', nil, 0)
		item:setDimension(15000)
		pitems.Eject(wshop, item)
	end,
})

preact.AddRecipe("DFHACK_POWERED_UNRAVELER", {
	validate = pfilter.Or{
		pfilter.MatFlag("THREAD_PLANT"),
		pfilter.MatFlag("SILK"),
		pfilter.MatFlag("YARN"),
	},
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras)
		if items[1]:getWear() >= math.random(4) then
			return
		end
		
		local mat = dfhack.matinfo.decode(items[1])
		
		local item = pitems.CreateItem(mat, 'item_clothst', nil, 0)
		item:setDimension(10000)
		pitems.SetAutoItemQuality(wshop, item, items[1].quality)
		pitems.Eject(wshop, item)
	end,
})

preact.AddRecipe("DFHACK_POWERED_UNRAVELER", {
	validate = pfilter.MatFlag("LEATHER"),
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras)
		if items[1]:getWear() >= math.random(4) then
			return
		end
		
		-- Leather items have an additional 50% chance of failure
		if math.random(2) > 1 then
			return
		end
		
		local mat = dfhack.matinfo.decode(items[1])
		
		local item = pitems.CreateItem(mat, 'item_skin_tannedst', nil, 0)
		pitems.Eject(wshop, item)
	end,
})

pwshops.Register("DFHACK_POWERED_UNRAVELER", nil, 20, 0, 250, preact.MakeHandler("DFHACK_POWERED_UNRAVELER", {
	mangle_item = pdisaster.Switch({
		-- If the item is not hard then 1% chance of damage and rot it if possible, else pass it.
		{pfilter.Not(pfilter.MatFlag("ITEMS_HARD")), pdisaster.Damage(1, pdisaster.RotItem(pdisaster.PassItem))},
		
		-- Any other (invalid) item gives a 10% chance of damage, and the item is passed.
		{pfilter.Dummy, pdisaster.Damage(10, pdisaster.PassItem)},
	}),
	mangle_unit = pdisaster.MangleCreature,
}))
