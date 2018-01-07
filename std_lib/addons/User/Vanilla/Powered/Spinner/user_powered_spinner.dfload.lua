
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local preact = rubble.require "reaction_libs_powered"

preact.AddRecipe("DFHACK_POWERED_SPINNER", {
	validate = pfilter.Item("PLANT:NONE", function(item)
		local mat = dfhack.matinfo.decode(item)
		return mat.plant.material_defs.type_thread ~= -1
	end),
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras)
		local pmat = dfhack.matinfo.decode(items[1])
		ssize = items[1].stack_size
		
		local smat = dfhack.matinfo.decode(pmat.plant.material_defs.type_seed, pmat.plant.material_defs.idx_seed)
		if smat ~= nil then
			for i = 1, ssize, 1 do
				pitems.Eject(wshop, pitems.CreateItem(smat, 'item_seedsst', nil, 0))
			end
		end
		
		local mat = dfhack.matinfo.decode(pmat.plant.material_defs.type_thread, pmat.plant.material_defs.idx_thread)
		for i = 1, ssize, 1 do
			local item = pitems.CreateItem(mat, 'item_threadst', nil, 0)
			item:setDimension(15000)
			pitems.Eject(wshop, item)
		end
	end,
})

pwshops.Register("DFHACK_POWERED_SPINNER", nil, 20, 0, 500, preact.MakeHandler("DFHACK_POWERED_SPINNER", {
	mangle_item = pdisaster.Switch({
		-- If the item is not hard then 1% chance of damage and rot it if possible, else pass it.
		{pfilter.Not(pfilter.MatFlag("ITEMS_HARD")), pdisaster.Damage(1, pdisaster.RotItem(pdisaster.PassItem))},
		
		-- Any other (invalid) item gives a 10% chance of damage, and the item is passed.
		{pfilter.Dummy, pdisaster.Damage(10, pdisaster.PassItem)},
	}),
	mangle_unit = pdisaster.MangleCreature,
}))
