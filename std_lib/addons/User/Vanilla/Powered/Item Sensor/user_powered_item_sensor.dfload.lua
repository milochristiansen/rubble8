
local eventful = require "plugins.eventful"
local script = require 'gui.script'
local pwshops = rubble.require "workshops_libs_powered"
local ppersist = rubble.require "persist_libs_powered"
local pswitchable = rubble.require "switchable_libs_powered"

alreadyAdjusting = false
function itemSensorAdjust(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
	call_native.value = false
	
	if alreadyAdjusting == false then
		alreadyAdjusting = true
		
		script.start(function()
			local itemok = false
			local itemtype, itemsubtype
			
			local limit = "10"
			_, limit = script.showInputPrompt('Item Sensor Adjust', 'Trigger count:', COLOR_LIGHTGREEN, limit)
			if tonumber(limit) == nil then
				limit = "10"
			end
			
			local wshop = pwshops.MakeFake(unit.pos.x, unit.pos.y, unit.pos.z, 1)
			ppersist.SetOutputType(wshop, limit)
			
			alreadyAdjusting = false
		end)
	end
end

function makeItemSensor(typ)
	return function(wshop)
		local limit = tonumber(ppersist.GetOutputType(wshop))
		if limit == nil then
			return
		end
		
		local outputs = pswitchable.Switchables(wshop)
		if #outputs == 0 then
			return
		end
		
		local apos = pwshops.Area(wshop)
		local items = 0
		for cx = apos.x1, apos.x2, 1 do
			for cy = apos.y1, apos.y2, 1 do
				local itemblock = dfhack.maps.ensureTileBlock(cx, cy, apos.z)
				if itemblock.occupancy[cx%16][cy%16].item == true then
					for c = #itemblock.items - 1, 0, -1 do
						local item = df.item.find(itemblock.items[c])
						if item.pos.x == cx and item.pos.y == cy and item.pos.z == apos.z then
							items = items + 1
							if items >= limit then
								break
							end
						end
					end
				end
			end
		end
		
		local command = items < limit
		for _, output in ipairs(outputs) do
			pswitchable.SwitchBuilding(output, command)
		end
	end
end

pwshops.Register("DFHACK_POWERED_ITEM_SENSOR", nil, 0, 0, 500, makeItemSensor)

eventful.registerReaction("ADJUST_POWERED_ITEM_SENSOR", itemSensorAdjust)
