
-- String handling

rubble.template("@STR_LOWER", [[
	return string.lower(rubble.targs({...}, {""}))
]])

rubble.template("@STR_UPPER", [[
	return string.upper(rubble.targs({...}, {""}))
]])

rubble.template("@STR_TITLE", [[
	return string.title(rubble.targs({...}, {""}))
]])

rubble.template("@STR_REPLACE", [[
	local str, old, new, n = rubble.targs({...}, {"", "", "", -1})
	return string.replace(str, old, new, n)
]])

rubble.template("@STR_TO_ID", [[
	return string.upper(string.replace(string.replace(rubble.targs({...}, {""}), ":", "_", -1), " ", "_", -1))
]])

rubble.template("@STR_SPLIT", function(str, delim, max)
	str, delim, max = rubble.expandargs(str, delim, max)
	max = tonumber(max)
	if max == nil then
		max = -1
	end
	
	local parts = string.split(str, delim, max)
	for i, v in ipairs(parts) do
		rubble.configvar(i-1, v) -- Remember RTL is 0 based!
	end
end)
