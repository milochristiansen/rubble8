
-- Math templates

rubble.template("@MUL", function(x, y)
	x, y = rubble.expandargs(x, y)
	x, y = tonumber(x), tonumber(y)
	if x == nil or y == nil then
		rubble.abort("Non-numeric argument.")
	end
	
	return x * y
end)

rubble.template("@DIV", function(x, y)
	x, y = rubble.expandargs(x, y)
	x, y = tonumber(x), tonumber(y)
	if x == nil or y == nil then
		rubble.abort("Non-numeric argument.")
	end
	
	return x / y
end)

rubble.template("@IDIV", function(x, y)
	x, y = rubble.expandargs(x, y)
	x, y = tonumber(x), tonumber(y)
	if x == nil or y == nil then
		rubble.abort("Non-numeric argument.")
	end
	
	return x // y
end)

rubble.template("@MOD", function(x, y)
	x, y = rubble.expandargs(x, y)
	x, y = tonumber(x), tonumber(y)
	if x == nil or y == nil then
		rubble.abort("Non-numeric argument.")
	end
	
	return x % y
end)

rubble.template("@ADD", function(x, y)
	x, y = rubble.expandargs(x, y)
	x, y = tonumber(x), tonumber(y)
	if x == nil or y == nil then
		rubble.abort("Non-numeric argument.")
	end
	
	return x + y
end)

rubble.template("@SUB", function(x, y)
	x, y = rubble.expandargs(x, y)
	x, y = tonumber(x), tonumber(y)
	if x == nil or y == nil then
		rubble.abort("Non-numeric argument.")
	end
	
	return x - y
end)
