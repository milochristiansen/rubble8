
-- Powered Disaster: Functions for handling when things go wrong.
_ENV = rubble.mkmodule("disaster_libs_powered")

local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local punits = rubble.require "units_libs_powered"

-- Are the dangerous workshops options on?
-- These are global options that effect all clients of this module (that use the Mangle function).
-- If you create some kind of bad result that does not use Mangle remember to check these variables.

-- Should item mangling be carried out?
-- It is probably not a good idea to disable this (bad inputs can clog workshops otherwise).
EnabledItems = true

-- Should creature mangling be carried out?
-- OSHA recommends all overseers disable this option.
EnabledUnits = --MANGLE_UNIT

-- Can factories be damaged by invalid inputs?
-- Protect your property today!
EnabledDamage = --MANGLE_SHOP

--[[

-- Example
-- In this case the Mangle function will return nil unless the item to mangle was a hard, non-metal
-- item of the wrong type. Wooden items will not be considered mangle-able.

pdisaster.Mangle(wshop, pdisaster.Switch({
	-- If the item is metal 10% chance to damage the factory and pass the item.
	{pfilter.MatFlags("IS_METAL"), pdisaster.Damage(10, pdisaster.PassItem)},
	
	-- If the item is not hard then 1% chance of damage and rot it if possible, else pass it.
	{pfilter.Not(pfilter.MatFlags("ITEMS_HARD")), pdisaster.Damage(1, pdisaster.RotItem(pdisaster.PassItem))},
	
	-- Any other (invalid) item gives a 5% chance of damage, is destroyed, and returns it's material for use.
	{pfilter.Dummy, pdisaster.Damage(5, pdisaster.DestroyItemMat)},
	
	-- Creatures get the standard handling and wooden items are ignored.
}), pdisaster.MangleCreature, pfilter.MatFlags("WOOD"))

]]


-- Handle cases where the proper input(s) could not be found.
-- 
-- This function will return nil or whatever the mangle function returns (if one is called).
-- 
-- If any item is available at any input it will grab the first one it finds and pass it as an
-- argument to the mangle_item function you provided. If an item was not found the first available
-- creature is used (with mangle_unit). If no item OR creature could be found nil is returned.
-- 
-- Items that pass the nomangle check function will not be considered for item mangling. This is used for
-- workshops that take multiple items where you do not want valid inputs to be mangled just because there are
-- too few of them. Pass nil to skip this check.
-- 
-- The mangle functions should take a workshop and a creature or item and return something (exactly
-- what is up to the function).
-- 
-- All of the other functions in this module are used by this one at some level (most are used as
-- arguments to mangle_item or mangle_unit).
function Mangle(wshop, mangle_item, mangle_unit, nomangle)
	local check
	if nomangle == nil then
		check = function(i) return true end
	else
		check = function(i) return not nomangle(i) end
	end
	
	if EnabledItems then
		local item = pitems.FindItemAtInput(wshop, check)
		if item ~= nil then
			if mangle_item ~= nil then
				return mangle_item(wshop, item)
			end
			return nil
		end
	end
	
	--Try to get a creature
	if EnabledUnits then
		local unit = punits.FindAtWorkshop(wshop)
		if unit ~= nil then
			if mangle_unit ~= nil then
				return mangle_unit(wshop, unit)
			end
			return nil
		end
	end
	return nil
end

-- An item mangle function generator that ejects unharmed any item that matches the check.
-- Any item that fails the check is passed to mangle_next.
-- (check is a standard check function)
-- Returns an item mangle function.
-- The returned function returns nil or the result of mangle_next.
function PassItemIf(check, mangle_next)
	return function(wshop, item)
		if check(item) then
			pitems.Eject(item)
			return nil
		end
		
		if mangle_next ~= nil then
			return mangle_next(wshop, item)
		end
		return nil
	end
end

-- An item mangle function that ejects the item unharmed.
-- Returns nil.
function PassItem(wshop, item)
	pitems.Eject(wshop, item)
	return nil
end

-- An item mangle function that destroys the item and ejects an ash bar.
-- Returns nil.
function AshItem(wshop, item)
	pitems.DestroyItem(item, wshop)
	ash = pitems.CreateItem(dfhack.matinfo.find("ASH:NONE"), "item_barst", nil, 0)
	ash:setDimension(150)
	pitems.Eject(wshop, ash)
	return nil
end

-- An item mangle function generator that rots an item if possible or calls mangle_next
-- with the item if it is not rottable.
-- Returns an item mangle function.
-- The returned function returns nil or the result of mangle_next.
function RotItem(mangle_next)
	return function(wshop, item)
		local mat = dfhack.matinfo.decode(item)
		if mat ~= nil then
			local itemname = df.item_type[item:getType()]:lower()
			if mat.material.flags.ROTS and (itemname == 'corpsepiece' or itemname == 'corpse' or itemname == 'remains') then
				local rot = item.rot_timer
				if rot ~= nil then
					item.rot_timer = rot + 100
				end
				return nil
			end
		end
		
		if mangle_next ~= nil then
			return mangle_next(wshop, item)
		end
		return nil
	end
end

-- An item mangle function that destroys the item.
-- Returns nil.
function DestroyItem(wshop, item)
	pitems.DestroyItem(item, wshop)
	return nil
end

-- An item mangle function that destroys the item.
-- Returns the item's material.
function DestroyItemMat(wshop, item)
	local mat = dfhack.matinfo.decode(item)
	pitems.DestroyItem(item, wshop)
	return mat
end

-- A mangle function generator that calls mangle_if if the check is true and mangle_else if false.
-- (check is a standard check function, but this may be used with creatures as well)
-- Returns a generic (item OR creature) mangle function.
-- The returned function returns nil or the result of mangle_if or mangle_else.
function If(check, mangle_if, mangle_else)
	return function(wshop, obj)
		if check(obj) then
			if mangle_if ~= nil then
				return mangle_if(wshop, obj)
			end
			return nil
		else
			if mangle_else ~= nil then
				return mangle_else(wshop, obj)
			end
			return nil
		end
	end
end

-- A mangle function generator that iterates through the passed in table.
-- Each entry in the table should be a table with two items: The first must be a standard check
-- function, and the second should be a mangle function to call if the check returns true.
-- The checks are run in order, the first one to pass is the one used.
-- Returns a generic (item OR creature) mangle function.
-- The returned function returns nil or the result of the called mangle function.
function Switch(tbl)
	return function(wshop, obj)
		for i, condition in pairs(tbl) do
			if type(condition) == "table" and #condition == 2 then
				if condition[1](obj) then
					return condition[2](wshop, obj)
				end
			else
				print("powered.disaster: Invalid condition: "..i.." passed to Switch.")
			end
		end
		return nil
	end
end

-- A mangle function generator that has a chance to damage the factory before calling
-- mangle_next to finish the job.
-- Returns a generic (item OR creature) mangle function.
-- The returned function returns nil or the result of mangle_next.
function Damage(chance, mangle_next)
	return function(wshop, item)
		if EnabledDamage then
			pwshops.Damage(wshop, chance)
		end
		
		if mangle_next ~= nil then
			return mangle_next(wshop, item)
		end
		return nil
	end
end

-- A creature mangle function that slams the creature into the ground at a random speed.
-- (This does what the old Masterwork machina script did)
-- Returns nil.
function MangleCreature(wshop, unit)
	if dfhack.units.isDwarf(unit) then
		dfhack.gui.showAnnouncement(dfhack.TranslateName(unit.name).." has been caught in a machine!" , COLOR_MAGENTA, true)
	end
	
	local l = df.global.world.proj_list
	local lastlist = l
	l = l.next
	
	local count = 0
	while l do
		count = count + 1
		if l.next==nil then
			lastlist = l
		end
		l = l.next
	end
	
	newlist = df.proj_list_link:new()
	lastlist.next = newlist
	newlist.prev = lastlist
	proj = df.proj_unitst:new()
	newlist.item = proj
	proj.link = newlist
	proj.id = df.global.proj_next_id
	df.global.proj_next_id = df.global.proj_next_id + 1
	proj.unit = unit
	proj.origin_pos.x = unit.pos.x
	proj.origin_pos.y = unit.pos.y
	proj.origin_pos.z = unit.pos.z
	proj.prev_pos.x = unit.pos.x
	proj.prev_pos.y = unit.pos.y
	proj.prev_pos.z = unit.pos.z
	proj.cur_pos.x = unit.pos.x
	proj.cur_pos.y = unit.pos.y
	proj.cur_pos.z = unit.pos.z
	proj.flags.no_impact_destroy = true
	proj.flags.piercing = true
	proj.flags.parabolic = true
	proj.flags.unk9 = true
	proj.speed_x = 0
	proj.speed_y = 0
	proj.speed_z = -math.random(1000000)
	unitoccupancy = dfhack.maps.getTileBlock(unit.pos).occupancy[unit.pos.x%16][unit.pos.y%16]
	if not unit.flags1.on_ground then 
		unitoccupancy.unit = false 
	else 
		unitoccupancy.unit_grounded = false 
	end
	unit.flags1.projectile=true
	unit.flags1.on_ground=false
	return nil
end

return _ENV