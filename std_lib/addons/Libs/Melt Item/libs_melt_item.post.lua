
local melt = require "libs_melt_item"

local file = rubble.files["libs_melt_item.dfmod.lua"]
file.Content = string.replace(file.Content, "--RESULT_TABLE_HERE", melt.generate_result(), -1)
file.Content = string.replace(file.Content, "--REACTION_TABLE_HERE", melt.generate_react(), -1)
