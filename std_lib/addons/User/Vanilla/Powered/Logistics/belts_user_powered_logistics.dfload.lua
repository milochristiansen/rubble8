
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"

local build_list = rubble.require 'libs_change_build_list'

function makeBelt(dir)
	return function(wshop)
		local pos = pwshops.Center(wshop)
		
		local itemblock = dfhack.maps.ensureTileBlock(pos)
		if itemblock.occupancy[pos.x%16][pos.y%16].item == false then
			return
		end
		
		-- Forbid all items on the workshop, that way items dumped by minecarts won't "walk off"
		-- before the belt can move them.
		local item = nil
		for c = #itemblock.items-1,0,-1 do
			local citem = df.item.find(itemblock.items[c])
			if citem.pos.x == pos.x and citem.pos.y == pos.y and citem.pos.z == pos.z then
				item = citem
				item.flags.forbid = true
				
				for r = #item.specific_refs - 1, 0, -1 do
					if item.specific_refs[r].type == df.specific_ref_type["JOB"] then
						item.specific_refs[r].job.flags.item_lost = true
					end
				end
			end
		end
		if item == nil then
			return
		end
		
		local npos = pwshops.Center(wshop)
		if dir == "NORTH" then
			npos.y = npos.y - 1
		elseif dir == "SOUTH" then
			npos.y = npos.y + 1
		elseif dir == "EAST" then
			npos.x = npos.x + 1
		elseif dir == "WEST" then
			npos.x = npos.x - 1
		end
		
		-- If the tile we want to move to is not passable.
		local ttype = dfhack.maps.getTileType(npos.x, npos.y, npos.z)
		local tshape = df.tiletype.attrs[ttype].shape
		if not df.tiletype_shape.attrs[tshape].passable_high then
			-- Try to move to the tile above that.
			npos.z = npos.z + 1
			ttype = dfhack.maps.getTileType(npos.x, npos.y, npos.z)
			tshape = df.tiletype.attrs[ttype].shape
			if not df.tiletype_shape.attrs[tshape].passable_high then
				return
			end
			
			-- But only if there is a hole in the floor.
			ttype = dfhack.maps.getTileType(pos.x, pos.y, pos.z + 1)
			tshape = df.tiletype.attrs[ttype].shape
			if not df.tiletype_shape.attrs[tshape].passable_low then
				return
			end
		end
		
		dfhack.items.moveToGround(item, npos)
		pitems.ForbidIfNeeded(item)
		pitems.ProjectileIfNeeded(item)
	end
end

local outputs = {
	"NORTH",
	"SOUTH",
	"EAST",
	"WEST",
}

pwshops.Register("DFHACK_POWERED_BELTS", outputs, 0, 0, 5, makeBelt)
build_list.ChangeBuilding("DFHACK_POWERED_BELTS_NORTH", "WORKSHOPS", false)
build_list.ChangeBuilding("DFHACK_POWERED_BELTS_NORTH", "MACHINES", true, "CUSTOM_SHIFT_B")

for _, output in pairs(outputs) do
	-- This makes it so that items that are output onto a belt with Eject are forbidden.
	table.insert(pitems.ForbidOver, "DFHACK_POWERED_BELTS_"..output)
end
