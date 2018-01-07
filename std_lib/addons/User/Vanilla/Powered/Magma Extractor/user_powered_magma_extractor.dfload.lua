
local fluids = rubble.require "libs_fluids"
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"

results = {
	-- ["inorganic"] = percent chance,
	["ADAMANTINE"] = 1,
	["PLATINUM"] = 2,
	["ALUMINUM"] = 2,
	["GOLD"] = 3,
	["IRON"] = 5,
	["SILVER"] = 5,
	["COPPER"] = 10,
	["TIN"] = 10,
}

function makeExtractMetal(output)
	return function(wshop)
		if pwshops.IsUnpowered(wshop) then
			return
		end
		if not pwshops.HasOutput(wshop) then
			return
		end
		
		local apos = pwshops.Area(wshop)
		if not fluids.eatFromArea(apos.x1, apos.y1, apos.x2, apos.y2, apos.z, true, 2, 4) then
			return
		end
		
		for matn, chance in pairs(results) do
			if math.random(100) <= chance then
				local mat = dfhack.matinfo.find("INORGANIC:"..matn)
				item = pitems.CreateItem(mat, 'item_barst', nil, 0)
				item:setDimension(150)
				pitems.Eject(wshop, item)
				return
			end
		end
	end
end

pwshops.Register("DFHACK_POWERED_MAGMA_EXTRACTOR", nil, 50, 0, 2000, makeExtractMetal)
