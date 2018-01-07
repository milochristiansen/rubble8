
_ENV = mkmodule("libs_random")

source = source or rubble.random()

local seed = rubble.configvar("LIBS_RANDOM_SEED")
if seed ~= "" then
	source.seed = seed
else
	seed = source.seed -- Reading the seed key returns a "good enough" default seed value based on the time.
	rubble.configvar("LIBS_RANDOM_SEED", seed)
	source.seed = seed
end

-- Returns a number between 0 and n inclusive
function int(n)
	if n <= 0 then
		return 0
	end
	return source:intn(n)
end

-- Returns a number between min and max inclusive
function range(min, max)
	local range = max - min
	if range <= 0 then
		return min
	end
	
	return source:intn(range) + min
end

function chance(percent)
	return range(1, 100) <= percent
end

-- Select a random item from a table.
-- If idx is true then return the item's index instead of the item.
function select(tbl, idx)
	if tbl == nil or not next(tbl) then
		return nil
	end
	
	-- Build a list of the keys in a fixed order. The exact order of the keys does
	-- not matter, so long as it is always the same from Rubble run to Rubble run.
	local keys = {}
	for k, _ in pairs(tbl) do
		table.insert(keys, k)
	end
	table.sort(keys)
	
	local i = range(1, #keys)
	if idx then
		return keys[i]
	else
		return tbl[keys[i]]
	end
end

-- Select a random item from a table based on a weight number.
-- If "idx" is true return the item index instead of the item.
-- If "weighter" is non-nil it should be a function that takes an item and index and returns the weight.
-- The default weighter uses the "weight" key if the item is a table, else it converts the item to
-- a number and uses that.
function select_weighted(tbl, idx, weighter)
	if tbl == nil or not next(tbl) then
		return nil
	end
	
	if weighter == nil then
		weighter = function(item, index)
			local weight
			if type(item) == "table" then
				weight = tonumber(item.weight)
				if weight == nil then
					error("Invalid weight value: item.weight = "..tostring(item.weight))
				end
			else
				weight = tonumber(item)
				if weight == nil then
					error("Invalid weight value: item = "..tostring(item))
				end
			end
			
			return weight
		end
	end
	
	-- This is probably not the best way to do this...
	
	local total_weight = 0
	local weights = {}
	local keys = {} -- See select ^^^
	for k, v in pairs(tbl) do
		weights[k] = weighter(v, k)
		total_weight = total_weight + weights[k]
		table.insert(keys, k)
	end
	table.sort(keys)
	
	local selection = range(1, total_weight)
	local weight = 0
	for _, k in pairs(keys) do
		local v = tbl[k]
		weight = weight + weights[k]
		if weight >= selection then
			if idx then
				return k
			else
				return v
			end
		end
	end
	return nil
end

return _ENV
