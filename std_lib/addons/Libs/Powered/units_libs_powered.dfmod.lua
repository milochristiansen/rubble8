
-- Powered Units: Finding units on certain tiles or workshop inputs.
_ENV = rubble.mkmodule("units_libs_powered")

local pwshops = rubble.require "workshops_libs_powered"

-- Return a creature at the location.
function FindInTile(x, y, z)
	local block = dfhack.maps.ensureTileBlock(x, y, z)
	if block.occupancy[x%16][y%16].unit == true or block.occupancy[x%16][y%16].unit_grounded == true then
		allUnits = df.global.world.units.active
		for i = #allUnits - 1, 0, -1 do -- search list in reverse
			u = allUnits[i]
			if u.pos.x == x and u.pos.y == y and u.pos.z == z and u.flags1.dead == false and u.flags3.ghostly == false then
				return u
			end
		end
	end
	return nil
end

-- Find a creature at one of the passed in locations.
-- The locations are checked in random order.
function FindAt(locs)
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
		local unit = FindInTile(locs[i].x, locs[i].y, locs[i].z)
		if unit ~= nil then
			return unit
		end
	end
	return nil
end

-- Find a creature at a workshop, searching inputs first, then the workshop itself.
-- Input tiles are checked in random order.
-- Returns a creature or nil
function FindAtWorkshop(wshop)
	local unit = FindAt(pwshops.Inputs(wshop))
	if unit ~= nil then
		return unit
	end
	
	for cx = wshop.x1, wshop.x2, 1 do
		for cy = wshop.y1, wshop.y2, 1 do
			unit = FindInTile(cx, cy, wshop.z)
			if unit ~= nil then
				return unit
			end
		end
	end
	return nil
end

-- Find a creature in an area
-- Returns a creature or nil
function FindInArea(x1, y1, x2, y2, z)
	for cx = x1, x2, 1 do
		for cy = y1, y2, 1 do
			unit = FindInTile(cx, cy, z)
			if unit ~= nil then
				return unit
			end
		end
	end
	return nil
end

-- Find all the creature in an area.
-- Returns a table of creatures in the area.
function ListInArea(x1, y1, x2, y2, z)
	local units = {}
	for cx = x1, x2, 1 do
		for cy = y1, y2, 1 do
			local block = dfhack.maps.ensureTileBlock(cx, cy, z)
			if block.occupancy[cx%16][cy%16].unit == true or block.occupancy[cx%16][cy%16].unit_grounded == true then
				allUnits = df.global.world.units.active
				for i = #allUnits - 1, 0, -1 do
					u = allUnits[i]
					if u.pos.x == cx and u.pos.y == cy and u.pos.z == z and u.flags1.dead == false and u.flags3.ghostly == false then
						table.insert(units, u)
					end
				end
			end
		end
	end
	return units
end

-- Find a creature on an adjacent input tile.
-- Input tiles are checked in random order.
-- Returns a creature or nil
function FindAtInput(wshop)
	return FindAt(pwshops.Inputs(wshop))
end

return _ENV
