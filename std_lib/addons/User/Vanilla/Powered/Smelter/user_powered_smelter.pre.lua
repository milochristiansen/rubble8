
local wshop = require("libs_powered").NewWShop("DFHACK_POWERED_SMELTER", "Powered Smelter")
wshop.ExtraItems = [[
	[BUILD_ITEM:2:TRAPCOMP:ITEM_TRAPCOMP_MECHANICAL_ARM:NONE:NONE]
		[CAN_USE_ARTIFACT]
]]
wshop:SetCenter("8", "0:4:1")
