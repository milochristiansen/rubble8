
local wshop = require("libs_powered").NewWShop("DFHACK_POWERED_WOOD_FURNACE", "Powered Wood Furnace")
wshop.ExtraItems = [[
	[BUILD_ITEM:2:TRAPCOMP:ITEM_TRAPCOMP_MECHANICAL_ARM:NONE:NONE]
		[CAN_USE_ARTIFACT]
]]
wshop:AddOutput("CHARCOAL", "charcoal")
wshop:AddOutput("ASH", "ash")
