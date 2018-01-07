
-- Adds the BUILD_KEY template

-- returns nil for invalid keys
local bkey_valid = {}
-- returns the key index in the order array
local bkey_index = {}
-- the key order, used for picking alternate keys
local bkey_order = {}

local bkey_used_w = rubble.registry["Libs/Base:@BUILD_KEY:F"]
local bkey_used_f = rubble.registry["Libs/Base:@BUILD_KEY:W"]

local letters = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
local mods = {"", "SHIFT_", "CTRL_", "ALT_"}

for _, char in ipairs(letters) do
	for _, prefix in ipairs(mods) do
		local key = prefix..char
		bkey_valid[key] = true
		table.insert(bkey_order, key)
		bkey_index[key] = #bkey_order
	end
end

for _, key in ipairs({
	"E",
	"Q",
	"SHIFT_M",
	"O",
	"K",
	"B",
	"C",
	"F",
	"V",
	"J",
	"M",
	"U",
	"N",
	"R",
	"S",
	"T",
	"L",
	"W",
	"Z",
	"H",
	"Y",
	"D",
}) do
	bkey_used_w.table[key] = "t"
end

for _, key in ipairs({
	"W",
	"S",
	"G",
	"K",
	"L",
	"A",
	"N",
}) do
	bkey_used_f.table[key] = "t"
end

function rubble.libs_base.clear_key(key, furnace)
	local used_list
	if furnace then
		used_list = bkey_used_f.table
	else
		used_list = bkey_used_w.table
	end
	
	if not bkey_valid[key] then
		rubble.abort("Invalid key: "..key)
	end
	
	used_list[key] = "f"
end

rubble.template("@CLEAR_KEY", [[
	local key, furnace = rubble.targs({...}, {"", "false"})
	furnace = furnace ~= "false"
	
	rubble.libs_base.clear_key(key, furnace)
]])

function rubble.libs_base.build_key(key, furnace)
	local used_list
	if furnace then
		used_list = bkey_used_f.table
	else
		used_list = bkey_used_w.table
	end
	
	if not bkey_valid[key] then
		rubble.abort("Invalid key: "..key)
	end
	
	if used_list[key] == "t" then
		local wrap = false
		local next_index = bkey_index[key] + 1
		if next_index > #bkey_order then
			wrap = true
			next_index = 1
		end
		local next_key = bkey_order[next_index]
		
		while true do
			if used_list[next_key] == "t" then
				next_index = bkey_index[next_key] + 1
				if next_index > #bkey_order then
					if wrap then
						rubble.abort("Cannot find valid key, all keys used?!!")
					end
					wrap = true
					next_index = 1
				end
				next_key = bkey_order[next_index]
			else
				key = next_key
				break
			end
		end
	end
	
	used_list[key] = "t"
	return "[BUILD_KEY:CUSTOM_"..key.."]"
end

rubble.template("@BUILD_KEY", [[
	local key, furnace = rubble.targs({...}, {"", "false"})
	furnace = furnace ~= "false"
	
	return rubble.libs_base.build_key(key, furnace)
]])
