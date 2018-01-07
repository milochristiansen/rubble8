
-- This just supports basic castes, for more advanced abilities you can further specialize these templates.

-- TODO: Redesign this to use the shared script data registry.

rubble.libs_castes = {}
rubble.libs_castes.castes = {}
rubble.libs_castes.bonuses = {}
rubble.libs_castes.names = {}
rubble.libs_castes.names_plur = {}

rubble.libs_castes.creature_castes = {}
rubble.libs_castes.creature_desc = {}
rubble.libs_castes.creature_male = {}
rubble.libs_castes.creature_female = {}
rubble.libs_castes.creature_adj = {}

function rubble.libs_castes.registercreature(id, desc, male, female, adj)
	rubble.libs_castes.creature_castes[id] = {}
	rubble.libs_castes.creature_desc[id] = desc
	rubble.libs_castes.creature_male[id] = male
	rubble.libs_castes.creature_female[id] = female
	rubble.libs_castes.creature_adj[id] = adj
	
	rubble.libs_castes.castes[id] = {}
	rubble.libs_castes.bonuses[id] = {}
	rubble.libs_castes.names[id] = {}
	rubble.libs_castes.names_plur[id] = {}
end

function rubble.libs_castes.newcaste(creature, id, desc_name, name, name_plur, popm, popf, desc, bonus)
	if desc_name ~= "" then
		desc_name = "*"..desc_name.."* "
	end
	if desc ~= "" then
		desc = " "..desc
	end
	
	if rubble.libs_castes.castes[creature][id] == nil then
		table.insert(rubble.libs_castes.creature_castes[creature], id)
	end
	
	rubble.libs_castes.castes[creature][id] =
		"\t[CASTE:MALE_"..id.."]\n"..
		"\t\t[DESCRIPTION:"..desc_name..rubble.libs_castes.creature_desc[creature]..desc.."]\n"..
		"\t\t[POP_RATIO:"..popm.."]\n"..
		"\t[CASTE:FEMALE_"..id.."]\n"..
		"\t\t[DESCRIPTION:"..desc_name..rubble.libs_castes.creature_desc[creature]..desc.."]\n"..
		"\t\t[POP_RATIO:"..popf.."]\n"
	
	rubble.libs_castes.bonuses[creature][id] = bonus
	rubble.libs_castes.names[creature][id] = name
	rubble.libs_castes.names_plur[creature][id] = name_plur
end

rubble.template("!REGISTER_CREATURE", [[
	rubble.libs_castes.registercreature(rubble.targs({...}, {"", "", "", "", ""}))
]])

rubble.template("!DEFAULT_CASTE", [[
	rubble.libs_castes.newcaste(rubble.targs({...}, {"", "", "", "", "", "", "", "", ""}))
]])

rubble.template("CASTE", [[
	rubble.libs_castes.newcaste(rubble.targs({...}, {"", "", "", "", "", "", "", "", ""}))
]])

rubble.template("#CASTE_INSERT", [[
	local creature = (...) or ""
	
	if rubble.libs_castes.creature_castes[creature] == nil then
		rubble.abort "#CASTE_INSERT: Attempt to insert castes for creature that has no caste definitions."
	end
	
	local out = ""
	
	-- Caste Declarations
	out = out.."# Generated Castes\n"
	for _, id in ipairs(rubble.libs_castes.creature_castes[creature]) do
		out = out..rubble.libs_castes.castes[creature][id]
	end
	
	-- Set male/female info
	local m_castes = ""
	local f_castes = ""
	local once = true
	for _, id in ipairs(rubble.libs_castes.creature_castes[creature]) do
		if once then
			m_castes = m_castes.."\t[SELECT_CASTE:MALE_"..id.."]\n"
			f_castes = f_castes.."\t[SELECT_CASTE:FEMALE_"..id.."]\n"
			once = false
		else
			m_castes = m_castes.."\t[SELECT_ADDITIONAL_CASTE:MALE_"..id.."]\n"
			f_castes = f_castes.."\t[SELECT_ADDITIONAL_CASTE:FEMALE_"..id.."]\n"
		end
	end
	out = out.."\n"..m_castes.."\t\t"..rubble.libs_castes.creature_male[creature].."\n\n"..
		f_castes.."\t\t"..rubble.libs_castes.creature_female[creature]
	
	-- Set bonuses
	for _, id in ipairs(rubble.libs_castes.creature_castes[creature]) do
		out = out..
			"\n\n"..
			"\t[SELECT_CASTE:MALE_"..id.."]\n"..
			"\t[SELECT_ADDITIONAL_CASTE:FEMALE_"..id.."]\n"..
			"\t\t[CASTE_NAME:"..rubble.libs_castes.names[creature][id]..":"..
				rubble.libs_castes.names_plur[creature][id]..":"..rubble.libs_castes.creature_adj[creature].."]\n"..
			"\t\t"..rubble.libs_castes.bonuses[creature][id]
	end
	
	return out
]])
