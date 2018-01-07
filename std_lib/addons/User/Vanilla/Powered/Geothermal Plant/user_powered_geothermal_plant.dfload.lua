
local buildings = require 'plugins.building-hacks'

local pwshops = rubble.require "workshops_libs_powered"
local punits = rubble.require "units_libs_powered"

-- The tile type to use as the drill pipe
-- THIS MUST MATCH THE SAME SETTING IN THE DRILL SCRIPT!
local drillPipe = df.tiletype["ConstructedPillar"]

-- Find the bottom of the drill string.
local getDepth = function(x, y, z)
	for depth = z - 1, 0, -1 do
		local block = dfhack.maps.ensureTileBlock(x, y, depth)
		if block.tiletype[x%16][y%16] ~= drillPipe then
			return depth
		end
	end
end

local magmaAt = function(x, y, z)
	local block = dfhack.maps.ensureTileBlock(x, y, z)
	if block.designation[x%16][y%16].liquid_type then
		return block.designation[x%16][y%16].flow_size
	end
	return 0
end
function calcPower()	
	return function(wshop)
		local pos = pwshops.Center(wshop)
		local depth = getDepth(pos.x, pos.y, pos.z)
		
		local power = 0
		for cz = depth, depth - 2, -1 do
			for cx = wshop.x1, wshop.x2, 1 do
				for cy = wshop.y1, wshop.y2, 1 do
					power = power + magmaAt(cx, cy, cz)
				end
			end
		end
		
		buildings.setPower(wshop, power, 0)
	end
end

-- Should update the power output every 30 seconds (at 100 FPS)
pwshops.Register("DFHACK_POWERED_GEOTHERMAL_PLANT", nil, 0, 10, 3000, calcPower, 5, 5)
