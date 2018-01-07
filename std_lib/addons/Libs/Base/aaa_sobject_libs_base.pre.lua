
-- SHARED_OBJECT, the single most important template in all of Rubble,
-- also a bunch of related templates.

rubble.template("!SHARED_OBJECT", [[
	local id, raws = rubble.targs({...}, {"", ""})
	
	local data = rubble.registry["Libs/Base:!SHARED_OBJECT"].table
	
	if data[id] ~= nil then
		rubble.parse(raws)
		return ""
	else
		data[id] = rubble.parse(raws)
		return "{_INSERT_SHARED_OBJECT;"..id.."}"
	end
]])

rubble.template("!SHARED_OBJECT_DUPLICATE", [[
	local oid, nid, edit, cat = rubble.targs({...}, {"", "", "true", "true"})
	
	local data = rubble.registry["Libs/Base:!SHARED_OBJECT"].table
	
	if data[oid] == nil then
		rubble.abort("Call to !SHARED_OBJECT_DUPLICATE trying to duplicate an object that does not exist. Make sure this template is parsed *after* the object you want to extend.")
	end
	
	if data[nid] ~= nil then
		return ""
	end
	
	local raws = data[oid]
	if edit == "true" then
		-- First try to determine if the new ID is a standard two part ID.
		local type, id = "", nid
		local parts = string.split(nid, ":")
		if #parts == 2 then
			type, id = parts[1], parts[2]
		elseif #parts ~= 1 then
			-- Invalid, and not a standard two part ID, fail.
			rubble.error("New object ID passed to !SHARED_OBJECT_DUPLICATE was not a valid two part ID and was not a valid raw tag parameter, thus the raw auto-correction feature failed. You may need to disable raw auto-correction for this template call and correct the object raws manually.")
		end
		
		-- Replace the first tag in the object with a new one.
		local tags = rubble.rparse.parse(raws)
		for _, tag in ipairs(tags) do
			if not tag.CommentsOnly then
				if tag.ID ~= type then
					rubble.error("New object ID passed to !SHARED_OBJECT_DUPLICATE appears to be a standard two part ID, but the type did not match the type of the object being duplicated. You may need to disable raw auto-correction for this template call and correct the object raws manually.")
				end
				tag.Params[1] = id
				break
			end
		end
		raws = rubble.rparse.format(tags)
		
		if cat == "true" then
			local data = rubble.registry["Libs/Base:!SHARED_OBJECT_CATEGORY:"..type]
			data:listappend(nid)
			data.table[nid] = "t"
		end
	end
	
	data[nid] = raws
	return "{_INSERT_SHARED_OBJECT;"..nid.."}"
]])

local soexist = [[
	local id, t, e = rubble.targs({...}, {"", "", ""})
	
	local data = rubble.registry["Libs/Base:!SHARED_OBJECT"].table
	
	if data[id] ~= nil then
		return rubble.parse(t)
	end
	return rubble.parse(e)
]]
rubble.template("SHARED_OBJECT_EXISTS", soexist)
rubble.template("#SHARED_OBJECT_EXISTS", soexist)

rubble.template("SHARED_OBJECT_DELETE", function(id)
	id = rubble.expandargs(id)
	
	local data = rubble.registry["Libs/Base:!SHARED_OBJECT"].table
	if data[id] ~= nil then
		data[id] = ""
	end
	data = rubble.registry["Libs/Base:SHARED_OBJECT_ADD"].table
	if data[id] ~= nil then
		data[id] = ""
	end
	
	for _, cat in ipairs(rubble.registry["Libs/Base:!SHARED_OBJECT_CATEGORY"].list) do
		if rubble.registry.exists["Libs/Base:!SHARED_OBJECT_CATEGORY:"..cat] then
			rubble.registry["Libs/Base:!SHARED_OBJECT_CATEGORY:"..cat].table[id] = "f"
		end
	end
	
	rubble.registry["Libs/Base:SHARED_OBJECT_DELETE"].table[id] = "t"
end)

function rubble.libs_base.sharedobject_walk(id, action)
	local data = rubble.registry["Libs/Base:!SHARED_OBJECT"].table
	if data[id] == nil then
		return
	end
	
	local tags = rubble.rparse.parse(data[id])
	for _, tag in ipairs(tags) do
		action(tag)
	end
	data[id] = rubble.rparse.format(tags)
end

function rubble.libs_base.matchtag(tag, match)
	if tag.CommentsOnly then
		return false
	end
	
	if #match ~= 1 and #match-1 > #tag.Params then
		return false
	end
	
	if match[1] ~= tag.ID then
		return false
	end
	
	for i = 2, #match, 1 do
		if match[i] ~= "&" and match[i] ~= tag.Params[i-1] then
			return false
		end
	end
	return true
end

rubble.template("SHARED_OBJECT_KILL_TAG", [[
	local id, target = rubble.targs({...}, {"", ""})
	target = string.split(target, ":")
	
	rubble.libs_base.sharedobject_walk(id, function(tag)
		if rubble.libs_base.matchtag(tag, target) then
			local repl = "-"..tag.ID
			for _, v in ipairs(tag.Params) do
				repl = repl..":"..v
			end
			tag.Comments = repl.."-"..tag.Comments
			tag.CommentsOnly = true
		end
	end)
]])

rubble.template("SHARED_OBJECT_REPLACE_TAG", [[
	local id, target, repl = rubble.targs({...}, {"", "", ""})
	target = string.split(target, ":")
	
	rubble.libs_base.sharedobject_walk(id, function(tag)
		if rubble.libs_base.matchtag(tag, target) then
			tag.Comments = repl..tag.Comments
			tag.CommentsOnly = true
		end
	end)
]])

rubble.template("SHARED_OBJECT_MERGE", [[
	local id, rules, source = rubble.targs({...}, {"", "", ""})
	
	local data = rubble.registry["Libs/Base:!SHARED_OBJECT"].table
	if data[id] == nil then
		return
	end
	data[id] = rubble.rawmerge(rules, source, data[id])
]])

function rubble.libs_base.sharedobject_add(id, raws)
	local data = rubble.registry["Libs/Base:SHARED_OBJECT_ADD"].table
	
	data[id] = (data[id] or "").."\n\t"..rubble.parse(raws)
	return
end

rubble.template("SHARED_OBJECT_ADD", [[
	rubble.libs_base.sharedobject_add(rubble.targs({...}, {""}))
]])
rubble.template("REGISTER_REACTION_CLASS", [[
	local id, class = rubble.targs({...}, {"", ""})
	rubble.libs_base.sharedobject_add(id, "[REACTION_CLASS:"..class.."]")
]])
rubble.template("REGISTER_REACTION_PRODUCT", [[
	local id, class, mat = rubble.targs({...}, {"", "", ""})
	rubble.libs_base.sharedobject_add(id, "[MATERIAL_REACTION_PRODUCT:"..class..":"..mat.."]")
]])

rubble.template("_INSERT_SHARED_OBJECT", [[
	local id = rubble.targs({...}, {""})
	
	local data = rubble.registry["Libs/Base:!SHARED_OBJECT"].table
	data[id] = rubble.parse(data[id] or "")
	
	return "{#_INSERT_SHARED_OBJECT;"..id.."}"
]])

rubble.template("#_INSERT_SHARED_OBJECT", [[
	local id = rubble.targs({...}, {""})
	
	if rubble.registry["Libs/Base:SHARED_OBJECT_DELETE"].table[id] == "t" then
		return "Object "..id.."deleted."
	end
	
	local out = rubble.parse(rubble.registry["Libs/Base:!SHARED_OBJECT"].table[id])
	local add_data = rubble.registry["Libs/Base:SHARED_OBJECT_ADD"].table
	if add_data[id] ~= "" then
		out = out..rubble.parse(add_data[id] or "")
	end
	return out
]])

rubble.template("!SHARED_OBJECT_CATEGORY", [[
	local id, cat = rubble.targs({...}, {""})
	
	if rubble.registry["Libs/Base:!SHARED_OBJECT"].table[id] == nil then
		rubble.error("Shared object: "..id.." Does not exist.")
	end
	
	local data = rubble.registry["Libs/Base:!SHARED_OBJECT_CATEGORY"]
	data:listappend(cat)
	
	data = rubble.registry["Libs/Base:!SHARED_OBJECT_CATEGORY:"..cat]
	
	if data.table[id] == nil then
		data:listappend(id)
	end
	data.table[id] = "t"
]])

-- Returns a sequence listing all shared objects in a certain category.
-- List order is deterministic (in this case it follows declaration order).
-- If category does not exist returns nil.
function rubble.libs_base.sharedobject_listcategory(cat)
	if rubble.registry.exists["Libs/Base:!SHARED_OBJECT_CATEGORY:"..cat] then
		local rtn = {}
		local data = rubble.registry["Libs/Base:!SHARED_OBJECT_CATEGORY:"..cat]
		for _, k in ipairs(data.list) do
			if data.table[k] == "t" then
				table.insert(rtn, k)
			end
		end
		return rtn
	end
	return nil
end

function rubble.libs_base.sharedobject_incategory(id, cat)
	if rubble.registry.exists["Libs/Base:!SHARED_OBJECT_CATEGORY:"..cat] then
		local ok = rubble.registry["Libs/Base:!SHARED_OBJECT_CATEGORY:"..cat].table[id]
		return ok ~= nil and ok == "t"
	end
	return nil -- So you can tell a missing category from a item that is not listed.
end

-- Specialized versions of SHARED_OBJECT

local variants = {
	"CREATURE",
	"PLANT",
	"INORGANIC",
	"MATERIAL_TEMPLATE",
	"CREATURE_VARIATION",
	"TISSUE_TEMPLATE",
	"BODY_DETAIL_PLAN",
	"INTERACTION",
	"BODY",
	"TRANSLATION",
	"SYMBOL",
	"WORD",
	"COLOR",
	"COLOR_PATTERN",
	"SHAPE",
}

for _, v in ipairs(variants) do
	rubble.usertemplate("!SHARED_"..v, {{"id", ""}, {"raws", ""}},
		"{!SHARED_OBJECT;"..v..":%{id};\n"..
		"["..v..":%{id}]\n"..
		"	%{raws}\n"..
		"}{!SHARED_OBJECT_CATEGORY;"..v..":%{id};"..v.."}"
	)
end

rubble.usertemplate("!SHARED_REACTION", {{"id", ""}, {"class", ""}, {"raws", ""}},
	"{!SHARED_OBJECT;REACTION:%{id};\n"..
	"{REACTION;%{id};%{class}}\n"..
	"	%{raws}\n"..
	"}{!SHARED_OBJECT_CATEGORY;REACTION:%{id};REACTION}"
)

rubble.usertemplate("!SHARED_BUILDING_WORKSHOP", {{"id", ""}, {"class", ""}, {"raws", ""}},
	"{!SHARED_OBJECT;BUILDING_WORKSHOP:%{id};\n"..
	"{BUILDING_WORKSHOP;%{id};%{class}}\n"..
	"	%{raws}\n"..
	"}{!SHARED_OBJECT_CATEGORY;BUILDING_WORKSHOP:%{id};BUILDING_WORKSHOP}"
)

rubble.usertemplate("!SHARED_BUILDING_FURNACE", {{"id", ""}, {"class", ""}, {"raws", ""}},
	"{!SHARED_OBJECT;BUILDING_FURNACE:%{id};\n"..
	"{BUILDING_FURNACE;%{id};%{class}}\n"..
	"	%{raws}\n"..
	"}{!SHARED_OBJECT_CATEGORY;BUILDING_FURNACE:%{id};BUILDING_FURNACE}"
)

rubble.usertemplate("!SHARED_ENTITY", {{"id", ""}, {"fort", ""}, {"adv", ""}, {"raws", ""}},
	"{!SHARED_OBJECT;ENTITY:%{id};\n"..
	"[ENTITY:%{id}]\n"..
	"	{!ENTITY_PLAYABLE;%{id};%{fort};%{adv}}\n"..
	"	%{raws}\n"..
	"}{!SHARED_OBJECT_CATEGORY;ENTITY:%{id};ENTITY}"
)

-- SHARED_ITEM has it's own file.
