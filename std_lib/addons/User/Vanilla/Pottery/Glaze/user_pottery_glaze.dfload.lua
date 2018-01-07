
dfhack.pcall(function()
	local pitems = rubble.require "items_libs_dfhack_powered"
	local pfilter = rubble.require "filter_libs_dfhack_powered"
	local preact = rubble.require "reaction_libs_dfhack_powered"
	
	preact.AddRecipe("DFHACK_POWERED_MILL", {
		needs_jug = true,
		validate = pfilter.Item("BAR:NONE", pfilter.Mat("ASH:NONE", nil)),
		input_item = function(item, wshop, bag, jug, barrel)
			dfhack.items.remove(item)
		end,
		output_item = function(item, wshop, bag, jug, barrel)
			local mat = dfhack.matinfo.find("INORGANIC:ASH_GLAZE")
			local nitem = pitems.CreateItem(mat, 'item_powder_miscst', nil, 0)
			nitem:setDimension(150)
			nitem.stack_size = 3
			
			dfhack.items.moveToContainer(nitem, jug)
			pitems.Eject(wshop, jug)
		end,
	})
end)
