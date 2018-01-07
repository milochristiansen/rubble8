
local eventful = require "plugins.eventful"
local script = require 'gui.script'

local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local ppersist = rubble.require "persist_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local preact = rubble.require "reaction_libs_powered"

alreadyAdjusting = false
function assemblerAdjust(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
	call_native.value = false
	
	if alreadyAdjusting == false then
		alreadyAdjusting = true
		
		local opt_types = {}
		local opt_names = {}
		
		for i = 0, #reaction.products-1, 1 do
			option = reaction.products[i]
			table.insert(opt_types, "itype = "..option.item_type..", isubtype = "..option.item_subtype..", barcount = "..option.count)
			table.insert(opt_names, pitems.GetItemCaption(option.item_type, option.item_subtype))
		end
		
		script.start(function()
			local choiceok, choice = script.showListPrompt('Metal Press', 'Select item to produce:', COLOR_LIGHTGREEN, opt_names)
			
			local product = ""
			if choiceok then
				product = opt_types[choice]
			else
				product = "NONE"
			end
			
			local wshop = pwshops.MakeFake(unit.pos.x, unit.pos.y, unit.pos.z, 1)
			ppersist.SetOutputType(wshop, "return {"..product.."}")
			
			alreadyAdjusting = false
		end)
	end
end

local make_item = function(items, wshop, extras)
	local output = ppersist.GetOutputTypeAsCode(wshop)
	if output == nil then
		return
	end
	
	local mat = dfhack.matinfo.decode(items[1])
	
	-- Gloves
	if df.item_type[output.itype] == "GLOVES" then
		local q = pitems.AutoQuality(wshop)
		
		local item = pitems.CreateItemClothing(mat, output.itype, output.isubtype, nil, 0)
		item:setQuality(q)
		item:setGloveHandedness(1)
		pitems.Eject(wshop, item)
		
		item = pitems.CreateItemClothing(mat, output.itype, output.isubtype, nil, 0)
		item:setQuality(q)
		item:setGloveHandedness(2)
		pitems.Eject(wshop, item)
		return
	end
	
	-- Shoes
	if df.item_type[output.itype] == "SHOES" then
		local q = pitems.AutoQuality(wshop)
		
		local item = pitems.CreateItemClothing(mat, output.itype, output.isubtype, nil, 0)
		item:setQuality(q)
		pitems.Eject(wshop, item)
		
		item = pitems.CreateItemClothing(mat, output.itype, output.isubtype, nil, 0)
		item:setQuality(q)
		pitems.Eject(wshop, item)
		return
	end
	
	-- Needed so armor creation works.
	local item = pitems.CreateItemClothing(mat, output.itype, output.isubtype, nil, 0)
	pitems.SetAutoItemQuality(wshop, item)
	pitems.Eject(wshop, item)
end

local not_wafers = function(item)
	local mat = dfhack.matinfo.decode(item)
	if mat.mode == "inorganic" then
		return not mat.inorganic.flags.WAFERS
	end
	return true
end

preact.AddRecipe("DFHACK_POWERED_METAL_PRESS", {
	custom = {count = 1},
	validate = pfilter.Item("BAR:NONE", pfilter.MatFlag("IS_METAL", not_wafers)),
	input_item = preact.DestroyInputs,
	output_item = make_item,
})

preact.AddRecipe("DFHACK_POWERED_METAL_PRESS", {
	custom = {count = 2},
	validate = pfilter.Item("BAR:NONE", pfilter.MatFlag("IS_METAL", not_wafers)),
	amount = 2,
	input_item = preact.DestroyInputs,
	output_item = make_item,
})

preact.AddRecipe("DFHACK_POWERED_METAL_PRESS", {
	custom = {count = 3},
	validate = pfilter.Item("BAR:NONE", pfilter.MatFlag("IS_METAL", not_wafers)),
	amount = 3,
	input_item = preact.DestroyInputs,
	output_item = make_item,
})

preact.AddRecipe("DFHACK_POWERED_METAL_PRESS", {
	custom = {count = 4},
	validate = pfilter.Item("BAR:NONE", pfilter.MatFlag("IS_METAL", not_wafers)),
	amount = 4,
	input_item = preact.DestroyInputs,
	output_item = make_item,
})

preact.AddRecipe("DFHACK_POWERED_METAL_PRESS", {
	custom = {count = 5},
	validate = pfilter.Item("BAR:NONE", pfilter.MatFlag("IS_METAL", not_wafers)),
	amount = 5,
	input_item = preact.DestroyInputs,
	output_item = make_item,
})

pwshops.Register("DFHACK_POWERED_METAL_PRESS", nil, 30, 0, 500, preact.MakeHandler("DFHACK_POWERED_METAL_PRESS", {
	-- This disables all the recipes except the one that matches the needed bar count for the current product.
	validate = function(wshop, extra)
		local output = ppersist.GetOutputTypeAsCode(wshop)
		if output == nil then
			return false
		end
		
		return extra.count == output.barcount
	end,
	
	mangle_item = pdisaster.Switch({
		-- If the item is not hard then 1% chance of damage and rot it if possible, else pass it.
		{pfilter.Not(pfilter.MatFlag("ITEMS_HARD")), pdisaster.Damage(1, pdisaster.RotItem(pdisaster.PassItem))},
		
		-- Any other (invalid) item gives a 5% chance of damage, and the item is passed.
		{pfilter.Dummy, pdisaster.Damage(5, pdisaster.PassItem)},
	}),
	mangle_unit = pdisaster.MangleCreature,
}))

eventful.registerReaction("ADJUST_POWERED_METAL_PRESS", assemblerAdjust)
