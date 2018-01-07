
_ENV = rubble.mkmodule("libs_persist")

-- This is an easy to use wrapper for the DFHack persistence API.
-- Basically these functions take care of ensuring the existence of the desired key

-- Get the underlying structure from the persistence API.
function GetRaw(key)
	local raw = dfhack.persistent.get(key)
	if raw == nil then
		raw, _ = dfhack.persistent.save({key = key})
	end
	return raw
end

-- Save a value using the persistence API.
function Save(key, value)
	local raw = GetRaw(key)
	raw.value = value
	raw:save()
end

-- Get a value from the persistence API.
function Get(key)
	return GetRaw(key).value
end

-- Get a value from the persistence API and run it as code (returning any return value).
-- Returns nil if there is an error when loading the code.
-- If there is an error it is logged to the DFHack console.
function GetAsCode(key)
	local code = Get(key)
	
	local f, err = load(code)
	if f == nil then
		dfhack.printerr(err)
		return nil
	end
	return f()
end

return _ENV
