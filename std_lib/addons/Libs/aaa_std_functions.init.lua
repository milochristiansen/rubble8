
-- Placeholder template generator.
function rubble.placeholder(name, silent)
	if silent then
		rubble.template(name, [[return ""]])
	else
		rubble.template(name, [[return  "The addon that contains \"]]..name..[[\" is disabled."]])
	end
end

-- Emulation of the way the old (Rubble 6) raw parser worked.
function rubble.rparse.walk(raws, action)
	local tags = rubble.rparse.parse(raws)
	for _, tag in ipairs(tags) do
		action(tag)
	end
	return rubble.rparse.format(tags)
end

function rubble.rparse.formattree(tree, depth, i)
	if depth == nil then
		depth = ""
	end
	
	local out = ""
	local ndepth = depth
	
	-- Ad a blank line before ever tag with children, but not if the previous tag on this level had children.
	-- Each table has non-integer keys, so length may not be reliable.
	if tree[1] ~= nil and (tree.parent == nil or i == nil or i <= 1 or tree.parent[i-1][1] == nil) then
		out = out..depth.."\n"
	end
	
	if tree.me ~= nil then
		-- Add one more tab before every group of tags, but not if they have no parent or their parent is a OBJECT tag.
		if tree.me.ID ~= "OBJECT" then
			ndepth = ndepth.."\t"
		end
		out = out..depth..tostring(tree.me).."\n"
	end
	
	for k, v in ipairs(tree) do
		out = out..rubble.rparse.formattree(v, ndepth, k)
		
		-- Add a blank line after the last child in every group.
		if tree[k+1] == nil then
			out = out..depth.."\n"
		end
	end
	
	return out
end

-- Default handling of template arguments.
function rubble.targs(args, defaults, noexpand)
	if type(noexpand) == "table" then
		for i = 1, #args, 1 do
			if not noexpand[i] then
				args[i] = rubble.expandvars(rubble.expandvars(args[i]), '&', true)
			end
		end
	else
		if not noexpand then
			for i = 1, #args, 1 do
				args[i] = rubble.expandvars(rubble.expandvars(args[i]), '&', true)
			end
		end
	end
	
	if defaults == nil then
		return args
	end
	
	if #args >= #defaults then
		return table.unpack(args)
	else
		for i = #args + 1, #defaults, 1 do
			table.insert(args, defaults[i])
		end
		return table.unpack(args)
	end
end

function rubble.expandargs(...)
	local args = {...}
	for i, v in ipairs(args) do
		if v == nil then v = "" end
		args[i] = rubble.expandvars(rubble.expandvars(v), '&', true)
	end
	return table.unpack(args)
end

function rubble.getarraypacked(array, fitem, len)
	local rtn = {}
	for i = fitem, fitem+len, 1 do
		table.insert(rtn, array[i])
	end
	return table.unpack(rtn)
end

function rubble.inverttable(tbl)
	rtn = {}
	for k, v in pairs(tbl) do
		rtn[v] = k
	end
	return rtn
end

local bool_map = {
	["yes"] = true,
	["y"] = true,
	["true"] = true,
	["t"] = true,
	["-1"] = true,
	["1"] = true,
}

-- Convert a string to a boolean value of some kind. Set t and f to specify what should be returned in true and false cases.
function rubble.tobool(opt, t, f)
	if t == nil then
		t = true
	end
	if f == nil then
		f = false
	end
	
	if bool_map[string.lower(opt)] then
		return t
	end
	return f
end
