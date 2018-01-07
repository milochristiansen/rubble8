
-- Items: Generic item creation and management functions.
_ENV = rubble.mkmodule("libs_items")

-- Find an item at the location.
-- check should be a function that takes an item and returns true if it
-- is like the one you are looking for.
-- See "Libs/DFHack/Items/Filter" for pre-made filter functions.
function FindItemInTile(x, y, z, check)
	local itemblock = dfhack.maps.ensureTileBlock(x, y, z)
	if itemblock.occupancy[x%16][y%16].item == true then
		for c=#itemblock.items-1,0,-1 do
			local item = df.item.find(itemblock.items[c])
			if item.pos.x == x and item.pos.y == y and item.pos.z == z then
				if check(item) then
					return item
				end
			end
		end
	end
	return nil
end

-- Finds an item in a container.
-- Returns item or nil.
-- check should be a function that takes an item and returns true if it
-- is like the one you are looking for.
-- See "Libs/DFHack/Items/Filter" for pre-made filter functions.
function FindItemIn(container, check)
	local contents = dfhack.items.getContainedItems(container)
	if contents ~= nil and #contents ~= 0 then
		for _, v in pairs(contents) do
			if check(v) then
				return v
			end
		end
	end
	return nil
end

-- Removes the specified number of items from the item stack.
-- If the stack is used up the item is deleted and false is returned,
-- else returns true.
function TakeFromStack(item, count)
	item.stack_size = item.stack_size - count
	if item.stack_size <= 0 then
		dfhack.items.remove(item)
		return false
	end
	return true
end

-- Returns the specified material reaction product from the passed in material or nil.
function GetMRP(mrp, mat)
	local rp = mat.material.reaction_product
	for k, v in ipairs(rp.id) do
		if v.value == mrp then
			return dfhack.matinfo.decode(rp.material.mat_type[k], rp.material.mat_index[k])
		end
	end
	return nil
end

-- Checks if a material has the specified reaction class and returns the true or false.
function HasRClass(class, mat)
	for _, v in ipairs(mat.material.reaction_class) do
		if v.value == class then
			return true
		end
	end
	return nil
end

function createItem(mat, typ, subtyp, unit, skill)
	local item = df[typ]:new()
	
	item.id = df.global.item_next_id
	df.global.world.items.all:insert('#', item)
	df.global.item_next_id = df.global.item_next_id + 1
	
	item:setMaterial(mat.type)
	item:setMaterialIndex(mat.index)
	
	item:setMakerRace(df.global.ui.race_id)
	if unit ~= nil then
		item:assignQuality(unit, skill)
		item:setMaker(unit.id)
	end
	
	if subtyp ~= -1 then
		item:setSubtype(subtyp)
	end
	
	item:categorize(true)
	item.flags.removed = true
	
	return item
end

-- Like CreateItem, but with numeric type and subtype.
function CreateItemNumeric(mat, typ, subtyp, unit, skill)
	return createItem(mat, 'item_'..string.lower(df.item_type[typ])..'st', subtyp, unit, skill)
end

-- Create a basic item, you will have to set dimensions, subtype or stack size if needed.
-- The removed flag is set (as needed by moveToGround), so remember to clear this if you need to!
-- If unit is not nil then the item quality is based on it's skill.
-- id should be an item type id of the form "item_barst" or "item_boulderst".
-- The item is returned.
function CreateItem(mat, id, unit, skill)
	return createItem(mat, id, -1, unit, skill)
end

-- Like CreateItem, but just use "BAR" or "bar" instead of "item_barst".
function CreateItemBasic(mat, id, unit, skill)
	return createItem(mat, 'item_'..string.lower(id)..'st', -1, unit, skill)
end

-- Creates a "clothing" item. For some reason the other item creation functions crash DF when they
-- create any clothing.
function CreateItemClothing(mat, typ, subtyp, unit, skill, race)
	-- Clothing causes a CTD if it does not have a valid creator (even with dfhack.items.createItem),
	-- so pick a random creature of the correct race to "create" the item if one is not provided.
	local unitok = true
	if unit == nil then
		unitok = false
		for _, u in ipairs(df.global.world.units.all) do
			if u.race == df.global.ui.race_id then
				unit = u
			end
		end
	end
	
	-- For some reason even setting the creator is not enough to make pitems.CreateNumeric work
	-- for clothing (it crashes when item:categorize(true) is called), but dfhack.items.createItem
	-- works, so use that.
	-- TODO: I changed the way CreateItemNumeric works, so it may work now, test.
	
	local id = dfhack.items.createItem(typ, subtyp, mat.type, mat.index, unit)
	local item = df.item.find(id)
	if unitok then
		item:assignQuality(unit, skill)
	end
	
	-- This should be what is needed to make non-main race clothing, test.
	if race ~= nil then
		item:setMakerRace(race)
	end
	
	return item
end

-- Get a display name for an item type/subtype pair.
-- Use -1 for "no subtype".
function GetItemCaption(type, subtype)
    local attrs = df.item_type.attrs[type]
    if subtype == -1 or subtype == nil then
		return attrs.caption
	else
		return df['itemdef_'..string.lower(df.item_type[type])..'st'].find(subtype).name
	end
end

-- Delete an item.
-- If the item is a container or cage it's contents are dumped on the ground or, if wshop is not nil,
-- the item is assumed to be in the workshop and the contents are dumped into the workshop instead.
-- Most of the time you can just use "dfhack.items.remove".
function DestroyItem(item, wshop)
	-- Remove items from containers and let creatures out of cages.
	for r = #item.general_refs - 1, 0, -1 do
		if getmetatable(item.general_refs[r]) == 'general_ref_contains_itemst' then
			contained_item = df.item.find(item.general_refs[r].item_id)
			for r2 = #contained_item.general_refs-1, 0, -1 do
				if getmetatable(contained_item.general_refs[r2]) == 'general_ref_contained_in_itemst' then
					contained_item.general_refs:erase(r2)
					contained_item.flags.in_inventory = false
				end
			end
			contained_item:moveToGround(item.pos.x,item.pos.y,item.pos.z)
			item.general_refs:erase(r)
			if wshop == nil then
				dfhack.items.moveToGround(contained_item, {item.pos.x, item.pos.y, item.pos.z})
			else
				dfhack.items.moveToBuilding(contained_item, wshop, 0)
			end
		elseif getmetatable(item.general_refs[r]) == 'general_ref_contains_unitst' then
			contained_unit = df.unit.find(item.general_refs[r].unit_id)
			
			-- This should release the unit, right?
			for r2 = #contained_unit.general_refs-1, 0, -1 do
				if getmetatable(contained_unit.general_refs[r2]) == 'general_ref_contained_in_itemst' then
					contained_unit.general_refs:erase(r2)
				end
			end
			contained_unit.flags1.caged = false
			item.general_refs:erase(r)
			contained_unit.pos.x = item.pos.x
			contained_unit.pos.y = item.pos.y
			contained_unit.pos.z = item.pos.z
		end
	end
	
	-- Then delete the item.
	dfhack.items.remove(item)
end

return _ENV