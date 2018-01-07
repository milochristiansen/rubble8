
-- 
-- Rubble pseudo-module loader.
-- 
-- This code provides support for functionality sorta like `dfhack.script_environment`, but with a
-- syntax and usage much more like the Lua default "require" mechanism. In addition automatic
-- unloading is provided for modules that need it.
-- 
-- This loader also provides "live reloading", basically this makes the scripting system think the world
-- was unloaded, then reloaded, refreshing the scripts. This is invaluable when debugging a module.
-- Sadly this feature does not refresh the entire scripting state, as that would be basically impossible.
-- 
-- A pseudo-module is structured mostly like a module that you would use with the default require, but
-- with the following differences:
-- 
-- * Use `rubble.mkmodule` rather than `mkmodule`
-- * You can provide an optional onUnload function that will be called when the world is unloaded.
-- * You can provide an optional onStateChange function that will be called for all state change events
--   *except* `SC_WORLD_LOADED` and `SC_WORLD_UNLOADED` (don't look at me, it's a DFHack bug).
-- 
-- Using a pseudo-module is the same as using a default module, with the following difference:
-- 
-- * Use `rubble.require` instead of `require`.
-- 
-- `rubble.require` is fairly talented, if it can't find a module it will try `dfhack.script_environment`
-- and finally the default `require`, so you can just use it in all cases and it will load the module no
-- matter what underlying module mechanism was used.
-- 

-- Important Globals and Loader Functions

print("Initializing Rubble Module System...")

-- This little song-and-dance creates a new global table named "rubble".
dfhack.BASE_G.rubble = {}

-- Don't touch, internal.
rubble.__modules = {}

-- Don't touch, internal.
function rubble.__load_module(name)
	local modfile = SAVE_PATH.."/raw/modules/"..name..".lua"
	
	-- If the given pseudo module does not exist first try "dfhack.script_environment" and then "require".
	if not dfhack.filesystem.exists(modfile) then
		if not dfhack.findScript(name) then
			return require(name), nil
		end
		return dfhack.script_environment(name), nil
	end
	
	env = {}
	setmetatable(env, { __index = dfhack.BASE_G })
	
	local f, perr = loadfile(modfile, 't', env)
	if f then
		local ok, module = pcall(f)
		if not ok or not module then
			return nil, module
		end
		rubble.__modules[name] = module
		return module, nil
	end
	return nil, perr
end

-- Registers a single value as a module, useful for making small modules for special purposes.
-- Unlike the other module functions you can overwrite existing modules with this.
function rubble.forcemodule(name, module)
	rubble.__modules[name] = module
end

-- Use exactly like "mkmodule"
-- If called with the name of an existing module it will return a reference to the existing module.
function rubble.mkmodule(name)
	if rubble.__modules[name] ~= nil then
		return rubble.__modules[name]
	end
	
	env = {}
	setmetatable(env, { __index = dfhack.BASE_G })
	return env
end

-- "Extend" an existing module.
-- Makes a new module that has the API of the old module, plus whatever you add to it,
-- the old module is not modified.
-- This should work even if the parent uses "dfhack.script_environment" or the default
-- "require" mechanism.
function rubble.extendmodule(parent, name)
	if rubble.__modules[name] ~= nil then
		return rubble.__modules[name]
	end
	
	local parentmod = rubble.__modules[parent]
	if parentmod == nil then
		-- rubble.require errors out if the module does not exist in any form.
		parentmod = rubble.require(parent)
	end
	
	env = {}
	setmetatable(env, { __index = parentmod })
	return env
end

-- Use like "require", but for modules made with "rubble.mkmodule".
-- If the module does not exist this fails over to trying to load the module with
-- "dfhack.script_environment", then the default "require". If both of those fail
-- loading aborts with an error.
function rubble.require(name)
	if rubble.__modules[name] == nil then
		local mod, err = rubble.__load_module(name)
		if err ~= nil then
			qerror(err)
		end
		return mod
	end
	return rubble.__modules[name]
end

-- Refresh any DFHack startup scripts and Rubble pseudo-modules.
-- Some scripts may not like this! In general the only problems will be scripts
-- that start global actions and do not handle being called multiple times gracefully.
-- If your script can be called twice in a row with no ill effect then it should be
-- fine.
-- I don't/can't fully refresh the scripting system, as there is far too much room for
-- error, so in general the only things that get refreshed are pseudo modules and save
-- init scripts, which is generally sufficient, particularly since this is for use with
-- Rubble, which makes heavy use of both.
-- 
-- Oddly DFHack does not appear to call `onStateChange` for the `SC_WORLD_LOADED` *or*
-- `SC_WORLD_UNLOADED` events. Upon further consideration there is really no reason to,
-- as scripts are run on load, and `onUnload` is called when the world is unloaded, but
-- this behavior seems strange and may be a bug.
function rubble.refresh()
	-- Amazingly this is all that is needed.
	-- For some odd reason unloading is carried out for both events, I guess as insurance
	-- for missed unload events.
	dfhack.onStateChange.DFHACK_PER_SAVE(SC_WORLD_LOADED)
end

function onUnload()
	print("Unloading Rubble Module System...")
	
	for _, module in pairs(rubble.__modules) do
		if module.onUnload ~= nil then
			module.onUnload()
		end
	end
	
	rubble.__modules = {}
end

function onStateChange(state)
	for _, module in pairs(rubble.__modules) do
		if module.onStateChange ~= nil then
			module.onStateChange(state)
		end
	end
end
