
local fluids = rubble.require "libs_fluids"
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local punits = rubble.require "units_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"

local build_list = rubble.require 'libs_change_build_list'

function makeLoadCart(output)
	return function(wshop)
		if pwshops.IsUnpowered(wshop) then
			return
		end
		
		local pos = pwshops.Area(wshop)
		
		if output == "WATER" then
			local cart = fluids.findCartArea(pos.x1, pos.y1, pos.x2, pos.y2, pos.z, false)
			if cart == nil then
				return
			end
			
			if not fluids.checkInArea(pos.x1, pos.y1, pos.x2, pos.y2, pos.z, false, 4, 4) then
				return
			end
			
			-- Handle carts of various sizes
			amount = math.floor(math.floor(cart.subtype.container_capacity/60)/7)
			if amount > 7 then amount = 7 end
			minimum = 4
			if minimum < amount then minimum = amount end
			
			fluids.eatFromArea(pos.x1, pos.y1, pos.x2, pos.y2, pos.z, false, amount, minimum)
			fluids.fillCart(cart, false)
		elseif output == "MAGMA" then
			local cart = fluids.findCartArea(pos.x1, pos.y1, pos.x2, pos.y2, pos.z, pos.z, true)
			if cart == nil then
				if pdisaster.EnabledItems then
					-- Will the cart melt or catch fire? Lets hope so!
					cart = fluids.findCartArea(pos.x1, pos.y1, pos.x2, pos.y2, pos.z, pos.z, false)
					if cart == nil then
						return
					end
				else
					return
				end
			end
			
			if not fluids.checkInArea(pos.x1, pos.y1, pos.x2, pos.y2, pos.z, true, 4, 4) then
				return
			end
			
			-- Handle carts of various sizes
			amount = math.floor(math.floor(cart.subtype.container_capacity/60)/7)
			if amount > 7 then amount = 7 end
			minimum = 4
			if minimum < amount then minimum = amount end
			
			fluids.eatFromArea(pos.x1, pos.y1, pos.x2, pos.y2, pos.z, true, amount, minimum)
			fluids.fillCart(cart, true)
		else
			local cart
			if pwshops.HasOutput(wshop) then
				cart = pitems.FindItemAt(pwshops.Outputs(wshop), function(item)
					return item:isTrackCart()
				end)
			else
				cart = pitems.FindItemArea(wshop, function(item)
					return item:isTrackCart()
				end)
			end
			if cart == nil then
				return
			end
			
			-- Get how full the cart is
			local totalvolume = 0
			local cartrefs = cart.general_refs
			for r = 0, #cartrefs - 1, 1 do
				if getmetatable(cartrefs[r])=="general_ref_contains_itemst" then
					totalvolume = totalvolume + df.item.find(cartrefs[r].item_id):getVolume()
				end
			end
			
			local item = pitems.FindItemAtInput(wshop, function(item)
				if totalvolume + item:getVolume() <= cart.subtype.container_capacity then
					return true
				end
				return false
			end)
			if item == nil then
				if pdisaster.EnabledUnits then
					-- Copied from the old Masterwork machina script.
					if cart.flags2.has_rider == false then
						local u = punits.FindAtInput(wshop)
						if u ~= nil then
							--Stun the unit
							u.counters.unconscious = 250
							
							--toss the unit into the minecart!
							u.pos.x = cart.pos.x
							u.pos.y = cart.pos.y
							u.pos.z = cart.pos.z
							u.riding_item_id = cart.id
							--u.flags3.exit_vehicle1 = true
							cart.flags2.has_rider = true
							cartref = df.general_ref_unit_riderst:new()
							cartref.unit_id = u.id
							
							duplicate = false
							cartrefs = cart.general_refs
							for r=0,#cartrefs-1,1 do
								if getmetatable(cartrefs[r])=="general_ref_unit_riderst" then
									if cartrefs[r].unit_id == u.id then 
										duplicate = true
										break
									end
								end
							end
							if duplicate == false then
								cart.general_refs:insert('#', cartref)
							end
						end
					end
				end
				return
			end
			
			dfhack.items.moveToContainer(item, cart)
		end
	end
end

local outputs = {
	"ITEMS",
	"WATER",
	"MAGMA"
}

build_list.ChangeBuilding("DFHACK_POWERED_CART_LOADER_ITEMS", "MACHINES", true)
build_list.ChangeBuilding("DFHACK_POWERED_CART_LOADER_ITEMS", "WORKSHOPS", false)
pwshops.Register("DFHACK_POWERED_CART_LOADER", outputs, 5, 0, 10, makeLoadCart, 1, 1, {240,0,7,0}, {254,0,7,0})
