
-- Define a new crate.
rubble.template("!CRATE", [[
	local id, name, value, product = rubble.targs({...}, {"", "", "", ""})
	
	local data = rubble.registry["Libs/Crates:!CRATE"]
	
	if data.table[id] ~= nil then
		rubble.error("Crate: "..id.." already exists.")
	else
		rubble.registry["Libs/Crates"].table["last"] = id
		data.table[id] = #data.list+1
		data:listappend(id)
		data:listappend(name)
		data:listappend(value)
		data:listappend(product)
		data:listappend("f")
	end
]])

-- Define a new crate (containing 10 bars).
rubble.template("!CRATE_BARS", [[
	local id, name, value, bar_mat = rubble.targs({...}, {"", "", "", ""})
	
	local data = rubble.registry["Libs/Crates:!CRATE"]
	
	if data.table[id] ~= nil then
		rubble.error("Crate: "..id.." already exists.")
	else
		rubble.registry["Libs/Crates"].table["last"] = id
		data.table[id] = #data.list+1
		data:listappend(id)
		data:listappend(name.." bars (10)")
		data:listappend(value)
		data:listappend(bar_mat)
		data:listappend("t")
	end
]])

-- Add last defined crate to class.
-- Crates may have more than one class, just call this template more than once.
-- !CRATE_CLASS class | !CRATE_CLASS id class
rubble.template("!CRATE_CLASS", [[
	local id, class, args = nil, nil, {...}
	if #args > 1 then
		id, class = rubble.targs(args, {"", ""})
	else
		id = rubble.registry["Libs/Crates"].table["last"]
		class = rubble.targs(args, {""})
	end
	
	rubble.registry["Libs/Crates:!CRATE_CLASS:"..class]:listappend(id)
]])

-- This generates a list of product lines for all crates, use in world gen reactions.
rubble.template("CRATE_WORLDGEN_REACTION_PRODUCTS", [[
	local out = ""
	for _, id in ipairs(rubble.registry["Libs/Crates:!CRATE"].list) do
		out = out.."\t[PRODUCT:100:1:BAR:NONE:CREATURE_MAT:LIBS_CRATES_CREATURE:"..id.."][PRODUCT_DIMENSION:150]\n"
	end
	return string.trimspace(out)
]])

-- This generates a list of product lines for a crate class, use in world gen reactions.
rubble.template("CRATE_WORLDGEN_REACTION_PRODUCTS_CLASSED", [=[
	local class = ...
	
	if not rubble.registry.exists["Libs/Crates:!CRATE_CLASS:"..class] then
		return "# Class: "..class.." Has no assigned crates."
	end
	
	local out = ""
	for _, id in ipairs(rubble.registry["Libs/Crates:!CRATE_CLASS:"..class].list) do
		out = out.."\t[PRODUCT:100:1:BAR:NONE:CREATURE_MAT:LIBS_CRATES_CREATURE:"..id.."][PRODUCT_DIMENSION:150]\n"
	end
	return string.trimspace(out)
]=])

-- Generate unpack reactions for all crates.
-- Example:
-- {CRATE_UNPACK_REACTIONS;CRAFTSMAN;CARPENTRY;ADDON_HOOK_PLAYABLE}
rubble.template("CRATE_UNPACK_REACTIONS", [[
	local building, skill, techclass, auto = rubble.targs({...}, {"", "", "", "true"})
	
	if auto == "true" then
		auto = "\t[AUTOMATIC]\n"
	else
		auto = ""
	end
	
	local data = rubble.registry["Libs/Crates:!CRATE"].list
	local out = ""
	for i = 1, #data, 5 do
		local id, name, product, bar = data[i], data[i + 1], data[i + 3], data[i + 4]
		
		if bar == "t" then
			out = out..
			"\n{REACTION;UNPACK_"..id..";"..techclass.."}\n"..
				"\t[NAME:unpack "..name.."]\n"..
				"\t[BUILDING:"..building..":NONE]\n"..
				"\t[REAGENT:A:150:BAR:NONE:CREATURE_MAT:LIBS_CRATES_CREATURE:"..id.."]\n"..
				"\t\t[HAS_MATERIAL_REACTION_PRODUCT:CRATE_"..id.."_MAT]\n"..
				"\t[SKILL:"..skill.."]\n"..
				"\t[PRODUCT:100:10:BAR:NONE:GET_MATERIAL_FROM_REAGENT:A:CRATE_"..id.."_MAT][PRODUCT_DIMENSION:150]\n"..
				auto
		else
			out = out..
			"\n{REACTION;UNPACK_"..id..";"..techclass.."}\n"..
				"\t[NAME:unpack "..name.."]\n"..
				"\t[BUILDING:"..building..":NONE]\n"..
				"\t[REAGENT:A:150:BAR:NONE:CREATURE_MAT:LIBS_CRATES_CREATURE:"..id.."]\n"..
				"\t[SKILL:"..skill.."]\n"..
				"\t"..product.."\n"..
				auto
		end
	end
	return string.trimspace(rubble.parse(out))
]])

-- Same as CRATE_UNPACK_REACTIONS, except for only a single crate class.
rubble.template("CRATE_UNPACK_REACTIONS_CLASSED", [[
	local building, skill, techclass, crateclass, auto = rubble.targs({...}, {"", "", "", "", "true"})
	
	if not rubble.registry.exists["Libs/Crates:!CRATE_CLASS:"..crateclass] then
		return "# Class: "..crateclass.." Has no assigned crates."
	end
	
	if auto == "true" then
		auto = "\t[AUTOMATIC]\n"
	else
		auto = ""
	end
	
	local out = ""
	local class_data = rubble.registry["Libs/Crates:!CRATE_CLASS:"..crateclass].list
	local data = rubble.registry["Libs/Crates:!CRATE"]
	for _, id in ipairs(class_data) do
		local i = data.table[id]
		local name, product, bar = data.list[i + 1], data.list[i + 3], data.list[i + 4]
		
		if bar == "t" then
			out = out..
			"\n{REACTION;UNPACK_"..id..";"..techclass.."}\n"..
				"\t[NAME:unpack "..name.."]\n"..
				"\t[BUILDING:"..building..":NONE]\n"..
				"\t[REAGENT:A:150:BAR:NONE:CREATURE_MAT:LIBS_CRATES_CREATURE:"..id.."]\n"..
				"\t\t[HAS_MATERIAL_REACTION_PRODUCT:CRATE_"..id.."_MAT]\n"..
				"\t[SKILL:"..skill.."]\n"..
				"\t[PRODUCT:100:10:BAR:NONE:GET_MATERIAL_FROM_REAGENT:A:CRATE_"..id.."_MAT][PRODUCT_DIMENSION:150]\n"..
				auto
		else
			out = out..
			"\n{REACTION;UNPACK_"..id..";"..techclass.."}\n"..
				"\t[NAME:unpack "..name.."]\n"..
				"\t[BUILDING:"..building..":NONE]\n"..
				"\t[REAGENT:A:150:BAR:NONE:CREATURE_MAT:LIBS_CRATES_CREATURE:"..id.."]\n"..
				"\t[SKILL:"..skill.."]\n"..
				"\t"..product.."\n"..
				auto
		end
	end
	return string.trimspace(rubble.parse(out))
]])

rubble.usertemplate("@CRATE_PRODUCT", {{"id", ""}, {"chance", "100"}, {"count", "1"}},
	"[PRODUCT:%{chance}:%{count}:BAR:NONE:CREATURE_MAT:LIBS_CRATES_CREATURE:%{id}][PRODUCT_DIMENSION:150]")

rubble.template("#CRATE_MATS", [[
	local data = rubble.registry["Libs/Crates:!CRATE"].list
	
	local out = ""
	for i = 1, #data, 5 do
		local id, name, value, product, bar = data[i], data[i + 1], data[i + 2], data[i + 3], data[i + 4]
		
		if bar == "t" then
			bar = "\t\t[MATERIAL_REACTION_PRODUCT:CRATE_"..id.."_MAT:"..product.."]\n"
		else
			bar = ""
		end
		
		out = out..
		"\n\t[USE_MATERIAL_TEMPLATE:"..id..":CRATE_TEMPLATE]\n"..
			"\t\t[STATE_NAME_ADJ:ALL_SOLID:"..name.." crate]\n"..
			"\t\t[STATE_NAME_ADJ:LIQUID:melted "..name.." crate]\n"..
			"\t\t[STATE_NAME_ADJ:GAS:boiling "..name.." crate]\n"..
			"\t\t[PREFIX:NONE]\n"..
			"\t\t[MATERIAL_VALUE:"..value.."]\n"..
			bar
	end
	return string.trimspace(out)
]])
