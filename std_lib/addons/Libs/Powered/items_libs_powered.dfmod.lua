
-- Powered Items: Finding, creating, outputting, and otherwise dealing with items.
_ENV = rubble.extendmodule("libs_items", "items_libs_powered")

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- 
-- Not all functions that will be in the module are listed in this file!
-- 
-- See "Libs/DFHack/Items" for more functions. This file contains only the custom powered workshop extensions to the
-- generic items module!
-- 
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


local pwshops = rubble.require "workshops_libs_powered"

local fluids = rubble.require "libs_fluids"

local fuelmat = dfhack.matinfo.find("COAL:COKE")

--[[
Looking at the Lua APIs it should be possible to make a "stockpile input" that takes items from any
adjacent stockpile using the following functions:

	dfhack.buildings.findAtTile
	dfhack.buildings.getStockpileContents

All I need to do is figure out the details.

I am not really sure if this is worth it, it would be cool, but easy to exploit.
]]

-- Find either adjacent magma or a bar of fuel on an input tile.
-- Returns magma, bar.
-- If magma is true bar will be nil, if magma is false bar will be either a bar of fuel or nil.
function FindFuel(wshop)
	local check = function(item)
		if df.item_type[item:getType()] == "BAR" then
			local mat = dfhack.matinfo.decode(item)
			if mat.type == fuelmat.type then
				return true
			end
		end
		return false
	end
	
	local pos = pwshops.Area(wshop)
	if fluids.checkInArea(pos.x1, pos.y1, pos.x2, pos.y2, pos.z, true, 4, 4) then
		return true, nil
	end
	
	return false, FindItemAtInput(wshop, check)
end

-- Finds an item adjacent to or on top of the workshop.
-- Returns an item or nil.
-- check should be a function that takes an item and returns true if it
-- is like the one you are looking for.
function FindItemArea(wshop, check)
	local apos = pwshops.Area(wshop)
	for cx = apos.x1, apos.x2, 1 do
		for cy = apos.y1, apos.y2, 1 do
			item = FindItemInTile(cx, cy, apos.z, check)
			if item ~= nil then
				return item
			end
		end
	end
	return nil
end

-- Finds a certain number of items adjacent to or on top of the workshop.
-- Returns a table containing the items or nil.
-- check should be a function that takes an item and returns true if it
-- is like the one you are looking for.
function FindXItemsArea(wshop, x, check)
	local items = {}
	local found = {}
	for i = 1, x, 1 do
		local item = FindItemArea(wshop, function(item)
			if found[item.id] == true then
				return false
			end
			
			return check(item)
		end)
		if item == nil then
			return nil
		end
		found[item.id] = true
		items[i] = item
	end
	return items
end

-- Find an item at one of the passed in locations.
-- check should be a function that takes an item and returns true if it
-- is like the one you are looking for.
-- The locations are checked in random order.
function FindItemAt(locs, check)
	-- I know a media player or two that needs this algorithm for their shuffle
	-- function (hearing the same song twice in a row sucks...)
	local order = {}
	for i = 1, #locs, 1 do
		order[i] = 1
	end
	for i = 1, #locs, 1 do
		local j = math.random(i)
		order[i] = order[j]
		order[j] = i
	end
	
	for _, i in pairs(order) do
		local item = FindItemInTile(locs[i].x, locs[i].y, locs[i].z, check)
		if item ~= nil then
			return item
		end
	end
	return nil
end

-- Finds a certain number of items at one of the passed in locations.
-- Returns a table containing the items or nil.
-- check should be a function that takes an item and returns true if it
-- is like the one you are looking for.
-- The locations are checked in random order.
function FindXItemsAt(locs, x, check)
	local items = {}
	local found = {}
	for i = 1, x, 1 do
		local item = FindItemAt(locs, function(item)
			if found[item.id] == true then
				return false
			end
			
			return check(item)
		end)
		if item == nil then
			return nil
		end
		found[item.id] = true
		items[i] = item
	end
	return items
end

-- Find an item on an adjacent input tile.
-- Checks all input tiles (in random order), not just the first one it finds.
-- Returns an item or nil
-- check should be a function that takes an item and returns true if it
-- is like the one you are looking for.
function FindItemAtInput(wshop, check)
	return FindItemAt(pwshops.Inputs(wshop), check)
end

-- Finds a certain number of items on adjacent input tiles.
-- Checks all input tiles (in random order), not just the first one it finds.
-- Returns a table containing the items or nil.
-- check should be a function that takes an item and returns true if it
-- is like the one you are looking for.
function FindXItemsAtInput(wshop, x, check)
	return FindXItemsAt(pwshops.Inputs(wshop), x, check)
end

ForbidOver = {}

-- Find the bottom of a shaft
local findBottom = function(x, y, z)
	local ttype = dfhack.maps.getTileType(x, y, z)
	if ttype == 32 or ttype == 1 then
		for depth = z - 1, 0, -1 do
			local ttype = dfhack.maps.getTileType(x, y, depth)
			if ttype ~= 32 and ttype ~= 1 then
				return depth
			end
		end
	end
	return z
end

-- Sets an item as forbidden if it is on an input (or will fall onto an input).
-- Keeps dwarves from stealing stuff from the middle of your production lines...
function ForbidIfNeeded(item)
	local z = findBottom(item.pos.x, item.pos.y, item.pos.z)
	
	if pwshops.InputAt(item.pos.x, item.pos.y, z) then
		item.flags.forbid = true
		return
	end
	
	if pwshops.BuildingsAt(item.pos.x, item.pos.y, z, ForbidOver) then
		item.flags.forbid = true
		return
	end
	item.flags.forbid = false
end

-- Allows an item to drop if over open space or a down slope.
function ProjectileIfNeeded(item)
	local ttype = dfhack.maps.getTileType(item.pos.x, item.pos.y, item.pos.z)
	if ttype == 32 or ttype == 1 then
		dfhack.items.makeProjectile(item)
	end
end

-- Put the item on one of the workshop's output tiles.
-- If there are no output tiles the item is placed in the workshop center.
-- If the item is to be placed on an input tile it will be forbidden.
-- If the item is to be placed over open space it will be allowed to fall.
-- If there is more than one output tile one will be chosen at random.
function Eject(wshop, item)
	local outputs = pwshops.Outputs(wshop)
	if #outputs == 0 then
		opos = pwshops.Center(wshop)
		dfhack.items.moveToGround(item, opos)
		return
	end
	
	dfhack.items.moveToGround(item, outputs[math.random(#outputs)])
	ForbidIfNeeded(item)
	ProjectileIfNeeded(item)
end

-- Set an item's quality based on the result from AutoQuality.
function SetAutoItemQuality(wshop, item, cap)
	item:setQuality(AutoQuality(wshop, cap))
end

-- Calculates an item quality based on the quality of the workshop's components
-- The quality will be equal to the average or one to two levels lower, with the
-- average being the most common and one lower the second most common. Masterwork
-- quality is impossible, so if your machine has all masterwork components it will
-- have a higher chance to produce exceptional items.
-- 
-- If components of the workshop are damaged the average damage level will be subtracted
-- from the quality.
-- 
-- This has no relation to the quality calculations used for workers, it is designed
-- to produce more consistent results (as befits a machine).
function AutoQuality(wshop, cap)
	if cap == nil or cap > 4 then
		cap = 4
	end
	
	local totalQuality = 0
	local totalWear = 0
	local partNumber = 0
	for i = 0, #wshop.contained_items - 1, 1 do
		ic = wshop.contained_items[i]
		-- Only take mechanisms and trap components into account
		if (ic.item:getType() == 66 or ic.item:getType() == 67) and ic.use_mode == 2 then
			partNumber = partNumber + 1
			totalQuality = totalQuality + ic.item.quality
			totalWear = totalWear + ic.item:getWear()
		end
	end
	
	local quality = 0
	local wear = 0
	if partNumber > 0 then
		quality = math.floor(totalQuality / partNumber)
		wear = math.floor(totalWear / partNumber)
	end
	
	
	if math.random(2) == 1 then
		quality = quality - 1
	end
	
	if math.random(5) == 1 then
		quality = quality - 1
	end
	
	quality = quality - wear
	
	if quality > cap then
		quality = cap
	end
	if quality < 0 then
		quality = 0
	end
	return quality
end

return _ENV