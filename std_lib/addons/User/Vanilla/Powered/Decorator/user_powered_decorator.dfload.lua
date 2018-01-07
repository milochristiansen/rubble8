
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local preact = rubble.require "reaction_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"

preact.AddRecipe("DFHACK_POWERED_DECORATOR", {
	validate = pfilter.Not(pfilter.Rots()),
	output_item = function(items, wshop, extras)
		local imp_mat = dfhack.matinfo.decode(extras.powder)
		local item = items[1]
		
		-- item:isImprovable does not seem to work for what I need, but this does.
		local ok = dfhack.pcall(function()
			local x = item.improvements
		end)
		if ok then
			local improvement = nil
			if extras.powder:isDye() == true then
				for r = #item.improvements-1, 0, -1 do
					if getmetatable(item.improvements[r]) == 'itemimprovement_threadst' then
						item.improvements:erase(r)
					end
				end
				
				improvement = df.itemimprovement_threadst:new()
				i_mat = dfhack.matinfo.decode(item)
				improvement.mat_type = i_mat.type
				improvement.mat_index = i_mat.index
				improvement.dye.mat_type = imp_mat.type
				improvement.dye.mat_index = imp_mat.index
				improvement.dye.quality = pitems.AutoQuality(wshop)
			else
				improvement = df.itemimprovement_coveredst:new()
				improvement.mat_type = imp_mat.type
				improvement.mat_index = imp_mat.index
				improvement.quality = pitems.AutoQuality(wshop)
			end
			
			improvement.quality = pitems.AutoQuality(wshop)
			item.improvements:insert('#',improvement)
		end
		
		pitems.Eject(wshop, item)
	end,
})

pwshops.Register("DFHACK_POWERED_DECORATOR", nil, 20, 0, 500, preact.MakeHandler("DFHACK_POWERED_DECORATOR", {
	validate = function(wshop, extra)
		return pitems.FindItemAtInput(wshop, pfilter.Contains(pfilter.Item("POWDER_MISC:NONE"))) ~= nil
	end,
	
	pre = function(wshop, extra)
		local bag = pitems.FindItemAtInput(wshop, pfilter.Contains(pfilter.Item("POWDER_MISC:NONE")))
		return {
			bag = bag,
			powder = pitems.FindItemIn(bag, pfilter.Item("POWDER_MISC:NONE"))
		}
	end,
	
	post = function(wshop, extra)
		if not pitems.TakeFromStack(extra.powder, 1) then
			pitems.Eject(wshop, extra.bag)
		end
	end,
	
	mangle_item = pdisaster.RotItem(pdisaster.PassItem),
	
	mangle_unit = pdisaster.MangleCreature,
	
	black_list = pfilter.Contains(pfilter.Item("POWDER_MISC:NONE")),
}))
