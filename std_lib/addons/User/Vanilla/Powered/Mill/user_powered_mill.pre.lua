
local wshop = require("libs_powered").NewWShop("DFHACK_POWERED_MILL", "Powered Mill")
wshop.ExtraItems = [[
	[BUILD_ITEM:1:MILLSTONE:NONE:NONE:NONE]
		[CAN_USE_ARTIFACT]
	[BUILD_ITEM:2:TRAPCOMP:ITEM_TRAPCOMP_MECHANICAL_ARM:NONE:NONE]
		[CAN_USE_ARTIFACT]
]]
wshop:SetCenter("9", "6:0:0")
