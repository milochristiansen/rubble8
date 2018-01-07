
local eventful = require "plugins.eventful"
local script = require 'gui.script'

local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local ppersist = rubble.require "persist_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local preact = rubble.require "reaction_libs_powered"

alreadyAdjusting = false
function clothierAdjust(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
	call_native.value = false
	
	if alreadyAdjusting == false then
		alreadyAdjusting = true
		
		local opt_types = {}
		local opt_names = {}
		
		for i = 0, #reaction.products-1, 1 do
			option = reaction.products[i]
			table.insert(opt_types, "itype = "..option.item_type..", isubtype = "..option.item_subtype)
			table.insert(opt_names, pitems.GetItemCaption(option.item_type, option.item_subtype))
		end
		
		script.start(function()
			local choiceok, choice = script.showListPrompt('Clothier', 'Select item to produce:', COLOR_LIGHTGREEN, opt_names)
			
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

preact.AddRecipe("DFHACK_POWERED_CLOTHIER", {
	validate = pfilter.Or{pfilter.Item("CLOTH:NONE"), pfilter.Item("SKIN_TANNED:NONE")},
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras)
		local output = ppersist.GetOutputTypeAsCode(wshop)
		if output == nil then
			return
		end
		
		local mat = dfhack.matinfo.decode(items[1])
		
		local threadimp = nil
		for r = #items[1].improvements-1, 0, -1 do
			if getmetatable(items[1].improvements[r]) == 'itemimprovement_threadst' then
				threadimp = items[1].improvements[r]
				break
			end
		end
		local adddye = function(item)
			if threadimp ~= nil then
				improvement = df.itemimprovement_threadst:new()
				improvement.mat_type = threadimp.mat_type
				improvement.mat_index = threadimp.mat_index
				improvement.dye.mat_type = threadimp.dye.mat_type
				improvement.dye.mat_index = threadimp.dye.mat_index
				improvement.dye.quality = threadimp.dye.quality
				item.improvements:insert('#',improvement)
			end
		end
		
		-- Gloves
		if df.item_type[output.itype] == "GLOVES" then
			local q = pitems.AutoQuality(wshop)
			
			local item = pitems.CreateItemClothing(mat, output.itype, output.isubtype, nil, 0)
			item:setQuality(q)
			item:setGloveHandedness(1)
			adddye(item)
			pitems.Eject(wshop, item)
			
			item = pitems.CreateItemClothing(mat, output.itype, output.isubtype, nil, 0)
			item:setQuality(q)
			item:setGloveHandedness(2)
			adddye(item)
			pitems.Eject(wshop, item)
			return
		end
		
		-- Shoes
		if df.item_type[output.itype] == "SHOES" then
			local q = pitems.AutoQuality(wshop)
			
			local item = pitems.CreateItemClothing(mat, output.itype, output.isubtype, nil, 0)
			item:setQuality(q)
			adddye(item)
			pitems.Eject(wshop, item)
			
			item = pitems.CreateItemClothing(mat, output.itype, output.isubtype, nil, 0)
			item:setQuality(q)
			adddye(item)
			pitems.Eject(wshop, item)
			return
		end
		
		-- Everything else
		local item = pitems.CreateItemClothing(mat, output.itype, output.isubtype, nil, 0)
		pitems.SetAutoItemQuality(wshop, item)
		adddye(item)
		pitems.Eject(wshop, item)
	end,
})

pwshops.Register("DFHACK_POWERED_CLOTHIER", nil, 30, 0, 500, preact.MakeHandler("DFHACK_POWERED_CLOTHIER", {
	mangle_item = pdisaster.Switch({
		-- If the item is metal 10% chance to damage the factory and pass the item.
		{pfilter.MatFlag("IS_METAL"), pdisaster.Damage(10, pdisaster.PassItem)},
		
		-- If the item is not hard then 1% chance of damage and rot it if possible, else pass it.
		{pfilter.Not(pfilter.MatFlag("ITEMS_HARD")), pdisaster.Damage(1, pdisaster.RotItem(pdisaster.PassItem))},
		
		-- Any other (invalid) item gives a 5% chance of damage, and the item is passed
		{pfilter.Dummy, pdisaster.Damage(5, pdisaster.PassItem)},
	}),
	mangle_unit = pdisaster.MangleCreature,
}))

eventful.registerReaction("ADJUST_POWERED_CLOTHIER", clothierAdjust)
