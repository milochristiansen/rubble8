
local eventful = require "plugins.eventful"
local script = require 'gui.script'
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local ppersist = rubble.require "persist_libs_powered"

local build_list = rubble.require 'libs_change_build_list'

alreadyAdjusting = false
function sorterAdjust(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
	call_native.value = false
	
	if alreadyAdjusting == false then
		alreadyAdjusting = true
		
		script.start(function()
			local itemok = false
			local itemtype, itemsubtype
			
			local adjust = script.showYesNoPrompt('Sorter Adjust', 'Sort by specific item type?', COLOR_LIGHTGREEN)
			if adjust == true then
				require('gui.materials').ItemTypeDialog{
					text = "Sort what item type?",
					item_filter = function() return true end,
					hide_none = true,
					on_select = script.mkresume(true),
					on_cancel = script.mkresume(false),
					on_close = script.qresume(nil)
				}:show()
				
				itemok, itemtype, itemsubtype = script.wait()
			end
			
			local matok = false
			local mattype, matindex
			adjust = script.showYesNoPrompt('Sorter Adjust', 'Sort by specific material?', COLOR_LIGHTGREEN)
			if adjust == true then
				matok, mattype, matindex = script.showMaterialPrompt('Sort','Sort what material?')
			end
			
			local ilimit = "0"
			adjust = script.showYesNoPrompt('Sorter Adjust', 'Set an output item limit?', COLOR_LIGHTGREEN)
			if adjust == true then
				_, ilimit = script.showInputPrompt('Sorter Ajust', 'How many items should be output before stopping (0 means no limit)?', COLOR_LIGHTGREEN, ilimit)
			end
			if tonumber(ilimit) == nil then
				ilimit = "0"
			end
			
			local area = script.showYesNoPrompt('Sorter Adjust', 'Take from area instead of inputs?', COLOR_LIGHTGREEN)
			if area then
				area = "true"
			else
				area = "false"
			end
			
			local invert = script.showYesNoPrompt('Sorter Adjust', 'Invert settings?', COLOR_LIGHTGREEN)
			if invert then
				invert = "true"
			else
				invert = "false"
			end
			
			local ipart = ""
			local mpart = ""
			if itemok then
				ipart = "itype = "..itemtype..", isubtype = "..itemsubtype
			else
				ipart = "itype = nil, isubtype = -1"
			end
			if matok then
				mpart = "mtype = "..mattype..", mindex = "..matindex
			else
				mpart = "mtype = nil, mindex = -1"
			end
			
			local wshop = pwshops.MakeFake(unit.pos.x, unit.pos.y, unit.pos.z, 1)
			ppersist.SetOutputType(wshop, "return {"..ipart..", "..mpart..", limit = "..ilimit..", invert = "..invert..", area = "..area.."}")
			
			alreadyAdjusting = false
		end)
	end
end

function makeSortItem()
	return function(wshop)
		
		local output = ppersist.GetOutputTypeAsCode(wshop)
		if output == nil then
			return
		end
		
		if not pwshops.HasOutput(wshop) then
			return
		end
		
		if output.limit > 0 then
			-- count items at outputs
			local icount = 0
			local outputs = pwshops.Outputs(wshop)
			for _, pos in pairs(outputs) do
				local itemblock = dfhack.maps.ensureTileBlock(pos.x, pos.y, pos.z)
				if itemblock.occupancy[pos.x%16][pos.y%16].item == true then
					for c = #itemblock.items - 1, 0, -1 do
						local item = df.item.find(itemblock.items[c])
						if item.pos.x == pos.x and item.pos.y == pos.y and item.pos.z == pos.z then
							icount = icount + 1
							if icount >= output.limit then
								return
							end
						end
					end
				end
			end
		end
		
		local matchitem = function(item)
			match = true
			if output.itype ~= nil then
				if item:getType() ~= output.itype then
					match = false
				end
				if output.isubtype ~= -1 then
					if item:getSubtype() ~= output.isubtype then
						match = false
					end
				end
			end
			
			if output.mtype ~= nil then
				local mat = dfhack.matinfo.decode(item)
				
				if mat.type ~= output.mtype or mat.index ~= output.mindex then
					match = false
				end
			end
			
			if output.invert then
				return not match
			end
			return match
		end
		
		local item = nil
		if output.area then
			item = pitems.FindItemArea(wshop, matchitem)
			if item == nil then
				return
			end
		else
			item = pitems.FindItemAtInput(wshop, matchitem)
			if item == nil then
				return
			end
		end
		
		pitems.Eject(wshop, item)
	end
end

build_list.ChangeBuilding("DFHACK_POWERED_SORTER", "MACHINES", true, "CUSTOM_SHIFT_S")
pwshops.Register("DFHACK_POWERED_SORTER", nil, 0, 0, 10, makeSortItem)
eventful.registerReaction("ADJUST_POWERED_SORTER", sorterAdjust)
