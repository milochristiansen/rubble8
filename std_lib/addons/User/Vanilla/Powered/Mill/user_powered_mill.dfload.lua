
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local preact = rubble.require "reaction_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"

function makepowder(powder)
	return function(items, wshop, extra)
		local mat = pitems.GetMRP(powder, dfhack.matinfo.decode(items[1]))
		local nitem = pitems.CreateItem(mat, 'item_powder_miscst', nil, 0)
		nitem:setDimension(150)
		nitem.stack_size = items[1].stack_size
		
		if extra.jug ~= nil then
			dfhack.items.moveToContainer(nitem, extra.jug)
			pitems.Eject(wshop, extra.jug)
		else
			dfhack.items.moveToContainer(nitem, extra.bag)
			pitems.Eject(wshop, extra.bag)
		end
	end
end

-- This one needs to be first so glaze powder overrides sand (if you have those addons active)
-- This recipe is here because I am lazy and didn't want the hassle of making sure this recipe
-- and the next one got added in the correct order by their respective addons.
preact.AddRecipe("DFHACK_POWERED_MILL", {
	custom = {jug = true},
	validate = pfilter.Item("BOULDER:NONE", pfilter.MRP("BOULDER_MILL_JUG_MAT", nil)),
	input_item = preact.DestroyInputs,
	output_item = makepowder("POWERED_MILL_JUG_MAT"),
})

-- This recipe is here because I am lazy and didn't want the hassle of making sure this recipe
-- and the previous one got added in the correct order by their respective addons.
preact.AddRecipe("DFHACK_POWERED_MILL", {
	custom = {jug = false},
	validate = pfilter.Item("BOULDER:NONE", pfilter.MRP("BOULDER_MILL_MAT", nil)),
	input_item = preact.DestroyInputs,
	output_item = makepowder("POWERED_MILL_MAT"),
})

-- This recipe will grind any millable plant.
-- Seed output (if needed) is automatic.
preact.AddRecipe("DFHACK_POWERED_MILL", {
	custom = {jug = false},
	validate = pfilter.Item("PLANT:NONE", function(item)
		local mat = dfhack.matinfo.decode(item)
		if mat.plant.material_defs.type_mill ~= -1 then
			return true
		end
		return false
	end),
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extra)
		local pmat = dfhack.matinfo.decode(items[1])
		ssize = items[1].stack_size
		
		local smat = dfhack.matinfo.decode(pmat.plant.material_defs.type_seed, pmat.plant.material_defs.idx_seed)
		if smat ~= nil then
			for i = 1, ssize, 1 do
				pitems.Eject(wshop, pitems.CreateItem(smat, 'item_seedsst', nil, 0))
			end
		end
		
		mat = dfhack.matinfo.decode(pmat.plant.material_defs.type_mill, pmat.plant.material_defs.idx_mill)
		local nitem = pitems.CreateItem(mat, 'item_powder_miscst', nil, 0)
		nitem:setDimension(150)
		nitem.stack_size = ssize
		dfhack.items.moveToContainer(nitem, extra.bag)
		pitems.Eject(wshop, extra.bag)
	end,
})

-- Any other item that cannot rot is ground into powder and stuffed in a bag.
-- (other items are rotted by the item mangler first)
preact.AddRecipe("DFHACK_POWERED_MILL", {
	custom = {jug = false},
	validate = pfilter.Not(pfilter.Rots()),
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extra)
		local mat = pitems.GetMRP(powder, dfhack.matinfo.decode(items[1]))
		local nitem = pitems.CreateItem(mat, 'item_powder_miscst', nil, 0)
		nitem:setDimension(150)
		nitem.stack_size = items[1].stack_size
		
		dfhack.items.moveToContainer(nitem, extra.bag)
		pitems.Eject(wshop, extra.bag)
	end,
})

pwshops.Register("DFHACK_POWERED_MILL", nil, 20, 0, 500, preact.MakeHandler("DFHACK_POWERED_MILL", {
	custom = {jug = false},
	validate = function(wshop, extra)
		if not extra.jug then
			local bag = pitems.FindItemAtInput(wshop, pfilter.Bag(pfilter.Empty()))
			if bag == nil then
				return false
			end
		else
			local jug = pitems.FindItemAtInput(wshop, pfilter.Jug(pfilter.Empty()))
			if jug == nil then
				return false
			end
		end
		return true
	end,
	
	pre = function(wshop, extra)
		local bag = nil
		local jug = nil
		if not extra.jug then
			bag = pitems.FindItemAtInput(wshop, pfilter.Bag(pfilter.Empty()))
		else
			jug = pitems.FindItemAtInput(wshop, pfilter.Jug(pfilter.Empty()))
		end
		
		return {
			bag = bag,
			jug = jug,
		}
	end,
	
	-- Rots the item or passes it.
	-- (In practice no items should ever pass)
	mangle_item = pdisaster.RotItem(pdisaster.PassItem),
	
	mangle_unit = pdisaster.MangleCreature,
	
	black_list = pfilter.Or{
		pfilter.Bag(),
		pfilter.Jug(),
	},
}))
