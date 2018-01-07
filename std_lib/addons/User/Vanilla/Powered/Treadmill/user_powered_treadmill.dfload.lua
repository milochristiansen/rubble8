
local buildings = require 'plugins.building-hacks'

local pwshops = rubble.require "workshops_libs_powered"
local punits = rubble.require "units_libs_powered"

function runTreadmill()
	return function(wshop)
		local pos = pwshops.Center(wshop)
		
		local p, c = buildings.getPower(wshop)
		local unit = punits.FindInTile(pos.x, pos.y, pos.z)
		
		if unit == nil and p ~= 0 then
			buildings.setPower(wshop, 0, 0)
		elseif unit ~= nil and p == 0 then
			buildings.setPower(wshop, 15, 0)
		end
	end
end

pwshops.Register("DFHACK_POWERED_TREADMILL", nil, 0, 15, 100, runTreadmill, 1, 51)
