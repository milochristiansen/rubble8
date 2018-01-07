
-- Item filter functions, these are commonly used under the "filter_libs_powered" alias.
_ENV = rubble.mkmodule("libs_items_filter")

local items = rubble.require "libs_items"

--[=[
All functions except Null and Dummy return filters, Null and Dummy are filters, and as such are used directly.

-- Examples:

-- These examples will all return a filter function when called, this function takes a single item as a parameter and
-- returns true if it matches the filter and false otherwise.

-- The Dummy and Null functions are special in that they are filters, not filter constructors. Simply use them directly.
-- Dummy and Null seem useless, but they are nice when working with more complicated APIs that use filters, for example
-- they are commonly used when working with the powered workshop reaction system provided by "Libs/DFHack/Powered"
-- (although in that case you will probably want to use the filter API provided by that addon, as it may have some extra
-- extensions added).

-- Matches an empty bag
filter.Bag(filter.Empty())

-- Matches a sand bag
filter.Bag(filter.Contains(function(item)
	return item:isSand()
end))

-- Matches any item made of stone or metal
filter.Or{
	filter.MatFlag("IS_STONE"),
	filter.MatFlag("IS_METAL")
}

-- Matches cut stones (but not cut gems or cut glass)
filter.Item("SMALLGEM:NONE", filter.MatFlag("IS_STONE", filter.Not(filter.MatFlag("IS_GEM"))))

-- Matches a granite boulder
filter.Item("BOULDER:NONE", filter.Mat("INORGANIC:GRANITE"))

-- Any clay boulder
filter.Item("BOULDER:NONE", filter.MRP("FIRED_MAT"))

-- How to use a filter:

-- Is "item" an empty bag?
local bagfilter = filter.Bag(filter.Empty())
local isemptybag = bagfilter(item)


]=]

-- The dummy filter, always returns true.
-- Use for the rare case where you need a valid filter but don't actually want to filter anything.
function Dummy(item)
	return true
end

-- The null filter, always returns false.
-- Use for the rare case where you need a filter that matches nothing.
function Null(item)
	return false
end

-- Returns a check function that inverts the provided filter.
function Not(filter)
	return function(item)
		return not filter(item)
	end
end

-- Returns a check function that ANDs several filters.
function And(tbl)
	return function(item)
		for _, filter in ipairs(tbl) do
			if not filter(item) then
				return false
			end
		end
		return true
	end
end

-- Returns a check function that ORs several filters.
function Or(tbl)
	return function(item)
		for _, filter in ipairs(tbl) do
			if filter(item) then
				return true
			end
		end
		return false
	end
end

-- Returns a check function that blocks any items that have a true entry in the ids table where the
-- item id is the index. Use to avoid items you have already found.
-- The last argument is an optional extra filter to allow chaining.
function ExcludeItems(ids, filter)
	return function(item)
		if ids[item.id] == true then
			return false
		end
		
		if filter ~= nil then
			return filter(item)
		end
		return true
	end
end

-- Returns a check function that eliminates all items that do not have a valid material
-- (dfhack.matinfo.decode returns nil, and yes that is possible with some body parts).
-- The last argument is an optional extra filter to allow chaining.
function ValidMat(filter)
	return function(item)
		if dfhack.matinfo.decode(item) == nil then
			return false
		end
		
		if filter ~= nil then
			return filter(item)
		end
		return true
	end
end

-- Returns a check function that discriminates based on the material flags ("WOOD", "IS_METAL", etc).
-- The last argument is an optional extra filter to allow chaining.
function MatFlag(flag, filter)
	return function(item)
		local mat = dfhack.matinfo.decode(item)
		if mat == nil then
			return false
		end
		
		if not mat.material.flags[flag] then
			return false
		end
		
		if filter ~= nil then
			return filter(item)
		end
		return true
	end
end

-- Returns a check function that discriminates based on the presence of a material reaction product.
-- The last argument is an optional extra filter to allow chaining.
function MRP(product, filter)
	return function(item)
		if items.GetMRP(product, dfhack.matinfo.decode(item)) == nil then
			return false
		end
		
		if filter ~= nil then
			return filter(item)
		end
		return true
	end
end

-- Returns a check function that discriminates based on the presence of a reaction class.
-- The last argument is an optional extra filter to allow chaining.
function RC(class, filter)
	return function(item)
		if items.HasRClass(class, dfhack.matinfo.decode(item)) == nil then
			return false
		end
		
		if filter ~= nil then
			return filter(item)
		end
		return true
	end
end

-- Returns a check function that discriminates based on item material.
-- The last argument is an optional extra filter to allow chaining.
function Mat(mat, filter)
	local mata = dfhack.matinfo.find(mat)
	if mata == nil then
		error("Invalid material for Mat filter.")
	end
	
	return function(item)
		if mata ~= nil and mata.type ~= -1 then
			local matb = dfhack.matinfo.decode(item)
			if matb == nil then
				return false
			end
			
			if mata.type ~= matb.type then
				return false
			end
			
			if mata.index ~= -1 then
				if mata.index ~= matb.index then
					return false
				end
			end
		end
		
		if filter ~= nil then
			return filter(item)
		end
		return true
	end
end

-- Returns a check function that discriminates based on item type.
-- The last argument is an optional extra filter to allow chaining.
function Item(item, filter)
	local itype = dfhack.items.findType(item)
	local istype = dfhack.items.findSubtype(item)
	
	return function(item)
		if itype ~= -1 then
			if item:getType() ~= itype then
				return false
			end
			
			if istype ~= -1 then
				if item:getSubtype() ~= istype then
					return false
				end
			end
		end
		
		if filter ~= nil then
			return filter(item)
		end
		return true
	end
end

-- Returns a check function for a container that contains an item that matches the filter.
function Contains(filter)
	if filter == nil then
		error "Nil filter in required context."
	end
	
	return function(item)
		local contents = dfhack.items.getContainedItems(item)
		if contents ~= nil and #contents ~= 0 then
			for _, v in pairs(contents) do
				if filter(v) then
					return true
				end
			end
		end
		return false
	end
end

-- Returns a check function that matches empty containers (may match non-containers as well, untested).
-- The last argument is an optional extra filter to allow chaining.
function Empty(filter)
	return function(item)
		local contents = dfhack.items.getContainedItems(item)
		if contents ~= nil and #contents ~= 0 then
			return false
		end
		
		if filter ~= nil then
			return filter(item)
		end
		return true
	end
end

-- Returns a check function for a bag.
-- The last argument is an optional extra filter to allow chaining.
function Bag(filter)
	return function(item)
		if not item:isBag() then
			return false
		end
		
		if filter ~= nil then
			return filter(item)
		end
		return true
	end
end

-- Returns a check function for a barrel/pot (any food storage container).
-- The last argument is an optional extra filter to allow chaining.
function Barrel(filter)
	return function(item)
		if not item:isFoodStorage() then
			return false
		end
		
		if filter ~= nil then
			return filter(item)
		end
		return true
	end
end

-- Returns a check function for a jug (or any tool with the LIQUID_CONTAINER use).
-- This is a convenience for calling Tool with the LIQUID_CONTAINER use.
-- The last argument is an optional extra filter to allow chaining.
function Jug(filter)
	return Tool("LIQUID_CONTAINER", filter)
end

-- Returns a check function for an item that has a specific tool use.
-- The last argument is an optional extra filter to allow chaining.
function Tool(use, filter)
	return function(item)
		if not item:hasToolUse(df.tool_uses[use]) then
			return false
		end
		
		if filter ~= nil then
			return filter(item)
		end
		return true
	end
end

-- Returns a check function for an item that can rot.
-- This only filters items that powered.disaster will rot with its RotItem function.
-- The last argument is an optional extra filter to allow chaining.
function Rots(filter)
	return function(item)
		local mat = dfhack.matinfo.decode(item)
		if mat == nil then
			return false
		end
		
		local itemname = df.item_type[item:getType()]:lower()
		if mat.material.flags.ROTS and (itemname == 'corpsepiece' or itemname == 'corpse' or itemname == 'remains') then
			if filter ~= nil then
				return filter(item)
			end
			return true
		end
		return false
	end
end

return _ENV
