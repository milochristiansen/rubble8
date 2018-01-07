
-- Powered Reaction: A system for recipe based powered workshops.
_ENV = rubble.mkmodule("reaction_libs_powered")

local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local punits = rubble.require "units_libs_powered"

--[=[
	recipes = {
		["ID"] = {
			-- Recipe Table
			{
				-- Custom should be something to pass to this workshop's global validate and pre
				-- functions. If you need a bag (for example) this is the place to let the global
				-- validate function know.
				custom = {}
				
				-- validate should return true if this recipe can work with the item being checked.
				-- This is a standard check function.
				validate = function(item) return false end,
				
				-- If this is not nil this many items must be found that pass validate before the
				-- recipe will run.
				amount = 1
				
				-- The following is two steps because it makes it easier to share behaviors across
				-- several recipes.
				
				-- Called just after the global pre function, this should create the output (if any)
				-- items is a table of all the input items.
				-- extra is the return value of the global pre function.
				-- output is the hardcoded output type for this workshop (normally "").
				output_item = function(items, wshop, extra, output) end,
				
				-- Called just after the output_item function, this should handle the input items
				-- (generally destroy them)
				-- items is a table of all the input items.
				-- extra is the return value of the global pre function.
				-- output is the hardcoded output type for this workshop (normally "").
				input_item = function(items, wshop, extra, output) end,
			},
		},
	}
]=]
recipes = {}

-- Adds a recipe to the registry.
-- See the comment above for the structure of the recipe table.
function AddRecipe(id, recipe)
	if recipe.validate == nil then
		recipe.validate = function(item) return false end
	end
	if recipe.output_item == nil then
		recipe.output_item = function(items, wshop, extra, output) return end
	end
	if recipe.input_item == nil then
		recipe.input_item = function(items, wshop, extra, output) return end
	end
	
	if recipes[id] == nil then
		recipes[id] = {}
	end
	
	table.insert(recipes[id], recipe)
end

local recipeSelection = function(wshop, data, possible_recipes, bad_items)
	-- This need ValidMat to keep items with invalid materials from causing problems (AFAIK this
	-- only effects some body parts, I don't know if there is a workaround).
	local filter = pfilter.ExcludeItems(bad_items, pfilter.ValidMat(pfilter.Not(data.black_list)))
	
	local item = pitems.FindItemAtInput(wshop, filter)
	if item == nil then
		return {ok = false, err = 'no_items'}
	end

	local items = {item}
	local found_items = {[item.id] = true}
	local mangle = nil
	for _, cnv in ipairs(possible_recipes) do
		if data.validate(wshop, cnv.custom) then
			if cnv.validate(item) then
				if cnv.amount == nil or cnv.amount == 1 then
					-- We only needed one item, we are done!
					return {ok = true, recipe = cnv, items = items}
				else
					-- We need a few more items...
					for i = 2, cnv.amount, 1 do
						local ei = pitems.FindItemAtInput(wshop, pfilter.ExcludeItems(found_items, filter))
						if ei == nil then
							return {ok = false, err = 'too_few', items = items}
						end
						found_items[ei.id] = true
						table.insert(items, ei)
					end
					return {ok = true, recipe = cnv, items = items}
				end
			end
		end
	end
	return {ok = false, err = 'no_recipe', items = items}
end

--[=[
	-- Workshop Data
	{
		-- validate, pre, and post are here so you can put common stuff that all recipes for this
		-- workshop will need in one place.
		
		-- Return true if this workshop operate at all (has needed items, etc).
		-- extra is the "custom" field of the recipe that is being contemplated.
		validate = function(wshop, extra) return true end,
		
		-- Do any setup required to run recipes at this workshop.
		-- extra is the "custom" field of the recipe that is being run (it is too late to abort here).
		-- return something to pass to post.
		pre = function(wshop, extra) return nil end,
		
		-- Cleanup after running a recipe at this workshop.
		-- extra is whatever pre returned.
		post = function(wshop, extra) end,
		
		-- Standard mangle function to use for any item that does not pass recipe selection.
		-- This function will not receive items that pass selection but cannot make up the recipe's
		-- required amount.
		mangle_item = function(wshop, item) end,
		
		-- If no item could be found (or they all passed black_list) then any creature unlucky
		-- enough to be on an input is passed over into this function's tender mercies.
		mangle_unit = function(wshop, unit) end,
		
		-- Items that pass this check are not considered for recipe selection (or mangling) at
		-- this workshop.
		black_list = function(item) return false end,
	}
]=]

-- Returns a handler function for the given workshop.
-- The id should be the same used when registering recipes.
-- data is the global workshop data, see above for information.
function MakeHandler(id, data)
	if data == nil then
		data = {}
	end
	if data.validate == nil then
		data.validate = function(wshop, extra) return true end
	end
	if data.pre == nil then
		data.pre = function(wshop, extra) return nil end
	end
	if data.post == nil then
		data.post = function(wshop, extra) end
	end
	if data.mangle_item == nil then
		data.mangle_item = function(wshop, item) return nil end
	end
	if data.mangle_unit == nil then
		data.mangle_unit = function(wshop, unit) return nil end
	end
	if data.black_list == nil then
		data.black_list = function(item) return false end
	end
	
	return function(output)
		return function(wshop)
			if pwshops.IsUnpowered(wshop) then
				return
			end
			if not pwshops.HasOutput(wshop) then
				return
			end
			if recipes[id] == nil then
				-- No recipes at all?
				-- Probably something is wrong, but oh well.
				return
			end
			
			local possible_recipes = {}
			for _, recipe in ipairs(recipes[id]) do
				if data.validate(wshop, recipe.custom) then
					table.insert(possible_recipes, recipe)
				end
			end
			
			if #possible_recipes == 0 then
				-- No recipes passed the global check, mangle a creature.
				local unit = punits.FindAtWorkshop(wshop)
				if unit ~= nil and pdisaster.EnabledUnits then
					data.mangle_unit(wshop, unit)
				end
				return
			end
			
			--[[
				Rant:
				
				Lua is such a screwed up language.
				
				Lets start with one based indexing. zero based indexing is done for a good reason, it
				makes bounds checks, loop conditions, etc much easier, plus there are several other
				things that become at least slightly easier to do with zero based indexing.
				
				And just about every other language (including C, which Lua is written in) uses zero
				based indexing, so that is what programmers are used to. Lua is intended to be an
				embedded language, so why not at least try to play nice with the host? For example
				with DFHack some values are one based (the Lua ones) and some are zero based (the
				native ones), this just introduces confusion and you end up having to fight the
				language to make things work when using native values.
				
				And the loops, those horrid loops. Lua has a fairly standard set of loops, nothing
				really wrong there. The problem is with break and continue. Oh, wait did I say continue?
				I mean LACK of continue! How can you make a programming language and forget continue?
				And how do you break out of a nested loop? even the simplest BASIC clone has a way
				to do multi-level breaks, maybe not a GOOD way, but A way.
				
				An of course talking about loops brings us back to one based indexing. If you have a
				zero based data structure of some kind and you need to iterate over it with a counted
				for loop you need to do some extra stuff because you can't just say "count up from
				zero as long as the counter is less than the length", counted for loops (the way Lua
				does them) actually work quite well, with one based indexing. The problem lies in the
				fact that about the only time you need to use a counted for loop is when you are
				iterating over something zero based.
				
				At least semicolons are optional, and multiple return values can be nice...
			]]
			
			local items = nil
			local recipe = nil
			local bad_items = {}
			while true do
				local rtn = recipeSelection(wshop, data, possible_recipes, bad_items)
				if rtn.ok then
					-- Yay! We found a recipe!
					items = rtn.items
					recipe = rtn.recipe
					break
				end
				
				if rtn.err == 'no_items' then
					-- No (non-black listed) items, go go mangle!
					local unit = punits.FindAtWorkshop(wshop)
					if unit ~= nil and pdisaster.EnabledUnits then
						data.mangle_unit(wshop, unit)
					end
					return
				elseif rtn.err == 'no_recipe' then
					-- Oh no! No recipe found, time for the mangler!
					
					-- But wait! First we need to see if the item would pass a recipe that is
					-- currently not possible (because it failed global validation).
					local passed = false
					if #recipes[id] ~= #possible_recipes then
						for _, recipe in ipairs(recipes[id]) do
							if recipe.validate(rtn.items[1]) then
								passed = true
								break
							end
						end
					end
					
					if not passed then
						if pdisaster.EnabledItems then
							data.mangle_item(wshop, rtn.items[1])
						end
						return
					else
						-- If the item passed a disabled recipe we treat it like we had too few
						-- items to run the recipe.
						bad_items[rtn.items[1].id] = true
					end
				elseif rtn.err == 'too_few' then
					-- We found an item that had a recipe, but we had too few, try again.
					for _, i in pairs(rtn.items) do
						bad_items[i.id] = true
					end
				end
			end
			
			-- OK, we have a recipe and an item.
			
			local extras = data.pre(wshop, recipe.custom)
			
			recipe.output_item(items, wshop, extras, output)
			
			recipe.input_item(items, wshop, extras, output)
			
			data.post(wshop, extras)
		end
	end
end

function DestroyInputs(items, wshop, extra, output)
	for _, item in ipairs(items) do
		dfhack.items.remove(item)
	end
end

function DoNothing(items, wshop, extra, output)
end

-- Part of a set of workshop functions for fuel handling.
function ValidateFuel(wshop, extra)
	magma, fuel = pitems.FindFuel(wshop)
	if not magma then
		if fuel == nil then
			return false
		end
	end
	return true
end

-- Part of a set of workshop functions for fuel handling.
function PreFuel(wshop, extra)
	_, fuel = pitems.FindFuel(wshop)
	return {
		coal = fuel,
	}
end

-- Part of a set of workshop functions for fuel handling.
function PostFuel(wshop, extra)
	if extra.coal ~= nil then
		dfhack.items.remove(extra.coal)
	end
end

-- Part of a set of workshop functions for fuel handling.
BlackListFuel = pfilter.Item("BAR:NONE", pfilter.Mat("COAL:NO_MAT_GLOSS"))

return _ENV
