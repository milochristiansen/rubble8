
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local preact = rubble.require "reaction_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"

function makedrink(drink)
	return function(items, wshop, extra)
		local pmat = dfhack.matinfo.decode(items[1])
		local mat = pitems.GetMRP(drink, pmat)
		local nitem = pitems.CreateItem(mat, 'item_drinkst', nil, 0)
		nitem:setDimension(150)
		nitem.stack_size = items[1].stack_size * 5
		
		dfhack.items.moveToContainer(nitem, extra.barrel)
		pitems.Eject(wshop, extra.barrel)
		
		if pmat.mode == "plant" and extra.seeds then
			local smat = dfhack.matinfo.decode(pmat.plant.material_defs.type_seed, pmat.plant.material_defs.idx_seed)
			if smat ~= nil then
				pitems.Eject(wshop, pitems.CreateItem(smat, 'item_seedsst', nil, 0))
			end
		end
	end
end

preact.AddRecipe("DFHACK_POWERED_STILL", {
	-- In a still recipe custom = true means to attempt to produce seeds as well.
	custom = true,
	validate = pfilter.Item("PLANT:NONE", pfilter.MRP("DRINK_MAT")),
	input_item = preact.DestroyInputs,
	output_item = makedrink("DRINK_MAT"),
})

preact.AddRecipe("DFHACK_POWERED_STILL", {
	custom = false,
	validate = pfilter.Item("PLANT_GROWTH:NONE", pfilter.MRP("DRINK_MAT")),
	input_item = preact.DestroyInputs,
	output_item = makedrink("DRINK_MAT"),
})

pwshops.Register("DFHACK_POWERED_STILL", nil, 20, 0, 500, preact.MakeHandler("DFHACK_POWERED_STILL", {
	validate = function(wshop, extra)
		local barrel = pitems.FindItemAtInput(wshop, pfilter.Barrel(pfilter.Empty()))
		if barrel == nil then
			return false
		end
		return true
	end,
	
	pre = function(wshop, extra)
		return {
			barrel = pitems.FindItemAtInput(wshop, pfilter.Barrel(pfilter.Empty())),
			seeds = extra
		}
	end,
	
	mangle_item = pdisaster.Switch{
		-- If the item is not hard then 1% chance of damage and rot it if possible, else pass it.
		{pfilter.Not(pfilter.MatFlag("ITEMS_HARD")), pdisaster.Damage(1, pdisaster.RotItem(pdisaster.PassItem))},
		
		-- Any other (invalid) item gives a 10% chance of damage, and the item is passed.
		{pfilter.Dummy, pdisaster.Damage(10, pdisaster.PassItem)},
	},
	
	mangle_unit = pdisaster.MangleCreature,
	
	black_list = pfilter.Barrel()
}))
