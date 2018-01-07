
rubble.template("!ATTACH_INDUSTRY", [[
	local industry, hook = rubble.targs({...}, {"", ""})
	
	rubble.registry["Libs/Industry"].table[industry] = "t"
	rubble.registry["Libs/Industry:"..industry]:listappend(hook)
]])

rubble.usertemplate("!SHARED_INDUSTRY_REACTION", {{"id", ""}, {"class", ""}, {"raws", ""}},
	"{!SHARED_OBJECT;REACTION:%{id};\n"..
	"{INDUSTRY_REACTION;%{id};%{class}}\n"..
	"	%{raws}\n"..
	"}{!SHARED_OBJECT_CATEGORY;REACTION:%{id};REACTION}"
)

rubble.usertemplate("!SHARED_INDUSTRY_WORKSHOP", {{"id", ""}, {"class", ""}, {"raws", ""}},
	"{!SHARED_OBJECT;BUILDING_WORKSHOP:%{id};\n"..
	"{INDUSTRY_WORKSHOP;%{id};%{class}}\n"..
	"	%{raws}\n"..
	"}{!SHARED_OBJECT_CATEGORY;BUILDING_WORKSHOP:%{id};BUILDING_WORKSHOP}"
)

rubble.usertemplate("!SHARED_INDUSTRY_FURNACE", {{"id", ""}, {"class", ""}, {"raws", ""}},
	"{!SHARED_OBJECT;BUILDING_FURNACE:%{id};\n"..
	"{INDUSTRY_FURNACE;%{id};%{class}}\n"..
	"	%{raws}\n"..
	"}{!SHARED_OBJECT_CATEGORY;BUILDING_FURNACE:%{id};BUILDING_FURNACE}"
)

rubble.template("INDUSTRY_REACTION", [[
	local id, industry = rubble.targs({...}, {"", ""})
	
	if rubble.registry["Libs/Industry"].table[industry] ~= "t" then
		return "[REACTION:"..id.."]"
	end
	
	local data = rubble.registry["Libs/Industry:"..industry].list
	for _, hook in ipairs(data) do
		rubble.libs_base.reactionregister(id, hook)
	end
	return "[REACTION:"..id.."]"
]])

rubble.template("INDUSTRY_WORKSHOP", [[
	local id, industry = rubble.targs({...}, {"", ""})
	
	if rubble.registry["Libs/Industry"].table[industry] ~= "t" then
		return "[BUILDING_WORKSHOP:"..id.."]"
	end
	
	local data = rubble.registry["Libs/Industry:"..industry].list
	for _, hook in ipairs(data) do
		rubble.libs_base.buildingregister(id, hook)
	end
	return "[BUILDING_WORKSHOP:"..id.."]"
]])

rubble.template("INDUSTRY_FURNACE", [[
	local id, industry = rubble.targs({...}, {"", ""})
	
	if rubble.registry["Libs/Industry"].table[industry] ~= "t" then
		return "[BUILDING_FURNACE:"..id.."]"
	end
	
	local data = rubble.registry["Libs/Industry:"..industry].list
	for _, hook in ipairs(data) do
		rubble.libs_base.buildingregister(id, hook)
	end
	return "[BUILDING_FURNACE:"..id.."]"
]])
