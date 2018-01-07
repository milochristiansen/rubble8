
local eventful = require "plugins.eventful"
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local preact = rubble.require "reaction_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"

alreadyAdjusting = false
function furnaceAdjust(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
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
			local mats = {"GREEN", "CLEAR"}
			
			local matok, mat = script.showListPrompt('Glass Furnace', 'Select material:', COLOR_LIGHTGREEN, mats)
			local choiceok, choice = script.showListPrompt('Glass Furnace', 'Select item to produce:', COLOR_LIGHTGREEN, opt_names)
			
			local product = "NONE"
			if choiceok and matok then
				-- Some a**hole messes with the table passed into script.showListPrompt
				product = opt_types[choice]..", mat = \""..mats[mat].text.."\""
			end
			
			local wshop = pwshops.MakeFake(unit.pos.x, unit.pos.y, unit.pos.z, 3)
			ppersist.SetOutputType(wshop, "return {"..product.."}")
			
			alreadyAdjusting = false
		end)
	end
end

eventful.registerReaction("ADJUST_POWERED_GLASS_FURNACE", furnaceAdjust)

local sanditem = function(item)
	return item:isSand()
end

preact.AddRecipe("DFHACK_POWERED_GLASS_FURNACE", {
	validate = pfilter.Contains(sanditem),
	input_item = function(items, wshop, extras)
		local sand = pitems.FindItemIn(items[1], sanditem)
		dfhack.items.remove(sand)
		pitems.Eject(wshop, items[1])
	end,
	output_item = function(items, wshop, extras)
		local glass = dfhack.matinfo.find("GLASS_"..extras.output.mat..":NONE")
		item = pitems.CreateItemNumeric(glass, extras.output.itype, extras.output.isubtype, nil, 0)
		pitems.SetAutoItemQuality(wshop, item)
		pitems.Eject(wshop, item)
	end,
})

pwshops.Register("DFHACK_POWERED_GLASS_FURNACE", nil, 20, 0, 500, preact.MakeHandler("DFHACK_POWERED_GLASS_FURNACE", {
	validate = function(wshop, extra)
		local output = ppersist.GetOutputTypeAsCode(wshop)
		if output == nil then
			return false
		end
		
		if output.mat == "CLEAR" then
			pearlash = pitems.FindItemAtInput(wshop, pfilter.Item("BAR:NONE", pfilter.Mat("PEARLASH:NONE")))
			if pearlash == nil then
				return false
			end
		end
		
		return preact.ValidateFuel(wshop, extra)
	end,
	
	pre = function(wshop, extra)
		local output = ppersist.GetOutputTypeAsCode(wshop)
		if output == nil then
			return nil
		end
		
		local pearlash = nil
		if output.mat == "CLEAR" then
			pearlash = pitems.FindItemAtInput(wshop, pfilter.Item("BAR:NONE", pfilter.Mat("PEARLASH:NONE")))
		end
		
		return {
			fuel = preact.PreFuel(wshop, extra),
			perlash = pearlash,
			output = output,
		}
	end,
	
	post = function(wshop, extra)
		preact.PostFuel(wshop, extra.fuel)
		
		if extra.perlash ~= nil then
			dfhack.items.remove(extra.perlash)
		end
	end,
	
	mangle_item = pdisaster.Switch{
		-- If the item is metal, glass, stone, or gem 10% chance to damage the factory and pass the item.
		{pfilter.Or{
			pfilter.MatFlag("IS_METAL"),
			pfilter.MatFlag("IS_STONE"),
			pfilter.MatFlag("IS_GLASS"),
			pfilter.MatFlag("IS_GEM")
		}, pdisaster.Damage(10, pdisaster.PassItem)},
		
		-- Any other (invalid) item gives a 5% chance of damage, and the item is burned to ash.
		{pfilter.Dummy, pdisaster.Damage(5, pdisaster.AshItem)},
	},
	
	mangle_unit = pdisaster.MangleCreature,
	
	black_list = pfilter.Or{pfilter.Item("BAR:NONE", pfilter.Mat("PEARLASH:NONE")), preact.BlackListFuel},
}))
