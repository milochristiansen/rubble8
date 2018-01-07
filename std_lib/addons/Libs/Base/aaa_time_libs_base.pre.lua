
-- units -> seconds
-- Fort time is value/72 and a growdur is value/7200.
local timemap = {
	["SECOND"] = 1,
	["SECONDS"] = 1,
	["MINUTE"] = 60,
	["MINUTES"] = 60,
	["HOUR"] = 3600,
	["HOURS"] = 3600,
	["DAY"] = 86400,
	["DAYS"] = 86400,
	["WEEK"] = 604800,
	["WEEKS"] = 604800,
	["MONTH"] = 2419200,
	["MONTHS"] = 2419200,
	["SEASON"] = 7257600,
	["SEASONS"] = 7257600,
	["YEAR"] = 29030400,
	["YEARS"] = 29030400,
}

function rubble.libs_base.time(count, unit, divisor)
	if timemap[unit] == nil then
		rubble.abort("Attempt to use invalid time unit: "..unit..".")
	end
	
	local out = math.floor((timemap[unit] * count) / divisor)
	if out < 1 then
		out = 1
	end
	return out
end

rubble.template("@ADV_TIME", [[
	local count, unit = rubble.targs({...}, {"", ""})
	return rubble.libs_base.time(count, unit, 1)..""
]])

rubble.template("@FORT_TIME", [[
	local count, unit = rubble.targs({...}, {"", ""})
	return rubble.libs_base.time(count, unit, 72)..""
]])

rubble.template("@GROWDUR", [[
	local count, unit = rubble.targs({...}, {"", ""})
	return "[GROWDUR:"..rubble.libs_base.time(count, unit, 7200).."]"
]])
