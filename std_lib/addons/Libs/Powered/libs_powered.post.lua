
-- Item mangling cannot be turned off by config var because it is an integral part of the way things
-- work. Disabling it will not cause things to stop working, but it is better to leave it on.

local file = rubble.files["disaster_libs_powered.dfmod.lua"]
if rubble.configvar("POWERED_WORKSHOPS_MANGLE_UNIT") == "YES" then
	file.Content = string.replace(file.Content, "--MANGLE_UNIT", "true", -1)
else
	file.Content = string.replace(file.Content, "--MANGLE_UNIT", "false", -1)
end

if rubble.configvar("POWERED_WORKSHOPS_MANGLE_SHOP") == "YES" then
	file.Content = string.replace(file.Content, "--MANGLE_SHOP", "true", -1)
else
	file.Content = string.replace(file.Content, "--MANGLE_SHOP", "false", -1)
end

file = rubble.files["workshops_libs_powered.dfmod.lua"]
if rubble.configvar("POWERED_WORKSHOPS_OUTPUT_STYLE") ~= "" then
	file.Content = string.replace(file.Content, "--OUTPUT_STYLE", rubble.configvar("POWERED_WORKSHOPS_OUTPUT_STYLE"), -1)
else
	file.Content = string.replace(file.Content, "--OUTPUT_STYLE", "Rubble", -1)
end
