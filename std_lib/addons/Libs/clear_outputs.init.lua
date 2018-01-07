
-- This script clears the "out:" directory.

-- EXPERTS ONLY!
if rubble.configvar("_RUBBLE_NO_CLEAR_") == "true" then
	print "    _RUBBLE_NO_CLEAR_ is set, skipping."
	return
end

-- Recursively clears a directory.
local function cleardir(path)
	for _, dir in ipairs(axis.listdirs(path)) do
		cleardir(path.."/"..dir)
		local ok, err = axis.del(path.."/"..dir)
		if not ok then
			print("  Error deleting: \""..path.."/"..dir.."\": "..err)
		end
	end
	for _, file in ipairs(axis.listfiles(path)) do
		local ok, err = axis.del(path.."/"..file)
		if not ok then
			print("  Error deleting: \""..path.."/"..file.."\": "..err)
		end
	end
end

-- These are (or at least should be) safe to nuke.
cleardir("out/objects")
cleardir("out/scripts")
cleardir("out/init.d")
cleardir("out/modules")

-- Creature graphics are separately conditional (as it is a pain to make a graphics addon for personal use).
if rubble.configvar("_RUBBLE_NO_CLEAR_GRAPHICS_") == "true" then
	print "    _RUBBLE_NO_CLEAR_GRAPHICS_ is set, skipping graphics directory."
else
	cleardir("out/graphics")
end

-- Now clear out the various junk that has accumulated in the raw directory itself.
for _, file in ipairs(axis.listfiles("out")) do
	local ok, err = axis.del("out/"..file)
	if not ok then
		print("  Error deleting: \"out/"..file.."\": "..err)
	end
end
