
local pwshops = rubble.require "workshops_libs_powered"

function makeMist(output)
	return function(wshop)
		if pwshops.IsUnpowered(wshop) then
			return
		end
		
		local pos = pwshops.Center(wshop)
		
		block = dfhack.maps.ensureTileBlock(pos.x, pos.y, pos.z - 1)
		if block.designation[pos.x%16][pos.y%16].flow_size > 1 then
			block.designation[pos.x%16][pos.y%16].flow_size = block.designation[pos.x%16][pos.y%16].flow_size - 1
			if block.designation[pos.x%16][pos.y%16].liquid_type == true then
				dfhack.maps.spawnFlow(pos, df.flow_type["MagmaMist"], 0, 0, 50)
			else
				dfhack.maps.spawnFlow(pos, df.flow_type["Mist"], 0, 0, 50)
			end
			dfhack.maps.enableBlockUpdates(block, true, true)
		end
	end
end

pwshops.Register("DFHACK_POWERED_MIST_GEN", nil, 15, 0, 50, makeMist, 1, 1, {35, 7,0,0}, {35, 0,7,0})
