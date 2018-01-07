
--[[
Rubble Fluids DFHack Lua Pseudo Module

Copyright 2014 Milo Christiansen

This software is provided 'as-is', without any express or implied warranty. In
no event will the authors be held liable for any damages arising from the use of
this software.

Permission is granted to anyone to use this software for any purpose, including
commercial applications, and to alter it and redistribute it freely, subject to
the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim
that you wrote the original software. If you use this software in a product, an
acknowledgment in the product documentation would be appreciated but is not
required.

2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution.
]]

-- Rubble pseudo module syntax
local _ENV = rubble.mkmodule("libs_fluids")

-- Returns true if the specified tile is downward passable (to flows).
function passableDown(x, y, z)
	ttype = dfhack.maps.getTileType(x, y, z)
	tshape = df.tiletype.attrs[ttype].shape
	return df.tiletype_shape.attrs[tshape].passable_flow_down
end

-- Eat fluid from the specified tile, returns true if it succeeds.
function eatFluid(x, y, z, magma, amount, minimum)
	local block = dfhack.maps.ensureTileBlock(x,y,z)
	
	if block.designation[x%16][y%16].flow_size >= minimum then
		if block.designation[x%16][y%16].liquid_type == magma then
			block.designation[x%16][y%16].flow_size = block.designation[x%16][y%16].flow_size - amount
		else
			return false
		end
	else
		return false
	end
	
	dfhack.maps.enableBlockUpdates(block,true,true)
	return true
end

-- Eat from below a specified area, there needs to be access to the fluid via a downward passable tile.
function eatFromArea(x1, y1, x2, y2, z, magma, amount, minimum)
	for cx = x1, x2, 1 do
		for cy = y1, y2, 1 do
			if passableDown(cx, cy, z) then
				if eatFluid(cx, cy, z-1, magma, amount, minimum) then
					return true
				end
			end
		end
	end
	return false
end

-- Check if there is enough fluid of the correct type in the specified tile.
function checkFluid(x, y, z, magma, amount, minimum)
	local block = dfhack.maps.ensureTileBlock(x,y,z)
	
	if block.designation[x%16][y%16].flow_size >= minimum then
		if block.designation[x%16][y%16].liquid_type == magma then
			return true
		else
			return false
		end
	end
	return false
end

-- Check if there is enough fluids of the correct type below a specified area.
function checkInArea(x1, y1, x2, y2, z, magma, amount, minimum)
	for cx = x1, x2, 1 do
		for cy = y1, y2, 1 do
			if passableDown(cx, cy, z) then
				if checkFluid(cx, cy, z-1, magma, amount, minimum) then
					return true
				end
			end
		end
	end
	return false
end

-- spawn fluid, returns true if the fluid could be spawned
function spawnFluid(x, y, z, magma, amount)
	local block = dfhack.maps.ensureTileBlock(x,y,z)
	
	local ttype = block.tiletype[x%16][y%16]
	local tshape = df.tiletype.attrs[ttype].shape
	if not df.tiletype_shape.attrs[tshape].passable_flow then
		return false
	end
	
	if amount > 7 then
		amount = 7
	end
	
	local flow = block.designation[x%16][y%16].flow_size
	if flow == 7 or flow + amount > 7 then
		return false
	end
	
	if flow ~= 0 then
		if block.designation[x%16][y%16].liquid_type ~= magma then
			return false
		end
	end
	
	block.designation[x%16][y%16].flow_size = flow + amount
	block.designation[x%16][y%16].liquid_type = magma
	dfhack.maps.enableBlockUpdates(block, true, true)
	return true
end

-- Spawn below a specified area, there needs to be access via a downward passable tile
function spawnInArea(x1, y1, x2, y2, z, magma, amount)
	for cx = x1, x2, 1 do
		for cy = y1, y2, 1 do
			if passableDown(cx, cy, z) then
				if spawnFluid(cx, cy, z-1, magma, amount) then
					return true
				end
			end
		end
	end
	return false
end

-- Returns true if item is magma safe.
function magmaSafe(item)
	-- Should work, but always returns false, not sure what's wrong.
	--item:isTemperatureSafe(2)
	
	-- Not sure if all this is required, but better safe than sorry.
	local mat = dfhack.matinfo.decode(item)
	if mat.material.heat.heatdam_point > 12000 and
	mat.material.heat.melting_point > 12000 and
	mat.material.heat.ignite_point > 12000 and
	mat.material.heat.boiling_point > 12000 then
		return true
	end
	return false
end

-- Find an empty (possibly magma safe) cart in the specified tile
function findCart(x, y, z, magmasafe)
	local itemblock = dfhack.maps.ensureTileBlock(x, y, z)
	if itemblock.occupancy[x%16][y%16].item == true then
		for c=#itemblock.items-1,0,-1 do
			cart=df.item.find(itemblock.items[c])
			if cart:isTrackCart() then
				if cart.pos.x == x and cart.pos.y == y and cart.pos.z == z then
					if #dfhack.items.getContainedItems(cart) == 0 then
						if magmasafe then
							if magmaSafe(cart) then
								return cart
							end
						else
							return cart
						end
					end
				end
			end
		end
	end
	return nil
end

-- Find a empty (possibly magma safe) cart in the specified area.
function findCartArea(x1, y1, x2, y2, z, magmasafe)
	for cx = x1, x2, 1 do
		for cy = y1, y2, 1 do
			cart = findCart(cx, cy, z, magmasafe)
			if cart ~= nil then
				return cart
			end
		end
	end
	return nil
end

-- Fill a minecart with magma or water.
function fillCart(cart, magma)
	capacity = math.floor(cart.subtype.container_capacity/60)
	
	local item=df['item_liquid_miscst']:new()
	item.id=df.global.item_next_id
	df.global.world.items.all:insert('#',item)
	df.global.item_next_id=df.global.item_next_id+1
	
	local mat
	if magma then
		mat = dfhack.matinfo.find("INORGANIC:NONE")
		-- This keeps the magma from becoming solid after a few seconds
		-- apparently items start out at the default room temperature.
		item.temperature.whole = 12000
	else
		mat = dfhack.matinfo.find("WATER:NONE")
	end
	
	item:setMaterial(mat.type)
	item:setMaterialIndex(mat.index)
	item.stack_size = capacity
	item:categorize(true)
	item.flags.removed=true
	
	dfhack.items.moveToContainer(item, cart)
end

-- This should add skill exp to a unit
-- doesn't seem to fit the theme until you consider just how often this lib gets used from Lua hooks
-- (and AFAIK Lua hooks do not award exp for completed reactions)
-- This is lifted (almost) directly from the machina script from Masterwork
function levelUp(unit, skillId, amount)
	max_skill = 20 
	
	local skill = df.unit_skill:new()
	local foundSkill = false
	for k, soulSkill in ipairs(unit.status.current_soul.skills) do
		if soulSkill.id == skillId then
			skill = soulSkill
			foundSkill = true
			break
		end
	end
 
	if foundSkill then
		-- Let's not train beyond the max skill
		if skill.rating >= max_skill then
			return false
		end
 
		skill.experience = skill.experience + amount
		if skill.experience > 100 * skill.rating + 500 then
			skill.experience = skill.experience - (100 * skill.rating + 500)
			skill.rating = skill.rating + 1
		end
	else
		skill.id = skillId
		skill.experience = amount
		skill.rating = 0
		unit.status.current_soul.skills:insert('#',skill)
	end
	
	return true
end

return _ENV
