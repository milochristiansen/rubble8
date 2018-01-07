
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local preact = rubble.require "reaction_libs_powered"

function createMeal(subtyp, i1, i2, i3, i4, wshop)
	local item = df['item_foodst']:new()
	
	item.id = df.global.item_next_id
	df.global.world.items.all:insert('#',item)
	df.global.item_next_id = df.global.item_next_id + 1
	
	item.entity = -1
	item.recipe_id = -1
	
	item:setSubtype(subtyp)
	
	local ssize = 0
	if i1 ~= nil then
		local i = i1
		ssize = ssize + i.stack_size
		local imat = dfhack.matinfo.decode(i)
		item.ingredients:insert('#', {
			new = true,
			anon_1 = 0,
			item_type = i:getType(),
			unk_4 = -1,
			mat_type = imat.type,
			mat_index = imat.index,
			maker = -1,
			unk_10 = pitems.AutoQuality(wshop),
			unk_14 = 0,
			unk_18 = -1,
		})
	end
	
	if i2 ~= nil then
		local i = i2
		ssize = ssize + i.stack_size
		local imat = dfhack.matinfo.decode(i)
		item.ingredients:insert('#', {
			new = true,
			anon_1 = 0,
			item_type = i:getType(),
			unk_4 = -1,
			mat_type = imat.type,
			mat_index = imat.index,
			maker = -1,
			unk_10 = pitems.AutoQuality(wshop),
			unk_14 = 0,
			unk_18 = -1,
		})
	end
	
	if i3 ~= nil then
		local i = i3
		ssize = ssize + i.stack_size
		local imat = dfhack.matinfo.decode(i)
		item.ingredients:insert('#', {
			new = true,
			anon_1 = 0,
			item_type = i:getType(),
			unk_4 = -1,
			mat_type = imat.type,
			mat_index = imat.index,
			maker = -1,
			unk_10 = pitems.AutoQuality(wshop),
			unk_14 = 0,
			unk_18 = -1,
		})
	end
	
	if i4 ~= nil then
		local i = i4
		ssize = ssize + i.stack_size
		local imat = dfhack.matinfo.decode(i)
		item.ingredients:insert('#', {
			new = true,
			anon_1 = 0,
			item_type = i:getType(),
			unk_4 = -1,
			mat_type = imat.type,
			mat_index = imat.index,
			maker = -1,
			unk_10 = pitems.AutoQuality(wshop),
			unk_14 = 0,
			unk_18 = -1,
		})
	end
	
	item.stack_size = ssize
	
	item:setQuality(pitems.AutoQuality(wshop))
	
	item:setMakerRace(df.global.ui.race_id)
	
	item:categorize(true)
	item.flags.removed = true
	return item
end

preact.AddRecipe("DFHACK_POWERED_FOOD_PROCESSOR", {
	validate = pfilter.Or{
		pfilter.MatFlag("EDIBLE_COOKED"),
		pfilter.Contains(pfilter.MatFlag("EDIBLE_COOKED")),
	},
	amount = 3,
	input_item = preact.DestroyInputs,
	output_item = function(items, wshop, extras)
		-- Sanity check
		if #items ~= 3 then
			error "Powered Food Processor: Invalid item count (should be impossible)."
		end
		
		local cookable = pfilter.MatFlag("EDIBLE_COOKED")
		local empty = pfilter.Empty()
		
		local i1 = items[1]
		if not cookable(i1) then
			i1 = pitems.FindItemIn(i1, cookable)
			if empty(items[1]) then
				pitems.Eject(wshop, items[1])
			end
		end
		
		local i2 = items[2]
		if not cookable(i2) then
			i2 = pitems.FindItemIn(items[2], cookable)
			if empty(items[2]) then
				pitems.Eject(wshop, items[2])
			end
		end
		
		local i3 = items[3]
		if not cookable(i3) then
			i3 = pitems.FindItemIn(items[3], cookable)
			if empty(items[3]) then
				pitems.Eject(wshop, items[3])
			end
		end
		
		local subtyp = dfhack.items.findSubtype("FOOD:ITEM_FOOD_PROCESSED")
		local meal = createMeal(subtyp, i1, i2, i3, nil, wshop)
		pitems.Eject(wshop, meal)
	end,
})

pwshops.Register("DFHACK_POWERED_FOOD_PROCESSOR", nil, 20, 0, 500, preact.MakeHandler("DFHACK_POWERED_FOOD_PROCESSOR", {
	mangle_item = pdisaster.Switch({
		-- If the item is not hard then 1% chance of damage and rot it if possible, else pass it.
		{pfilter.Not(pfilter.MatFlag("ITEMS_HARD")), pdisaster.Damage(1, pdisaster.RotItem(pdisaster.PassItem))},
		
		-- Any other (invalid) item gives a 10% chance of damage, and the item is passed.
		{pfilter.Dummy, pdisaster.Damage(10, pdisaster.PassItem)},
	}),
	mangle_unit = pdisaster.MangleCreature,
}))
