
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local preact = rubble.require "reaction_libs_powered"

function isOre(mat)
	local products = {}
	
	if mat.material.flags.IS_STONE == true then
		-- METAL_ORE based smelting
		if #mat.inorganic.metal_ore.mat_index > 0 then
			for ore=0, #mat.inorganic.metal_ore.mat_index-1, 1 do
				ore_index = mat.inorganic.metal_ore.mat_index[ore]
				ore_prob = mat.inorganic.metal_ore.probability[ore]
				for p = 1, 4, 1 do
					if math.random(100) <= ore_prob then
						table.insert(products, dfhack.matinfo.decode(0, ore_index))
					end
				end
			end
		end
		
		-- Reaction Class based smelting
		local ores = {
			-- RC = inorganic,
			IRON_ORE = "IRON",
			NICKEL_ORE = "NICKEL",
			GOLD_ORE = "GOLD",
			SILVER_ORE = "SILVER",
			COPPER_ORE = "COPPER",
			LEAD_ORE = "LEAD",
			ZINC_ORE = "ZINC",
			TIN_ORE = "TIN",
			PLATINUM_ORE = "PLATINUM",
			BISMUTH_ORE = "BISMUTH",
			ALUMINUM_ORE = "ALUMINUM"
		}
		
		local rc = mat.material.reaction_class
		for k, v in ipairs(rc) do
			metal = ores[v.value]
			if metal ~= nil then
				local metalmat = dfhack.matinfo.find("INORGANIC:"..metal)
				table.insert(products, metalmat)
				table.insert(products, metalmat)
				table.insert(products, metalmat)
				table.insert(products, metalmat)
			end
		end
	end
	
	if #products ~= 0 then
		return products
	end
	return nil
end

preact.AddRecipe("DFHACK_POWERED_SMELTER", {
	validate = pfilter.Item("BOULDER:NONE", pfilter.Mat("INORGANIC:COAL_BITUMINOUS")),
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras)
		for i = 1, 9 do
			item = pitems.CreateItem(dfhack.matinfo.find("COAL:COKE"), 'item_barst', nil, 0)
			item:setDimension(150)
			pitems.Eject(wshop, item)
		end
	end,
})

preact.AddRecipe("DFHACK_POWERED_SMELTER", {
	validate = pfilter.Item("BOULDER:NONE", pfilter.Mat("INORGANIC:LIGNITE")),
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras)
		for i = 1, 5 do
			item = pitems.CreateItem(dfhack.matinfo.find("COAL:COKE"), 'item_barst', nil, 0)
			item:setDimension(150)
			pitems.Eject(wshop, item)
		end
	end,
})

preact.AddRecipe("DFHACK_POWERED_SMELTER", {
	validate = pfilter.Item("BOULDER:NONE", function(item)
		return isOre(dfhack.matinfo.decode(item)) ~= nil
	end),
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras)
		local products = isOre(dfhack.matinfo.decode(items[1]))
		
		for _, metal in ipairs(products) do
			item = pitems.CreateItem(metal, 'item_barst', nil, 0)
			item:setDimension(150)
			pitems.Eject(wshop, item)
		end
	end,
})

-- This allows you to just feed all boulders through the smelter without damage.
preact.AddRecipe("DFHACK_POWERED_SMELTER", {
	validate = pfilter.Item("BOULDER:NONE"),
	input_item = preact.DoNothing,
	output_item = preact.DoNothing,
})

pwshops.Register("DFHACK_POWERED_SMELTER", nil, 20, 0, 500, preact.MakeHandler("DFHACK_POWERED_SMELTER", {
	validate = preact.ValidateFuel,
	pre = preact.PreFuel,
	post = preact.PostFuel,
	
	mangle_item = pdisaster.Switch{
		-- If the item is metal, stone, or glass pass the item.
		{pfilter.Or{
			pfilter.MatFlag("IS_METAL"),
			pfilter.MatFlag("IS_STONE"),
			pfilter.MatFlag("IS_GLASS")
		}, pdisaster.Damage(10, pdisaster.PassItem)},
		
		-- Any other (invalid) item is burned to ash.
		{pfilter.Dummy, pdisaster.AshItem},
	},
	
	mangle_unit = pdisaster.MangleCreature,
	
	black_list = preact.BlackListFuel,
}))
