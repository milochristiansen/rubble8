
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local preact = rubble.require "reaction_libs_powered"

preact.AddRecipe("DFHACK_POWERED_WOOD_FURNACE", {
	validate = pfilter.Item("BLOCKS:NONE", pfilter.MatFlag("WOOD")),
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras, output)
		local mat
		if output == "ASH" then
			mat = dfhack.matinfo.find("ASH:NONE")
		else
			mat = dfhack.matinfo.find("COAL:CHARCOAL")
		end
		local item = pitems.CreateItem(mat, 'item_barst', nil, 0)
		item:setDimension(150)
		pitems.Eject(wshop, item)
	end,
})

-- Yes, a recipe based workshop with hardcoded output types, weird, but it works.
local outputs = {
	"CHARCOAL",
	"ASH",
}

pwshops.Register("DFHACK_POWERED_WOOD_FURNACE", outputs, 20, 0, 500, preact.MakeHandler("DFHACK_POWERED_WOOD_FURNACE", {
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
}))
