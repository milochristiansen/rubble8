
local fluids = rubble.require "libs_fluids"
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"

function makeCastObsidian(output)
	return function(wshop)
		if pwshops.IsUnpowered(wshop) then
			return
		end
		if not pwshops.HasOutput(wshop) then
			return
		end
		local apos = pwshops.Area(wshop)
		
		if fluids.checkInArea(apos.x1, apos.y1, apos.x2, apos.y2, apos.z, true, 4, 4) then
			if fluids.checkInArea(apos.x1, apos.y1, apos.x2, apos.y2, apos.z, false, 4, 4) then
				fluids.eatFromArea(apos.x1, apos.y1, apos.x2, apos.y2, apos.z, true, 4, 4)
				fluids.eatFromArea(apos.x1, apos.y1, apos.x2, apos.y2, apos.z, false, 4, 4)
				
				local mat = dfhack.matinfo.find("INORGANIC:OBSIDIAN")
				local item = pitems.CreateItem(mat, 'item_boulderst', nil, 0)
				pitems.Eject(wshop, item)
			end
		end
	end
end

pwshops.Register("DFHACK_POWERED_OBSIDIAN_CASTER", nil, 30, 0, 800, makeCastObsidian)
