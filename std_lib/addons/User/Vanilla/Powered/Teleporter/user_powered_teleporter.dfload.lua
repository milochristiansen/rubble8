
local pwshops = rubble.require "workshops_libs_powered"
local punits = rubble.require "units_libs_powered"

function makeTeleport()
	return function(wshop)
		if pwshops.IsUnpowered(wshop) then
			return
		end
		
		-- Get the average quality of the workshop's components.
		local totalQuality = 0
		local partNumber = 0
		for i = 0, #wshop.contained_items - 1, 1 do
			ic = wshop.contained_items[i]
			-- Only take mechanisms, trap components, and tools into account
			if (ic.item:getType() == 66 or ic.item:getType() == 67 or ic.item:getType() == 85) and ic.use_mode == 2 then
				partNumber = partNumber + 1
				totalQuality = totalQuality + ic.item.quality
			end
		end
		
		local quality = 0
		if partNumber > 0 then
			quality = math.floor(totalQuality / partNumber)
		end
		
		-- Teleport all units within a 9x9 area to their destination.
		local area = pwshops.Area(wshop)
		local units = punits.ListInArea(area.x1 - 3, area.y1 - 3, area.x2 + 3, area.y2 + 3, area.z)
		for _, unit in pairs(units) do
			-- If the unit has a destination (and is not at it).
			if unit.path.dest.z > -1 and not (unit.path.dest.x == unit.pos.x and unit.path.dest.y == unit.pos.y and unit.path.dest.z == unit.pos.z) then
				-- Teleport the unit!
				local unitoccupancy = dfhack.maps.getTileBlock(unit.pos).occupancy[unit.pos.x%16][unit.pos.y%16]
				unit.pos.x = unit.path.dest.x
				unit.pos.y = unit.path.dest.y
				unit.pos.z = unit.path.dest.z
				if not unit.flags1.on_ground then
					unitoccupancy.unit = false
				else
					unitoccupancy.unit_grounded = false
				end
				
				-- The lower the quality of the workshop components the higher the chance that
				-- the teleport is a frightening experience.
				errChance = math.random(5)
				if errChance > quality then
					-- I have no idea what most of these fields mean, I copied this from the siren script...
					unit.status.current_soul.personality.emotions:insert('#', {new = true,
						type = df.emotion_type.Fear,
						unk2 = 1,
						strength = 1,
						thought = df.unit_thought_type.Incident,
						subthought = 0,
						severity = 0,
						flags = 0,
						unk7 = 0,
						year = df.global.cur_year,
						year_tick = df.global.cur_year_tick})
				end
			end
		end
	end
end

-- 500 power!
pwshops.Register("DFHACK_POWERED_TELEPORTER", nil, 500, 0, 50, makeTeleport)
