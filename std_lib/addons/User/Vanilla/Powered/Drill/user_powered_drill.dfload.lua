
local eventful = require "plugins.eventful"
local buildings = require 'plugins.building-hacks'

local fluids = rubble.require "libs_fluids"

local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local ppersist = rubble.require "persist_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local punits = rubble.require "units_libs_powered"
local pfilter = rubble.require "filter_libs_powered"

-- The tile type to use as the drill pipe
-- If you change this change the same setting in the geothermal power plant script.
local drillPipe = df.tiletype["ConstructedPillar"]

-- How much power it takes to run the machine for each level drilled
local powerPerLevel = 10

local ttypCache = {}

-- Finds a tile type with the given material class and shape class (for example "FLOOR" "SOIL", but
-- the numeric indexes instead of the string names).
-- 
-- This saves me from needing a huge if/elseif mess for each possible tiletype when retracting.
-- Instead I just need to specify what the basic shapes should transition to and the material takes
-- care of itself.
-- 
-- In practice this is only used for ramps, but that's still 4-5 ramp types to worry about, plus this
-- way will work even if more tiletypes are added someday.
-- 
-- The result is cached (for speed, not that it should really matter).
local findtiletype = function(shape, mat)
	-- Try to find the needed type in the cache.
	local tshape = ttypCache[shape]
	if tshape ~= nil then
		local ttype = ttypCache[shape][mat]
		if ttype ~= nil then
			return ttype
		end
	else
		ttypCache[shape] = {}
	end
	
	-- Type not in cache, do manual lookup.
	for typ = 0, df.tiletype._last_item, 1 do
		if df.tiletype.attrs[typ].shape == shape then
			if df.tiletype.attrs[typ].material == mat then
				ttypCache[shape][mat] = typ
				return typ
			end
		end
	end
	
	-- Should never happen.
	return df.tiletype["OpenSpace"]
end

-- Find the bottom of the drill string.
local getDepth = function(x, y, z)
	for depth = z - 1, 0, -1 do
		local block = dfhack.maps.ensureTileBlock(x, y, depth)
		if block.tiletype[x%16][y%16] ~= drillPipe then
			return depth
		end
	end
end

-- Set the drill to use the correct amount of power.
local setPower = function(x, y, z)
	local drill = dfhack.buildings.findAtTile(x, y, z)
	if drill == nil then
		return
	end
	
	local _, power = buildings.getPower(drill)
	if power == nil then
		return
	end
	
	local depth = getDepth(x, y, z)
	local levels = z - depth
	buildings.setPower(drill, 0, powerPerLevel * levels)
end

-- Reveal a tile.
local showTile = function(x, y, z)
	local block = dfhack.maps.ensureTileBlock(x, y, z)
	block.designation[x%16][y%16].hidden = false
end

function drillDown(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
	call_native.value = false
	
	local pos = {}
	pos.x = unit.pos.x
	pos.y = unit.pos.y
	pos.z = unit.pos.z
	
	-- Search downward until we find the end of the drill string,
	-- then extend the string downward by one block.
	local depth = getDepth(pos.x, pos.y, pos.z)
	local block = dfhack.maps.ensureTileBlock(pos.x,pos.y,depth)
	block.tiletype[pos.x%16][pos.y%16] = drillPipe
	block.designation[pos.x%16][pos.y%16].hidden = false
	block.designation[pos.x%16][pos.y%16].flow_size = 0
	
	-- Reveal the surrounding tiles.
	showTile(pos.x, pos.y - 1, depth)
	showTile(pos.x + 1, pos.y - 1, depth)
	showTile(pos.x + 1, pos.y, depth)
	showTile(pos.x + 1, pos.y + 1, depth)
	showTile(pos.x, pos.y + 1, depth)
	showTile(pos.x - 1, pos.y + 1, depth)
	showTile(pos.x - 1, pos.y, depth)
	showTile(pos.x - 1, pos.y - 1, depth)
	
	-- Increase the amount of power needed.
	setPower(pos.x, pos.y, pos.z)
	
	-- Check for fluids below drill bit
	local onebelow = dfhack.maps.ensureTileBlock(pos.x,pos.y,depth-1)
	if onebelow.designation[pos.x%16][pos.y%16].flow_size > 0 then
		if onebelow.designation[pos.x%16][pos.y%16].liquid_type == true then
			dfhack.gui.showAnnouncement("The drill has encountered magma!", COLOR_RED, true)
		else
			dfhack.gui.showAnnouncement("The drill has encountered water!", COLOR_BLUE, true)
		end
	end
	
	fluids.levelUp(unit, df.job_skill["OPERATE_PUMP"], 30)
end

function drillUp(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
	call_native.value = true
	
	local pos = {}
	pos.x = unit.pos.x
	pos.y = unit.pos.y
	pos.z = unit.pos.z
	
	-- Search downward for the end of the drill string and retract it one block upward if possible.
	if (dfhack.maps.ensureTileBlock(pos.x,pos.y,pos.z-1)).tiletype[pos.x%16][pos.y%16] ~= drillPipe then
		dfhack.gui.showAnnouncement("Your Drilling Rig cannot retract any further!", COLOR_RED, true)
		call_native.value = false
		return
	end
	
	local depth = getDepth(pos.x, pos.y, pos.z)
	local block = dfhack.maps.ensureTileBlock(pos.x, pos.y, depth)
	local drillBit = dfhack.maps.ensureTileBlock(pos.x, pos.y, depth + 1)
	
	local shape = df.tiletype.attrs[block.tiletype[pos.x%16][pos.y%16]].shape
	local mat = df.tiletype.attrs[block.tiletype[pos.x%16][pos.y%16]].material
	
	-- I may want to add more transition rules here...
	local ttype = df.tiletype["OpenSpace"] -- If there is no specific rule then just use open space
	if shape == df.tiletype_shape["WALL"] then
		ttype = findtiletype(df.tiletype_shape["RAMP"], mat)
	elseif shape == df.tiletype_shape["RAMP"] then
		ttype = df.tiletype["RampTop"] -- There are no material variants for down ramps.
	end
	
	-- If I ever figure out how to get/manipulate a tile's material it should be possible to have the
	-- drill string have the same material as the input pipe sections and (when retracting) return
	-- pipe sections made from the material of the drill string.
	
	drillBit.tiletype[pos.x%16][pos.y%16] = ttype
	dfhack.maps.enableBlockUpdates(drillBit, true, true)
	
	-- Decrease the amount of power needed.
	setPower(pos.x, pos.y, pos.z)
	
	--fluids.levelUp(unit, df.job_skill["OPERATE_PUMP"], 30)
end

-- Toggle the pump state.
function drillPump(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
	call_native.value = false
	
	local wshop = pwshops.MakeFake(unit.pos.x, unit.pos.y, unit.pos.z, 3)
	
	local output = ppersist.GetOutputType(wshop)
	if output == "PUMPING" then
		ppersist.SetOutputType(wshop, "NONE")
	else
		ppersist.SetOutputType(wshop, "PUMPING")
	end
end

function makeDrillPump()
	return function(wshop)
		-- Set the power level just in case...
		local pos = pwshops.Center(wshop)
		setPower(pos.x, pos.y, pos.z)
		
		if pwshops.IsUnpowered(wshop) then
			return
		end
		
		-- Are we pumping?
		local output = ppersist.GetOutputType(wshop)
		if output ~= "PUMPING" then
			return
		end
		
		local depth = getDepth(pos.x, pos.y, pos.z)
		
		-- Find an item if possible.
		local item = pitems.FindItemInTile(pos.x, pos.y, depth, pfilter.Dummy)
		if item ~= nil then
			pitems.Eject(wshop, item)
			return
		end
		
		-- Otherwise try for a creature
		if pdisaster.EnabledUnits then
			local unit = punits.FindInTile(pos.x, pos.y, depth)
			if unit ~= nil then
				pdisaster.MangleCreature(wshop, unit)
				
				local outputs = pwshops.Outputs(wshop)
				if #outputs == 0 then
					unit.pos.x = pos.x
					unit.pos.y = pos.y
					unit.pos.z = pos.z
				else
					local out = outputs[math.random(#outputs)]
					
					unit.pos.x = out.x
					unit.pos.y = out.y
					unit.pos.z = out.z
				end
				return
			end
		end
		
		-- Finally try for fluids
		local fluid = false
		if fluids.checkFluid(pos.x, pos.y, depth, true, 4, 4) then
			fluid = true
		end
		if not fluid and not fluids.checkFluid(pos.x, pos.y, depth, false, 4, 4) then
			-- No fluids
			return
		end
		
		local area = pwshops.Area(wshop)
		
		for count = 1, 7, 1 do
			if fluids.eatFluid(pos.x, pos.y, depth, fluid, 1, 1) then
				if not fluids.spawnInArea(area.x1, area.y1, area.x2, area.y2, area.z, fluid, 1) then
					-- Cistern full
					return
				end
			else
				-- No fluids
				return
			end
		end
	end
end

pwshops.Register("DFHACK_POWERED_DRILLING_RIG", nil, powerPerLevel, 0, 200, makeDrillPump, 3, 3, nil, nil, true)

eventful.registerReaction("DFHACK_POWERED_DRILLING_RIG_DOWN", drillDown)
eventful.registerReaction("DFHACK_POWERED_DRILLING_RIG_UP", drillUp)
eventful.registerReaction("DFHACK_POWERED_DRILLING_RIG_PUMP", drillPump)
