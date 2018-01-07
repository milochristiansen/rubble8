
local wshop = require("libs_powered").NewWShop("DFHACK_POWERED_LOGIC_GATES", "Powered Logic Gate")
wshop.Small = true
wshop:AddOutput("AND", "AND")
wshop:AddOutput("OR", "OR")
wshop:AddOutput("NOT", "NOT")
wshop:AddOutput("XOR", "XOR")
