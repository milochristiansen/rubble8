
local wshop = require("libs_powered").NewWShop("DFHACK_POWERED_GLASS_FURNACE", "Powered Glass Furnace")
wshop.ExtraItems = [[
	[BUILD_ITEM:2:TRAPCOMP:ITEM_TRAPCOMP_MECHANICAL_ARM:NONE:NONE]
		[CAN_USE_ARTIFACT]
]]
wshop:SetCenter("8", "0:4:1")
