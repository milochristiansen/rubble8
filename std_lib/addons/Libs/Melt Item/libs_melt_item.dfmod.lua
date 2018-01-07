
_ENV = rubble.mkmodule("libs_melt_item")

local persist = rubble.require("libs_persist")

itemSizes = --RESULT_TABLE_HERE

reactions = --REACTION_TABLE_HERE

local function createBar(mat)
	local item = df['item_barst']:new()
	
	item.id = df.global.item_next_id
	df.global.world.items.all:insert('#',item)
	df.global.item_next_id = df.global.item_next_id+1
	
	item:setMaterial(mat.type)
	item:setMaterialIndex(mat.index)
	
	item:setMakerRace(df.global.ui.race_id)
	
	item:categorize(true)
	item:setDimension(150)
	return item
end

function meltMetalItem(item)
	local bars = {}
	
	local mat = dfhack.matinfo.decode(item)
	if mat == nil then
		return {}
	end
	local matstring = mat.type.."|"..mat.index
	
	local wafers = false
	if mat.mode == "inorganic" then
		wafers = mat.inorganic.flags.WAFERS
	end
	
	local item_type = item:getType()
	local item_stype = item:getSubtype()
	
	local item_mat_size = nil
	if item_stype ~= -1 then
		if itemSizes[item_type + 1][4] ~= nil then
			if itemSizes[item_type + 1][4][item.subtype.id] ~= nil then
				if wafers then
					item_mat_size = itemSizes[item_type + 1][4][item.subtype.id][2]
				else
					item_mat_size = itemSizes[item_type + 1][4][item.subtype.id][1]
				end
			end
		end
	end
	if item_mat_size == nil then
		if wafers then
			item_mat_size = itemSizes[item_type + 1][3]
		else
			item_mat_size = itemSizes[item_type + 1][2]
		end
	end
	
	if item.stack_size > 1 then
		item_mat_size = item_mat_size * item.stack_size
	end
	
	local product_number = 0
	local extra_parts = 0
	
	product_number, extra_parts = math.modf(item_mat_size)
	
	-- Adjust extra_parts to be a positive number between 0 and 999
	extra_parts, _ = math.modf(extra_parts * 1000)
	
	-- Create the specified number of bars
	if product_number > 0 then
		for p = 1, product_number, 1 do
			local bar = createBar(mat)
			bar.flags.removed = false
			table.insert(bars, bar)
		end
	end
	
	local parts_table = persist.GetAsCode("libs_dfhack_melt_item")
	
	-- Take care of any tail-ender bars
	local existing_parts = 0
	if parts_table ~= nil then
		existing_parts = parts_table[matstring] or 0
	else
		parts_table = {}
	end
	local parts = existing_parts + extra_parts
	
	-- 333 * 3 = 999
	if parts >= 999 then
		parts = parts - 1000
		if parts < 0 then parts = 0 end
		local bar = createBar(mat)
		bar.flags.removed = false
		table.insert(bars, bar)
	end
	
	parts_table[matstring] = parts
	local out = "return {\n"
	for k, v in pairs(parts_table) do
		out = out..'\t["'..k..'"] = '..v..',\n'
	end
	out = out.."}"
	persist.Save("libs_dfhack_melt_item", out)
	
	--print("Melt item debug:")
	--print("  Bars produced (before part calculations): "..product_number)
	--print("  Parts left from last reaction: "..existing_parts)
	--print("  Parts produced by this reaction: "..extra_parts)
	--print("  Parts left from this reaction: "..parts)
	return bars
end

-- This custom item melt reaction is a little more balanced than the vanilla one.
-- Instead of always producing a minimum of 1/10 of a bar a minimum of 1/1000 of a bar is produced.
-- Stacks of items are properly handled, a stack of 5 coins will produce exactly the same amount
-- of metal as 5 individual coins.
-- Bar returns are hard coded in a table instead of using a weird algorithm that has nothing to do
-- with the number of bars required to actually produce the item (which is what vanilla seems to do).
-- This makes most (if not all) melt-item exploits impossible.
-- Partial bars are shared globally by all smelters, so there is no need to restrict melting to one
-- smelter or anything like that. It is probably possible to use the hardcoded "melt_remainder" vector
-- for storing partial bars, but only for furnaces (and I need to use this with workshops).
function meltMetalItemHook(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
	call_native.value = false
	
	for i = 0, #in_reag - 1, 1 do
		if string.match(in_reag[i].code, '%_melt$') then
			local bars = meltMetalItem(in_items[i])
			for _, bar in ipairs(bars) do
				out_items:insert('#', bar)
			end
		end
	end
end

return _ENV
