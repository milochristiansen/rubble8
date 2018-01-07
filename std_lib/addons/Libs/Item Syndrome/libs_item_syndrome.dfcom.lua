-- Applies syndromes to creatures from inventory items.

-- 
-- Item Syndrome Reborn is copyright 2015-2016 by Milo Christiansen
-- 
-- Loosely based on the original Item Syndrome (by Putnam).
-- 
-- This software is provided 'as-is', without any express or implied warranty. In
-- no event will the authors be held liable for any damages arising from the use of
-- this software.
-- 
-- Permission is granted to anyone to use this software for any purpose, including
-- commercial applications, and to alter it and redistribute it freely, subject to
-- the following restrictions:
-- 
-- 1. The origin of this software must not be misrepresented; you must not claim
-- that you wrote the original software. If you use this software in a product, an
-- acknowledgment in the product documentation would be appreciated but is not
-- required.
-- 
-- 2. Altered source versions must be plainly marked as such, and must not be
-- misrepresented as being the original software.
-- 
-- 3. This notice may not be removed or altered from any source distribution.
-- 

-- 
-- Item Syndrome Reborn is a complete rewrite of the old Item Syndrome script.
-- Functionally it should be more-or-less the same, but more efficient and
-- generally improved.
-- 
-- Some features of the old item syndrome are not available (for example transformation
-- reequips), but all the important stuff is present.
-- 
-- In general what worked with the old script should work with this one, with a
-- few minor changes.
-- 
-- The biggest change is that if you want to apply a syndrome based on item type
-- instead of looking the syndrome up by item name (for example "battle axe") the
-- syndrome is looked up by item subtype ID ("ITEM_WEAPON_AXE_BATTLE"). This is done
-- to improve precision. Also such syndromes can be in any material, anywhere in the
-- raws, not just a material with a special name.
-- 
-- The flags have also been redone, they are now all permissions instead of a mixture
-- of permissions and restrictions.
-- 
-- Instructions:
-- 
-- Item Syndrome Reborn can apply syndromes in three ways:
-- 
-- * If the item's material has a syndrome with the class "DFHACK_ITEM_SYNDROME"
--   It will apply the syndrome to the creature subject to the flags (discussed later)
--   and any immunities/vulnerabilities the syndrome may have.
-- 
-- * All syndromes in every material in the entire world are searched for one that has
--   a name (the "SYN_NAME" tag) that matches the item's subtype ID *and* the "DFHACK_ITEM_SYNDROME"
--   class. Obviously this only works with items that have subtypes (armor, weapons, ammo, etc).
-- 
-- * If the item has any contaminants the contaminants are checked for valid syndromes
--   (syndromes with the "DFHACK_ITEM_SYNDROME" class) and if any are found they are
--   applied subject to the flags (discussed later) and any immunities/vulnerabilities
--   the syndrome may have.
-- 
-- Syndromes may have additional flags that modify how the syndrome is applied. These
-- flags take the form of syndrome classes (the "SYN_CLASS" tag).
-- 
-- * "DFHACK_AFFECTS_HAULER": Can effect units hauling the item.
-- * "DFHACK_AFFECTS_WIELDER": Can effect units that are using the item as a weapon.
-- * "DFHACK_AFFECTS_WEARER": Can effect unit that are wearing the item as armor.
-- * "DFHACK_AFFECTS_STUCKIN": Effects units the item has stuck in.
-- * "DFHACK_DO_NOT_REMOVE": Effect is not removed when the item is removed.
-- 

local synutil = require 'syndrome-util'
local eventful = require 'plugins.eventful'

-- I cache the syndrome data objects to avoid needing to regenerate them every time they are needed.
Chache = Chache or {}
Chache.Syndromes = Chache.Syndromes or {}
Chache.Items = Chache.Items or {}
dfhack.onStateChange.ItemSyndromeReborn = function(code)
	-- If anything changes (or may have changed) invalidate the cache.
	-- It is better to rebuild the cache unnecessarily than it is to have
	-- a cache with invalid data.
	Chache.Syndromes = {}
	Chache.Items = {}
end

-- Does the syndrome have the "DFHACK_ITEM_SYNDROME" class?
local function isItemSyndrome(syndrome)
	for _,v in ipairs(syndrome.syn_class) do
		if v.value == "DFHACK_ITEM_SYNDROME" then
			return true
		end
	end
	return false
end

-- Create a new syndrome data table from a syndrome.
local function createSynDat(syndrome)
	local syndat = {
		syndrome = syndrome,
		flags = {
			AFFECTS_HAULER = false,
			AFFECTS_WIELDER = false,
			AFFECTS_WEARER = false,
			AFFECTS_STUCKIN = false,
			DO_NOT_REMOVE = false
		},
	}
	
	for _, v in ipairs(syndat.syndrome.syn_class) do
		local flag = string.match(v.value, "DFHACK_(.+)")
		if syndat.flags[flag] ~= nil then
			syndat.flags[flag] = true
		end
	end
	
	return syndat
end

-- This gets a table of syndromes from the object's material and (if is_item is true)
-- the object's item subtype if the item has a subtype.
-- 
-- Return nil if no valid syndromes could be found, otherwise returns a table of syndrome data tables.
local function getObjectSyndromes(object, is_item)
	local syndromes = {}
	
	-- Look for syndromes attached to the material.
	local mat = dfhack.matinfo.decode(object)
	if mat ~= nil and mat.material ~= nil and mat.material.syndrome ~= nil then
		for _, syn in ipairs(mat.material.syndrome) do
			if Chache.Syndromes[syn.id] == nil then
				if isItemSyndrome(syn) then
					Chache.Syndromes[syn.id] = createSynDat(syn)
				else
					Chache.Syndromes[syn.id] = false
				end
			end
			
			if type(Chache.Syndromes[syn.id]) == "table" then
				table.insert(syndromes, Chache.Syndromes[syn.id])
			end
		end
	end
	
	-- Look for a syndrome attached to the item.
	-- The syndrome should have a syndrome name that matches the item's subtype id (this only
	-- works if the item has a subtype obviously).
	-- Unlike the old itemSyndrome I use the item subtype ID not the item subtype name!
	if is_item and object:getSubtype() ~= -1 and type(object.subtype) ~= "number" then
		-- It should be possible to just get the syndromes from the cache every time except the first.
		if Chache.Items[object.subtype.id] ~= nil then
			for _, syndat in ipairs(Chache.Items[object.subtype.id]) do
				table.insert(syndromes, syndat)
			end
		else
			local cache = {}
			for _, syn in ipairs(df.global.world.raws.syndromes.all) do
				if syn.syn_name == object.subtype.id then
					if isItemSyndrome(syn) then
						local syndat = createSynDat(syn)
						table.insert(syndromes, syndat)
						table.insert(cache, syndat)
					end
				end
			end
			Chache.Items[object.subtype.id] = cache
		end
	end
	
	-- No valid syndromes found.
	if #syndromes == 0 then
		return nil
	end
	return syndromes
end

-- Adds a syndrome to the unit.
local function applySyndrome(syndat, unit)
	print("Item Syndrome Reborn: Applying syndrome: ("..syndat.syndrome.id..") to unit ("..unit.id..")")
	
	synutil.infectWithSyndromeIfValidTarget(unit, syndat.syndrome, synutil.ResetPolicy.ResetDuration)
end

-- Removes a syndrome from the unit.
local function removeSyndrome(syndat, unit)
	print("Item Syndrome Reborn: Removing syndrome: ("..syndat.syndrome.id..") from unit ("..unit.id..")")
	
	synutil.eraseSyndromes(unit, syndat.syndrome.id)
end

-- Removes all item syndromes from all units (even syndromes with the DO_NOT_REMOVE flag).
local function killSyndromes()
	for _, unit in ipairs(df.global.world.units.all) do
		synutil.eraseSyndromeClass(unit, "DFHACK_ITEM_SYNDROME")
	end
end

-- Is the item in the correct part of the unit's inventory for the syndrome to apply?
-- Basically makes sure the item inventory mode matches the syndrome flags.
local function itemInValidPosition(item_inv, syndat)
	return (item_inv ~= nil) and -- Item taken off
	((item_inv.mode == 0 and syndat.flags.AFFECTS_HAULER) or -- Item is hauled
	(item_inv.mode == 1 and syndat.flags.AFFECTS_WIELDER) or -- Item is wielded
	(item_inv.mode == 2 and syndat.flags.AFFECTS_WEARER) or -- Item is worn (clothing)
	(item_inv.mode == 7 and syndat.flags.AFFECTS_STUCKIN)) -- Item is stuckin
end

local function itemInventorySlot(unit, item)
	for inv_id, item_inv in ipairs(unit.inventory) do
		if item_inv.item.id == item.id then
			return item_inv
		end
	end
	return nil
end

local function applyItemSyndromes(unit, item)
	local item_inv = itemInventorySlot(unit, item)
	
	-- First handle the item directly
	local syndats = getObjectSyndromes(item, true)
	if syndats ~= nil then
		for _, syndat in ipairs(syndats) do
			if itemInValidPosition(item_inv, syndat) then
				applySyndrome(syndat, unit)
			else
				if not syndat.flags.DO_NOT_REMOVE then
					removeSyndrome(syndat, unit)
				end
			end
		end
	end
	
	-- Then handle any item contaminants.
	if item.contaminants then
		for _, contaminant in ipairs(item.contaminants) do
			local syndats = getObjectSyndromes(contaminant, false)
			if syndats ~= nil then
				for _, syndat in ipairs(syndats) do
					if itemInValidPosition(item_inv, syndat) then
						applySyndrome(syndat, unit)
					else
						if not syndat.flags.DO_NOT_REMOVE then
							removeSyndrome(syndat, unit)
						end
					end
				end
			end
		end
	end
end

local function handleInvChange(unit_id, item_id, old_equip, new_equip)
	local item = df.item.find(item_id)
    if not item then
		return
	end
    local unit = df.unit.find(unit_id)
    if unit.flags1.dead then
		return
	end
	
	applyItemSyndromes(unit, item)
end

local function applyAllItemSyndromes()
	for _, unit in ipairs(df.global.world.units.all) do
		for _, item_inv in ipairs(unit.inventory) do
			-- First handle the item directly
			local syndats = getObjectSyndromes(item_inv.item, true)
			if syndats ~= nil then
				for _, syndat in ipairs(syndats) do
					if itemInValidPosition(item_inv, syndat) then
						applySyndrome(syndat, unit)
					else
						if not syndat.flags.DO_NOT_REMOVE then
							removeSyndrome(syndat, unit)
						end
					end
				end
			end
			
			-- Then handle any item contaminants.
			if item_inv.item.contaminants then
				for _, contaminant in ipairs(item_inv.item.contaminants) do
					local syndats = getObjectSyndromes(contaminant, false)
					if syndats ~= nil then
						for _, syndat in ipairs(syndats) do
							if itemInValidPosition(item_inv, syndat) then
								applySyndrome(syndat, unit)
							else
								if not syndat.flags.DO_NOT_REMOVE then
									removeSyndrome(syndat, unit)
								end
							end
						end
					end
				end
			end
		end
	end
end

if ... == "enable" then
	print('Item Syndrome Reborn: Enabling.')
	eventful.enableEvent(eventful.eventType.INVENTORY_CHANGE, 5)
	eventful.onInventoryChange.ItemSyndromeReborn = handleInvChange
	
elseif ... == "disable" then
	print('Item Syndrome Reborn: Disabling.')
	eventful.onInventoryChange.ItemSyndromeReborn = nil
	
elseif ... == "kill" then
	print('Item Syndrome Reborn: Killing.')
	eventful.onInventoryChange.ItemSyndromeReborn = nil
	dfhack.onStateChange.ItemSyndromeReborn = nil
	Chache.Syndromes = {}
	Chache.Items = {}
	
	if dfhack.isWorldLoaded() then
		killSyndromes()
	end
	
elseif ... == "refresh" then
	print('Item Syndrome Reborn: Refreshing.')
	if dfhack.isWorldLoaded() then
		killSyndromes()
		applyAllItemSyndromes()
	else
		qerror("  World is not loaded!")
	end
	
elseif ... == "clear_cache" then
	print('Item Syndrome Reborn: Clearing the cache.')
	Chache.Syndromes = {}
	Chache.Items = {}

else
	print([==[
Item Syndrome Reborn: Usage:

itemSyndromeReborn enable
    Start periodically updating.

itemSyndromeReborn disable
    Stop periodically updating.
    This does not clear the syndrome data cache!

itemSyndromeReborn kill
    Stop periodically updating and remove all item syndromes from all units.
    Also clears the syndrome data cache.

itemSyndromeReborn refresh
    Removes all item syndromes and the runs a single update.
    Use to fix "stuck" syndromes (should never happen, but just in case).

itemSyndromeReborn clear_cache
    Clear the syndrome data cache.
]==])
end
