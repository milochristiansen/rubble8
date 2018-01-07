
-- Setting the Skip tag should make this check impossible, but just in case...
if rubble ~= nil then
	return
end

-- Load the native modules into global variables for convenience.
rubble = require "rubble"
axis = require "axis"
rubble.rparse = require "rubble.rparse"

function printall(val)
	for k, v in pairs(val) do
		rubble.print(k, " = ", v, "\n")
	end
end

function mkmodule(name)
	local pkg = package.loaded[name]
	if pkg ~= nil then
		return pkg
	end
	return setmetatable({}, {__index = _G})
end

local loaderchecks = {
	function(name)
		return rubble.files[name..".mod.lua"]
	end,
	function(name)
		return rubble.files[name]
	end,
}

local function loadmodule(name, file)
	local fn, err = load(file.Content, file.Source.."/"..file.Name, "t", _G)
	if fn == nil then
		error(err)
	end
	return fn()
end

-- The default module searcher.
table.insert(package.searchers, function(name)
	local file, found = nil, false
	for _, check in ipairs(loaderchecks) do
		file = check(name)
		if file ~= nil and file.Tags["ModuleScript"] and file.Tags["LangLua"] and not file.Tags["DFHack"] and not file.Tags["Skip"] then
			found = true
			break
		end
	end
	if not found then
		return name..": Module does not exist in any active addon."
	end
	
	return loadmodule, file
end)

function rubble.checkversion(addon, major, minor, patch)
	local state = 0
	if rubble.vmajor == major then
		if rubble.vminor == minor then
			if rubble.vpatch == patch then
				state = 1
			elseif rubble.vpatch > patch then
				state = 2
			end
		elseif rubble.vminor > minor then
			state = 2
		end
	elseif rubble.vmajor > major then
		state = 2
	end
	
	if state == 1 then -- Equal
		if major.."."..minor.."."..patch ~= rubble.version then
			rubble.warning( 
				"      "..addon.." requires Rubble version "..major.."."..minor.."."..patch.." (or a compatible newer version)\n"..
				"      The current Rubble version is: "..rubble.version.."\n"..
				"      The version numbers match, but the version string does not. This may indicate that\n"..
				"      your version of Rubble is a beta version or other special distribution.\n"..
				"      If you encounter issues changing to the requested Rubble version may help.\n"
			)
		end
	elseif state == 2 then -- Newer
		rubble.warning( 
			"      "..addon.." requires Rubble version "..major.."."..minor.."."..patch.." (or a compatible newer version)\n"..
			"      The current Rubble version is: "..rubble.version.." Which is newer than requested.\n"..
			"      If you encounter issues changing to the requested Rubble version may help.\n"
		)
	else -- Older
		rubble.abort( 
			addon.." requires Rubble version "..major.."."..minor.."."..patch.." (or a compatible newer version)\n"..
			"The current Rubble version is: "..rubble.version.." Which is older than requested.\n"..
			"Please update to a newer Rubble version and try again.\n"
		)
	end
end

rubble.gfiles["aaa_init_scripting.load.lua"].Tags["Skip"] = true
