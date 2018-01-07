
local eventful = require "plugins.eventful"
local script = require 'gui.script'
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local ppersist = rubble.require "persist_libs_powered"

local build_list = rubble.require 'libs_change_build_list'

alreadyAdjusting = false
function launcherAdjust(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
	call_native.value = false
	
	if alreadyAdjusting == false then
		alreadyAdjusting = true
		
		script.start(function()
			local thold = "50"
			repeat
				_, thold = script.showInputPrompt('Minecart Launcher Adjust', 'Set how full the minecart needs to be (0-100)', COLOR_LIGHTGREEN, thold)
			until tonumber(thold) and tonumber(thold) >= 0 and tonumber(thold) <= 100
			
			local dirok, dir
			repeat
				dirok, dir = script.showListPrompt('Minecart Launcher Adjust', 'Select launch direction:', COLOR_LIGHTGREEN, {"N", "S", "E", "W"})
			until dirok
			
			local forbid = script.showYesNoPrompt('Minecart Launcher Adjust', 'Forbid cart on launch?', COLOR_LIGHTGREEN)
			if forbid then
				forbid = "true"
			else
				forbid = "false"
			end
			
			if thold ~= "0" then
				thold = tostring(tonumber(thold) / 100)
			end
			
			local launcher_dirs = {
				"vx = 0, vy = -20000", -- N
				"vx = 0, vy = 20000",  -- S
				"vx = 20000, vy = 0",  -- E
				"vx = -20000, vy = 0", -- W
			}
			
			local wshop = pwshops.MakeFake(unit.pos.x, unit.pos.y, unit.pos.z, 1)
			ppersist.SetOutputType(wshop, "return {"..launcher_dirs[dir]..", threshold = "..thold..", forbid = "..forbid.."}")
			
			alreadyAdjusting = false
		end)
	end
end

function makeLaunchCart()
	return function(wshop)
		if pwshops.IsUnpowered(wshop) then
			return
		end
		
		-- Read settings
		local output = ppersist.GetOutputTypeAsCode(wshop)
		if output == nil then
			return
		end
		
		local check = function(item)
			if item:isTrackCart() then
				local cart_capacity = item.subtype.container_capacity
				local totalvolume = 0
				local cartrefs = item.general_refs
				for r = 0, #cartrefs - 1, 1 do
					if getmetatable(cartrefs[r])=="general_ref_contains_itemst" then
						totalvolume = totalvolume + df.item.find(cartrefs[r].item_id):getVolume()
					end
				end
				
				--print(totalvolume.."|"..cart_capacity.."|"..(cart_capacity * output.threshold))
				if totalvolume >= (cart_capacity * output.threshold) then
					return true
				end
			end
			return false
		end
		
		-- find cart
		local cart
		if pwshops.HasOutput(wshop) then
			cart = pitems.FindItemAt(pwshops.Outputs(wshop), check)
		else
			cart = pitems.FindItemArea(wshop, check)
		end
		if cart == nil then
			return
		end
		
		-- launch the cart
		local vehicle = df.vehicle.find(cart.vehicle_id)
		
		-- Launch!
		if vehicle.time_stopped > 0 then
			local x = cart.pos.x
			local y = cart.pos.y
			if output.vx < 0 then
				x = x - 1
			elseif output.vx > 0 then
				x = x + 1
			end
			if output.vy < 0 then
				y = y - 1
			elseif output.vy > 0 then
				y = y + 1
			end
			
			ttype = dfhack.maps.getTileType(x, y, cart.pos.z)
			tshape = df.tiletype.attrs[ttype].shape
			if not df.tiletype_shape.attrs[tshape].passable_high then
				--The tile we are supposed to be launching into is not passable...
				return
			end
			
			cart.pos.x = x
			cart.pos.y = y
			
			vehicle.speed_x = output.vx
			vehicle.speed_y = output.vy
			vehicle.speed_z = 0
			
			-- We want to be in the middle of the tile
			vehicle.offset_x = 0
			vehicle.offset_y = 0
			vehicle.offset_z = 0
			
			if output.forbid then
				cart.flags.forbid = true
			end
		end
	end
end

build_list.ChangeBuilding("DFHACK_POWERED_CART_LAUNCHER", "MACHINES", true)
pwshops.Register("DFHACK_POWERED_CART_LAUNCHER", nil, 5, 0, 50, makeLaunchCart, 1, 1)

eventful.registerReaction("ADJUST_POWERED_CART_LAUNCHER", launcherAdjust)
