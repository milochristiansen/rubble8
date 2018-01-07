
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
			table.insert(opt_types, "itype = "..option.item_type..", isubtype = "..option.item_subtype)
			table.insert(opt_names, pitems.GetItemCaption(option.item_type, option.item_subtype))
		end
		
		script.start(function()
			local choiceok, choice = script.showListPrompt('Assembler', 'Select item to produce:', COLOR_LIGHTGREEN, opt_names)
			
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

preact.AddRecipe("DFHACK_POWERED_ASSEMBLER", {
	validate = pfilter.Item("BLOCKS:NONE"),
	amount = 3,
	input_item = preact.DestroyInputs,
	output_item = function(blocks, wshop, extras)
		local output = ppersist.GetOutputTypeAsCode(wshop)
		if output == nil then
			return
		end
		
		local mat = dfhack.matinfo.decode(blocks[1])
		
		local item = pitems.CreateItemNumeric(mat, output.itype, output.isubtype, nil, 0)
		pitems.SetAutoItemQuality(wshop, item)
		pitems.Eject(wshop, item)
	end,
})

pwshops.Register("DFHACK_POWERED_ASSEMBLER", nil, 30, 0, 500, preact.MakeHandler("DFHACK_POWERED_ASSEMBLER", {
	mangle_item = pdisaster.Switch({
		-- If the item is metal 10% chance to damage the factory and pass the item.
		{pfilter.MatFlag("IS_METAL"), pdisaster.Damage(10, pdisaster.PassItem)},
		
		-- If the item is not hard then 1% chance of damage and rot it if possible, else pass it.
		{pfilter.Not(pfilter.MatFlag("ITEMS_HARD")), pdisaster.Damage(1, pdisaster.RotItem(pdisaster.PassItem))},
		
		-- Any other (invalid) item gives a 5% chance of damage, and the item is made into a base quality product.
		{pfilter.Dummy, pdisaster.Damage(5, function(wshop, item)
			local output = ppersist.GetOutputTypeAsCode(wshop)
			if output == nil then
				return nil
			end
			
			local mat = dfhack.matinfo.decode(item)
			dfhack.items.remove(item)
			local item = pitems.CreateItemNumeric(mat, output.itype, output.isubtype, nil, 0)
			pitems.Eject(wshop, item)
			return nil
		end)},
	}),
	mangle_unit = pdisaster.MangleCreature,
}))

eventful.registerReaction("ADJUST_POWERED_ASSEMBLER", assemblerAdjust)
