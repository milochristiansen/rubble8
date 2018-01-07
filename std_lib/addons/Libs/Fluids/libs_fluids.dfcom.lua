-- Do fun stuff with water and magma.

--[[
Rubble Fluids DFHack Command

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

local utils = require 'utils'
local fluids = rubble.require "libs_fluids"

validArgs = validArgs or utils.invert({
	'help',
	'action',
	'area',
	'type',
	'loc',
	'amount',
	'minimum',
})

local args = utils.processArgs({...}, validArgs)

if args.help then
	print([[scripts/rubble_fluids

Allows you to:
    Spawn fluids, either in a single tile or in any tile below a downward passable tile in an area.
    Eat fluids, either from a single tile or from any tile below a downward passable tile in an area.
    Fill a minecart with fluids, either in a single tile or in an area.

Arguments:
    -help
        print this help message.
    -action
        one of "spawn", "eat", or "cart" (defaults to "eat").
    -area
        one of "spot", "3x3", "5x5", or "7x7" (defaults to "spot").
    -type
        "magma" or "water" (default "magma").
    -loc [ x y z ]
        Where to do the action (defaults to cursor location).
    -amount
        How much to eat/spawn (default 4).
    -minimum
        How much is required to be present before eating is allowed (defaults to the amount).

Examples:
    spawn 4/7 magma at cursor
        rubble_fluids -action spawn
    eat 2/7 magma at cursor, but only if there is at least 4/7 there
        rubble_fluids -amount 2 -minimum 4
    fill the minecart at cursor with water
        rubble_fluids -action cart -type water
    fill the minecart at coords <x:10, y:20, z:30> with water
        rubble_fluids -action cart -type water -loc [ 10 20 30 ]
    eat 2/7 magma from the first tile below a 3x3 area around the cursor that is 
    downward-passable and has at least 2/7 magma
        rubble_fluids -area 3x3 -amount 2
]])
	return
end

local pos = df.coord:new();
if args.loc then
	pos.x = tonumber(args.loc[1] or 'a')
	pos.y = tonumber(args.loc[2] or 'a')
	pos.z = tonumber(args.loc[3] or 'a')
end
if not pos.x or not pos.y or not pos.z then
	pos = df.global.cursor
end
if pos.x == -30000 then
	error "Invalid position: Drop a cursor or specify coords on the command line."
end

local spawn = false
local tocart = false
if args.action == "spawn" then
	spawn = true
elseif args.action == "eat" then
	
elseif args.action == "cart" then
	tocart = true
end

local area = false
local offset = 1
if args.area == "3x3" then
	area = true
	offset = 1
elseif args.area == "5x5" then
	area = true
	offset = 2
elseif args.area == "7x7" then
	area = true
	offset = 3
end

local magma = true
if args.type == "water" then
	magma = false
end

local amount = args.amount or 4
local minimum = args.minimum or amount
if minimum < amount then
	minimum = amount
end

-- Do the requested operation.
if spawn then
	if area then
		if not fluids.spawnInArea(pos.x-offset, pos.y-offset, pos.x+offset, pos.y+offset, pos.z, magma, amount) then
			error "Failed to spawn fluid in area."
		end
		return
	end
	
	if not fluids.spawnFluid(pos.x, pos.y, pos.z, magma, amount) then
		error "Failed to spawn fluid."
	end
	return
elseif tocart then
	local cart
	if area then
		cart = fluids.findCartArea(pos.x-offset, pos.y-offset, pos.x+offset, pos.y+offset, pos.z, magma)
	else
		cart = fluids.findCart(pos.x, pos.y, pos.z, magma)
	end
	
	if cart == nil then
		error "No minecart at coords/in area."
	end
	
	fluids.fillCart(cart, magma)
else
	if area then
		if not fluids.eatFromArea(pos.x-offset, pos.y-offset, pos.x+offset, pos.y+offset, pos.z, magma, amount, minimum) then
			error "Failed to find enough fluid in area."
		end
		return
	end
	
	if not fluids.eatFluid(pos.x, pos.y, pos.z, magma, amount, minimum) then
		error "Failed to find enough fluid."
	end
	return
end
