
-- Templates used in the base

rubble.libs_base = {}

rubble.template("!TEMPLATE", [[
local args = {...}

local targs = {}
for i = 2, #args - 1, 1 do
	local parts = string.split(args[i], "=", 2)
	
	-- Leading/trailing white space is striped by rubble.usertemplate
	table.insert(targs, {parts[1], parts[2] or ""})
end

rubble.usertemplate(args[1], targs, args[#args])
]])

-- The comment templates, very simple, just do nothing.
rubble.template("COMMENT", [[return ""]])
rubble.template("C", [[return ""]])

local void = [[
	local args = rubble.targs{...}
	for _, v in ipairs(args) do
		rubble.parse(v, -1)
	end
]]
rubble.template("@VOID", void)
rubble.template("!VOID", void)
rubble.template("VOID", void)
rubble.template("#VOID", void)
rubble.template("V", void)

-- ABORT, cause Rubble to exit with an error, not used in the base.
rubble.template("!ABORT", [[rubble.abort(...)]])
rubble.template("ABORT", [[rubble.abort(...)]])
rubble.template("#ABORT", [[rubble.abort(...)]])

-- The next templates are for stripping leading/trailing whitespace from a string.
-- A formatting tool mostly, helps keep whitespace under control in generated files.
-- May also be used to help control variable expansion.
local echo = [[
	local args = rubble.targs{...}
	local out = ""
	for _, v in ipairs(args) do
		out = out..v
	end
	return rubble.parse(out, -1)
]]
rubble.template("@ECHO", echo)
rubble.template("!ECHO", echo)
rubble.template("ECHO", echo)
rubble.template("#ECHO", echo)
rubble.template("@", echo)
rubble.template("#", echo)
rubble.template("E", echo)
rubble.template("!", echo)

rubble.template("@GENERATE_COUNT", [[
	local count = tonumber(rubble.targs({...}, {""}))
	if count == nil or count < 2 then
		return ""
	end
	return " ("..count..")"
]])

rubble.template("@IF", [[
	local a, b, t, e = rubble.targs({...}, {"", "", "", ""})
	if a == b then
		return rubble.parse(t, -1)
	end
	return rubble.parse(e, -1)
]])

rubble.template("@IF_ACTIVE", [[
	local addon, t, e = rubble.targs({...}, {"", "", ""})
	
	if rubble.addonactive[addon] then
		return rubble.parse(t)
	end
	return rubble.parse(e)
]])

rubble.template("@IF_SKIP", [[
	local a, b, t, e = rubble.targs({...}, {"", ""})
	if a == b then
		rubble.filetag(rubble.currentfile(), "Skip", true)
	end
]])

rubble.template("@STORE_LIST", [[
	local masterkey, index, item, rtn = rubble.targs({...}, {"", "", "", "false"})
	local data = rubble.registry[masterkey].list
	
	index = tonumber(index)
	if index == nil then
		index = #data
	end
	
	data[index+1] = item
	
	if rtn == "true" then
		return index..""
	end
]])

rubble.template("@READ_LIST", [[
	local masterkey, index = rubble.targs({...}, {"", ""})
	return rubble.registry[masterkey].list[tonumber(index)+1]
]])

rubble.template("@FOREACH_LIST", [[
	local masterkey, raws = rubble.targs({...}, {"", ""}, {false, true})
	local data = rubble.registry[masterkey].list
	
	local out = ""
	for k, v in pairs(data) do
		-- This is the exact procedure followed by the rubble template parser.
		local chunk = rubble.expandvars(raws, '%', true, {key = k-1, val = v})
		chunk = rubble.expandvars(chunk)
		chunk = rubble.expandvars(chunk, '&', true)
		out = out..rubble.parse(chunk)
	end
	return out
]])

rubble.template("@STORE_TABLE", [[
	local masterkey, key, item = rubble.targs({...}, {"", "", ""})
	local data = rubble.registry[masterkey].table
	data[key] = item
]])

rubble.template("@READ_TABLE", [[
	local masterkey, key = rubble.targs({...}, {"", ""})
	return rubble.registry[masterkey].table[key]
]])

rubble.template("@FOREACH_TABLE", [[
	local masterkey, raws = rubble.targs({...}, {"", ""}, {false, true})
	local data = rubble.registry[masterkey].table
	
	local out = ""
	for k, v in pairs(data) do
		-- This is the exact procedure followed by the rubble template parser.
		local chunk = rubble.expandvars(raws, '%', true, {key = k, val = v})
		chunk = rubble.expandvars(chunk)
		chunk = rubble.expandvars(chunk, '&', true)
		out = out..rubble.parse(chunk)
	end
	return out
]])

rubble.template("@FOREACH", [[
	local items, raws, sepa, sepb = rubble.targs({...}, {"", "", "|", "="}, {false, true, false, false})
	
	local data = string.split(items, sepa)
	
	local out = ""
	for _, item in pairs(data) do
		local parts = string.split(item, sepb, 2)
		
		local k = string.unquote(string.trimspace(parts[1]))
		local v = string.unquote(string.trimspace(parts[2] or ""))
		
		-- This is the exact procedure followed by the rubble template parser.
		local chunk = rubble.expandvars(raws, '%', true, {key = k, val = v})
		chunk = rubble.expandvars(chunk)
		chunk = rubble.expandvars(chunk, '&', true)
		out = out..rubble.parse(chunk)
	end
	return out
]])

rubble.template("@SCRIPT", [[
	local code, tag = rubble.targs({...}, {"", ""}, true)
	local ok, result = rubble.execscript(code, tag)
	if not ok then
		print(ok, '"'..result..'"')
		rubble.abort(result)
	end
	return result
]])

rubble.template("@SET", [[
	local name, value, expand = rubble.targs({...}, {"", "", "false"}, true)
	if expand ~= "false" then
		value = rubble.expandvars(value, "$", true)
		chunk = rubble.expandvars(chunk, '&', true)
	end
	rubble.configvar(name, value)
]])

rubble.template("@GENERATE_ID", [[
	local prefix = rubble.targs({...}, {""})
	
	local data = rubble.registry["Libs/Base:@GENERATE_ID"]
	local idx = tonumber(data.table[prefix])
	if idx == nil then
		idx = -1
	end
	idx = idx + 1
	data.table[prefix] = idx
	
	return prefix.."_"..idx
]])

local prnt = [[
	local args = rubble.targs{...}
	for _, v in ipairs(args) do
		rubble.print("    ", v, "\n")
	end
]]
rubble.template("!PRINT", prnt)
rubble.template("PRINT", prnt)
rubble.template("#PRINT", prnt)

local warn = [[
	local args = rubble.targs{...}
	rubble.warning("    Warning: ", string.join(args, "\n      "), "\n")
]]
rubble.template("!WARN", warn)
rubble.template("WARN", warn)
rubble.template("#WARN", warn)

rubble.template("@PARSE_TO", [[
	local id, raws = rubble.targs({...}, {"", ""})
	local chunk = rubble.expandvars(raws)
	chunk = rubble.expandvars(chunk, '&', true)
	rubble.configvar(id, rubble.parse(chunk))
]])

rubble.template("@COPY_FILE_BANK", [[
	local id, path, bid = rubble.targs({...}, {"", "", ""})
	rubble.copyfilebank(id, path, bid)
]])

rubble.template("@WHITE_LIST_BANK_FILE", [[
	local bid, file = rubble.targs({...}, {"", ""})
	rubble.whitelistbankfile(bid, file)
]])

rubble.template("@BLACK_LIST_BANK_FILE", [[
	local bid, file = rubble.targs({...}, {"", ""})
	rubble.blavklistbankfile(bid, file)
]])
