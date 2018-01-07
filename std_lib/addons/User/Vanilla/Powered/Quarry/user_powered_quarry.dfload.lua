
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local punits = rubble.require "units_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local tile_mat = rubble.require "libs_get_tile_material"

function isDiggable(x, y, z)
	local mat = tile_mat.GetTileMat(x, y, z)
	if mat.mode ~= "inorganic" then
		return nil, false
	end
	
	if mat.inorganic.flags.SOIL_SAND == true then
		return mat, true
	end
	
	return pitems.GetMRP("FIRED_MAT", mat), false
end

function findDiggableArea(x1, y1, x2, y2, z)
	for cx = x1, x2, 1 do
		for cy = y1, y2, 1 do
			soil, needs_bag = isDiggable(cx, cy, z)
			if soil ~= nil then
				return soil, needs_bag
			end
		end
	end
	return nil, false
end

function makeDigQuarry(output)
	return function(wshop)
		if pwshops.IsUnpowered(wshop) then
			return
		end
		if not pwshops.HasOutput(wshop) then
			return
		end
		local apos = pwshops.Area(wshop)
		
		local mat, needs_bag = findDiggableArea(apos.x1, apos.y1, apos.x2, apos.y2, apos.z)
		if mat == nil then
			local unit = punits.FindAtWorkshop(wshop)
			if unit ~= nil and pdisaster.EnabledUnits then
				pdisaster.MangleCreature(wshop, unit)
			end
			return
		end
		
		if needs_bag then
			local bag = pitems.FindItemAtInput(wshop, pfilter.Bag(pfilter.Empty()))
			if bag == nil then
				local unit = punits.FindAtWorkshop(wshop)
				if unit ~= nil and pdisaster.EnabledUnits then
					pdisaster.MangleCreature(wshop, unit)
				end
				return
			end
			
			local item = pitems.CreateItem(mat, 'item_powder_miscst', nil, 0)
			dfhack.items.moveToContainer(item, bag)
			pitems.Eject(wshop, bag)
		else
			local item = pitems.CreateItem(mat, 'item_boulderst', nil, 0)
			pitems.Eject(wshop, item)
		end
	end
end

pwshops.Register("DFHACK_POWERED_QUARRY", nil, 30, 0, 800, makeDigQuarry)
