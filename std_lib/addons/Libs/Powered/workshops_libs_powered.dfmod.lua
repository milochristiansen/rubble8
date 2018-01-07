
-- Powered Workshops: Registering workshops, finding input and output locations, etc.
_ENV = rubble.mkmodule("workshops_libs_powered")

-- building-hacks is not used directly in any other module.
-- (so a custom workshop plugin only needs to port this module to be automatically compatible with
--  *almost* all the workshops)
local buildings = require 'plugins.building-hacks'

local utils = require 'utils'

-- The names of any input and output workshops.
-- These should be non-mechanical single tile workshops.
-- You can add more than one type for each (I don't know why you would want to, but it is possible).
InputWorkshop = {"DFHACK_POWERED_INPUT"}
OutputWorkshop = {"DFHACK_POWERED_OUTPUT"}

-- Register a powered workshop.
-- 
-- The workshop may be any size rectangle, non-square workshops will work fine (and the other parts
-- of the API should also be smart enough to handle weird sizes without issues).
-- 
-- The corner tiles of the workshop are assumed to be animated gears (unless consume is <= 0).
-- For single tile workshops the only tile is treated like a corner tile.
-- 
-- By default workshops registered with this function do not need to be powered to run reactions.
-- 
-- This function will be suitable for the vast majority of powered workshops, but some odd types
-- may need to use building-hacks directly.
-- 
-- id is the building ID.
-- 
-- outputs is a table of name postfixes for variations of the same basic building (set to nil in
-- most cases). If outputs is NOT a table it is treated like it was an index in the outputs table,
-- this makes certain advanced uses easier (for example different action timings for each output).
-- 
-- consume is how much power to use.
-- 
-- produce is how much power to create.
-- 
-- if consume and produce are both <= 0 then the workshop is not mechanical (no animation or gears).
-- 
-- ticks is how often to run the function returned by makeaction.
-- 
-- makeaction is a function that takes one parameter (the output id) and returns a function to
-- handle the action. This function should take a single parameter as well, the workshop.
-- 
-- sizew and sizeh are how large the workshops is on a side, these are optional (and ignored if
-- workshop is not mechanical). If not specified these default to 3.
-- 
-- framea and frameb are animation frames for the corner tiles. These are optional (and ignored if
-- workshop is not mechanical). If not specified these default to looking like a gray gear assembly.
-- 
-- reactions_need_power if true forces the building to be powered before it can run reactions. Obviously
-- this only effects workshops that consume power.
function Register(id, outputs, consume, produce, ticks, makeaction, sizew, sizeh, framea, frameb, reactions_need_power)
	-- I am a little proud of this version of the Register function.
	-- Basically it takes the place of the two old functions *plus* several
	-- cases where I used building-hacks directly to do things that were not
	-- possible with the old functions.
	-- And the best part? This is just as easy to use as the old functions.
	
	if consume == nil or consume < 0 then
		consume = 0
	end
	
	if produce == nil or produce < 0 then
		produce = 0
	end
	
	if reactions_need_power == nil or not reactions_need_power then
		reactions_need_power = 0
	elseif reactions_need_power then
		reactions_need_power = 1
	end
	
	local animate = nil
	local gears = nil
	if consume > 0 or produce > 0 then
		if sizew == nil or sizew <= 0 then
			sizew = 3
		end
		if sizeh == nil or sizeh <= 0 then
			sizeh = 3
		end
		
		if framea == nil then
			framea = {15, 7,0,0}
		end
		
		if frameb == nil then
			frameb = {42, 7,0,0}
		end
		
		if sizew == 1 and sizeh == 1 then
			gears = {{x = 0, y = 0}}
			
			animate = {
				isMechanical = true,
				frames = {
					{
						{x = 0, y = 0, framea[1], framea[2], framea[3], framea[4]},
					},
					{
						{x = 0, y = 0, frameb[1], frameb[2], frameb[3], frameb[4]},
					},
				}
			}
		elseif sizew == 1 then
			local h = sizeh - 1
			
			gears = {{x = 0, y = 0}, {x = 0, y = h}}
			
			animate = {
				isMechanical = true,
				frames = {
					{
						{x = 0, y = 0, framea[1], framea[2], framea[3], framea[4]},
						{x = 0, y = h, framea[1], framea[2], framea[3], framea[4]},
					},
					{
						{x = 0, y = 0,frameb[1], frameb[2], frameb[3], frameb[4]},
						{x = 0, y = h,frameb[1], frameb[2], frameb[3], frameb[4]},
					},
				}
			}
		elseif sizeh == 1 then
			local w = sizew - 1
			
			gears = {{x = 0, y = 0}, {x = w, y = 0}}

			animate = {
				isMechanical = true,
				frames = {
					{
						{x = 0, y = 0, framea[1], framea[2], framea[3], framea[4]},
						{x = w, y = 0, framea[1], framea[2], framea[3], framea[4]},
					},
					{
						{x = 0, y = 0,frameb[1], frameb[2], frameb[3], frameb[4]},
						{x = w, y = 0,frameb[1], frameb[2], frameb[3], frameb[4]},
					},
				}
			}
		else
			local w = sizew - 1
			local h = sizeh - 1
			
			gears = {{x = 0, y = h}, {x = w, y = 0}, {x = w, y = h}, {x = 0, y = 0}}
			animate = {
				isMechanical = true,
				frames = {
					{
						{x = 0, y = h, framea[1], framea[2], framea[3], framea[4]},
						{x = w, y = 0, framea[1], framea[2], framea[3], framea[4]},
						{x = w, y = h, framea[1], framea[2], framea[3], framea[4]},
						{x = 0, y = 0, framea[1], framea[2], framea[3], framea[4]},
					},
					{
						{x = 0, y = h,frameb[1], frameb[2], frameb[3], frameb[4]},
						{x = w, y = 0,frameb[1], frameb[2], frameb[3], frameb[4]},
						{x = w, y = h,frameb[1], frameb[2], frameb[3], frameb[4]},
						{x = 0, y = 0,frameb[1], frameb[2], frameb[3], frameb[4]},
					},
				}
			}
		end
		
	end
	
	local register = function(output)
		-- Some a**hole modifies the animate table in-place instead of taking a copy.
		-- Of course that wouldn't be mentioned in the documentation, it might be useful...
		
		local cid = id
		local coutput = output
		if output == nil then
			coutput = ""
		else
			cid = cid.."_"..coutput
		end
		
		local action = nil
		if makeaction ~= nil and ticks > 0 then
			action = {ticks, makeaction(coutput)}
		end
		
		buildings.registerBuilding{
			name = cid,
			consume = consume,
			produce = produce,
			needs_power = reactions_need_power,
			gears = gears,
			action = action,
			animate = utils.clone(animate, true)
		}
	end
	
	if type(outputs) ~= 'table' then
		register(outputs)
	elseif #outputs == 0 then
		register(nil)
	else
		for _, output in pairs(outputs) do
			register(output)
		end
	end
end

-- Returns true if network required power < total network power.
-- This is a workaround for wshop:isUnpowered not working.
-- I am not sure if this is a problem with DFHack 40.24-r3 or if it is just my test fort,
-- but better safe than sorry.
function IsUnpowered(wshop)
	info = wshop:getMachineInfo()
	if info == nil then
		return true
	end
	machine = df.machine.find(info.machine_id)
	if machine == nil then
		return true
	end
	return machine.cur_power < machine.min_power
end

-- Returns true if there is a building at the location that is one of the specified types.
function BuildingsAt(x, y, z, types)
	-- Separate from BuildingAt to avoid multiple building lookups
	building = dfhack.buildings.findAtTile(x, y, z)
	if building ~= nil then
		if getmetatable(building) == "building_workshopst" then
			t = df.building_def.find(building.custom_type)
			if t ~= nil and t ~= -1 then
				for _, v in ipairs(types) do
					if t.code == v then
						return true
					end
				end
			end
		end
	end
	return false
end

-- Returns true if there is a building at the location that is the specified type.
function BuildingAt(x, y, z, typ)
	building = dfhack.buildings.findAtTile(x, y, z)
	if building ~= nil then
		if getmetatable(building) == "building_workshopst" then
			t = df.building_def.find(building.custom_type)
			if t ~= nil and t ~= -1 then
				if t.code == v then
					return true
				end
			end
		end
	end
	return false
end

-- Returns true if there is an input at the position.
function InputAt(x, y, z)
	return BuildingsAt(x, y, z, InputWorkshop)
end

-- This is the Masterwork default version of the IOOffsets function.
-- It allows inputs and outputs only in the middle tile of each workshop side.
-- Non-square workshops will work fine, for workshops with even side lengths (2, 4, 6, etc) the
-- tiles will tend north or west of true center. Odd length sides are recommended.
function IOOffsetsMasterwork(wshop)
	local area = Area(wshop)
	
	local w2 = math.floor((area.x2 - area.x1) / 2)
	local h2 = math.floor((area.y2 - area.y1) / 2)
	
	return {
		{x = area.x1 + w2, y = area.y1, z = area.z},
		{x = area.x1, y = area.y1 + h2, z = area.z},
		{x = area.x2, y = area.y1 + h2, z = area.z},
		{x = area.x1 + w2, y = area.y2, z = area.z},
	}
end

-- This is the Rubble default version of the IOOffsets function.
-- It allows inputs and outputs in any adjacent tile, including corners (allowing diagonal connections).
function IOOffsetsRubble(wshop)
	local area = Area(wshop)
	
	local locs = {}
	for cx = area.x1, area.x2, 1 do
		for cy = area.y1, area.y2, 1 do
			if (cx == area.x1 or cx == area.x2) or (cy == area.y1 or cy == area.y2) then
				table.insert(locs, {x = cx, y = cy, z = area.z})
			end
		end
	end
	return locs
end

-- This is the "no diagonals" version of the IOOffsets function.
-- It allows inputs and outputs in any adjacent tile (but not the corners).
function IOOffsetsNoDiag(wshop)
	local area = Area(wshop)
	
	local locs = {}
	for cx = area.x1, area.x2, 1 do
		for cy = area.y1, area.y2, 1 do
			if (cx == area.x1 or cx == area.x2) or (cy == area.y1 or cy == area.y2) then
				if not ((cx == area.x1 or cx == area.x2) and (cy == area.y1 or cy == area.y2)) then
					table.insert(locs, {x = cx, y = cy, z = area.z})
				end
			end
		end
	end
	return locs
end

-- This is the "sides only" version of the IOOffsets function.
-- It allows inputs and outputs in any adjacent tile (but not the corners or tiles adjacent to the corners).
function IOOffsetsSides(wshop)
	local area = Area(wshop)
	
	if (area.x2 - area.x1 < 3) and (area.y2 - area.y1 < 3) then
		-- The workshop is too small to have any IO locations with this algorithm,
		-- fall back to the "no diagonals" version.
		return IOOffsetsNoDiag(wshop)
	end
	
	local locs = {}
	for cx = area.x1, area.x2, 1 do
		for cy = area.y1, area.y2, 1 do
			if (cx == area.x1 or cx == area.x2) or (cy == area.y1 or cy == area.y2) then
				if not ((cx >= area.x1 + 1 or cx <= area.x2 - 1) and (cy >= area.y1 + 1 or cy <= area.y2 - 1)) then
					table.insert(locs, {x = cx, y = cy, z = area.z})
				end
			end
		end
	end
	return locs
end

-- IOOffsets should be set to a function that takes a workshop and returns a table of possible
-- input/output locations as {x, y, z} coord tables. These locations MUST be somewhere adjacent
-- to the workshop (any adjacent tile is legal).
-- The function should work with any size rectangular workshop.
IOOffsets = IOOffsets--OUTPUT_STYLE

-- Returns true if the workshop has at least one input tile.
function HasInput(wshop)
	local locs = IOOffsets(wshop)
	
	for _, off in pairs(locs) do
		if InputAt(off.x, off.y, off.z) then
			return true
		end
	end
	return false
end

-- Returns a list of input positions.
-- List uses 1-based indexing!
function Inputs(wshop)
	local locs = IOOffsets(wshop)
	
	local rtn = {}
	
	for _, off in pairs(locs) do
		if InputAt(off.x, off.y, off.z) then
			table.insert(rtn, {x = off.x, y = off.y, z = off.z})
		end
	end
	return rtn
end

-- Returns true if there is an output at the position.
function OutputAt(x, y, z)
	return BuildingsAt(x, y, z, OutputWorkshop)
end

-- Returns true if the workshop has at least one output tile.
function HasOutput(wshop)
	local locs = IOOffsets(wshop)
	
	for _, off in pairs(locs) do
		if OutputAt(off.x, off.y, off.z) then
			return true
		end
	end
	return false
end

-- Returns a list of output positions.
-- The locations returned are actually the tiles on the other side
-- of the outputs from the workshop!
function Outputs(wshop)
	local locs = IOOffsets(wshop)
	local pos = Area(wshop)
	
	local rtn = {}
	
	for _, off in pairs(locs) do
		if OutputAt(off.x, off.y, off.z) then
			local opos = {x = off.x, y = off.y, z = off.z}
			if off.x > pos.x2 - 1 then
				opos.x = opos.x + 1
			elseif off.x < pos.x1 + 1 then
				opos.x = opos.x - 1
			end
			if off.y > pos.y2 - 1 then
				opos.y = opos.y + 1
			elseif off.y < pos.y1 + 1 then
				opos.y = opos.y - 1
			end
			table.insert(rtn, opos)
		end
	end
	return rtn
end

-- Returns a {x,y,z} for the workshop's center tile.
function Center(wshop)
	return {x = wshop.centerx, y = wshop.centery, z = wshop.z}
end

-- Returns a {x1,y1,x2,y2,z} that describes the area around the workshop.
function Area(wshop)
	return {x1 = wshop.x1-1, y1 = wshop.y1-1, x2 = wshop.x2+1, y2 = wshop.y2+1, z = wshop.z}
end

-- Returns a fake "workshop" for use with the functions in this API.
-- Use for cases where the workshop is not immediately available.
-- Only works for odd sized square workshops (eg 1x1, 3x3, 5x5, etc.).
function MakeFake(x, y, z, size)
	local o = math.floor(size / 2) + 1
	return {centerx = x, centery = y, x1 = x-o, y1 = y-o, x2 = x+o, y2 = y+o, z = z}
end

-- Same as MakeFake, but for any size or (rectangular) shape.
function MakeFakeAdv(cx, cy, x1, y1, x2, y2, z)
	return {centerx = cx, centery = cy, x1 = x1, y1 = y1, x2 = x2, y2 = y2, z = z}
end

-- Add wear to a trap component or mechanism in a workshop.
-- Damage is a percent chance that one component of the workshop should be damaged.
-- If a component gets too damaged it can be destroyed, causing the factory to deconstruct.
function Damage(wshop, damage)
	-- Needs to be "<=" so damage == 100 will actually work 100% of the time...
	-- Remember some a**hole made Lua 1-based.
	if math.random(100) <= damage then
		local components = {}
		local partNumber = 0
		
		for i = 0, #wshop.contained_items - 1, 1 do
			ic = wshop.contained_items[i]
			-- Only take mechanisms and trap components into account
			-- (I assume use_mode == 2 means "part of the workshop"?)
			if (ic.item:getType() == 66 or ic.item:getType() == 67) and ic.use_mode == 2 then
				partNumber = partNumber + 1
				table.insert(components, ic.item)
			end
		end
		
		local i = math.random(partNumber)
		components[i]:setWear(components[i]:getWear() + 1)
		if components[i].wear > 3 then
			dfhack.items.remove(components[i])
		end
	end
end

return _ENV
