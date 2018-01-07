
local powered = require("libs_powered")

local wshop = powered.NewWShop("DFHACK_POWERED_BELTS", "Belt")
wshop.Small = true

wshop:AddOutput("NORTH", "N")
wshop:AddOutput("SOUTH", "S")
wshop:AddOutput("EAST", "E")
wshop:AddOutput("WEST", "W")

wshop = powered.NewWShop("DFHACK_POWERED_CART_LAUNCHER", "Powered Minecart Launcher")
wshop.Small = true
wshop.Hook = "NULL"

wshop = powered.NewWShop("DFHACK_POWERED_CART_LOADER", "Powered Minecart Loader")
wshop.Small = true
wshop.ExtraItems = "\t[BUILD_ITEM:1:TRAPCOMP:ITEM_TRAPCOMP_MECHANICAL_ARM:NONE:NONE]\n\t\t[CAN_USE_ARTIFACT]\n"

wshop:AddOutput("ITEMS", "items")
wshop:AddOutput("WATER", "water")
wshop:AddOutput("MAGMA", "magma")
