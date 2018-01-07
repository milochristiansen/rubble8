
local eventful = require 'plugins.eventful'

-- Remove the vanilla melt item job.
eventful.postWorkshopFillSidebarMenu.User_DFHack_Melt_Item = function(wshop)
	if wshop:getType() == df.building_type.Furnace then
		if wshop:getSubtype() == df.furnace_type.Smelter or wshop:getSubtype() == df.furnace_type.MagmaSmelter then
			local wjob = df.global.ui_sidebar_menus.workshop_job
			
			for i = 0, #wjob.choices_all - 1, 1 do
				if wjob.choices_all[i].job_type == df.job_type.MeltMetalObject then
					wjob.choices_all:delete(i)
					wjob.choices_visible:delete(i)
					return
				end
			end
		end
	end
end

function onUnload()
	eventful.postWorkshopFillSidebarMenu.User_DFHack_Melt_Item = nil
end

-- Add a melt item recipe to the powered smelter.
dfhack.pcall(function()
	local pitems = rubble.require "items_libs_dfhack_powered"
	local pfilter = rubble.require "filter_libs_dfhack_powered"
	local preact = rubble.require "reaction_libs_dfhack_powered"
	local melt = rubble.require "libs_dfhack_melt_item"
	
	preact.AddRecipe("DFHACK_POWERED_SMELTER", {
		validate = pfilter.MatFlag("IS_METAL"),
		input_item = preact.DestroyInputs,
		output_item = function(items, wshop, extras)
			local bars = melt.meltMetalItem(items[0])
			for _, bar in ipairs(bars) do
				pitems.Eject(wshop, bar)
			end
		end,
	})
end)


