
-- This is a Rubble module **not** a DFHack module!
_ENV = mkmodule("libs_powered")

workshops = workshops or {}

function NewWShop(id, name)
	workshops[id] = {
		name = name,
		
		outputs = {},
		AddOutput = function(self, id, name)
			table.insert(self.outputs, {id = id, name = name})
		end,
		
		-- The addon hook to use for reactions and workshops.
		Hook = "ADDON_HOOK_PLAYABLE",
		
		-- Tiles and colors for workshops.
		-- For normal size workshops only `Tiles[2][2]` and `Colors[2][2]` are used.
		Tiles = {
			{"7", "228", "254"}, -- •Σ■
			{"7", "42", "254"},  -- •*■
			{"7", "228", "254"}, -- •Σ■
		},
		Colors = {
			{"7:0:0", "0:0:1", "7:0:0"},
			{"7:0:0", "7:0:0", "7:0:0"},
			{"7:0:0", "0:0:1", "7:0:0"},
		},
		SetCenter = function(self, tile, color)
			self.Tiles[2][2] = tile
			self.Colors[2][2] = color
		end,
		
		-- Any build items you may want to add beyond the standard.
		ExtraItems = "",
		
		-- If true makes a 1x1 workshop rather than a 3x3.
		-- This setting ignores all tile and color settings, you will need to set that stuff from the DFHack side of things.
		Small = false,
		
		-- If true makes the workshop 5x5 rather than 3x3.
		Large = false,
	}
	return workshops[id]
end

function GenReactions(id)
	local out = ""
	
	local wshop = workshops[id]
	if wshop == nil then
		rubble.abort("Attempt to generate reactions for non-existent powered workshop: "..id)
	end
	
	if #wshop.outputs > 0 then
		for _, output in ipairs(wshop.outputs) do
			local me = id.."_"..output.id
			
			out = out.."\n{!SHARED_REACTION;"..me.."_OUTPUT;"..wshop.Hook..";\n\t[BUILDING:"..me..":NONE]\n\t[NAME:producing "..output.name.."]\n\t[SKILL:MECHANICS]\n}\n{!SHARED_REACTION;"..me.."_SEPERATOR;"..wshop.Hook..";\n\t[BUILDING:"..me..":NONE]\n\t[NAME:-----------------]\n\t[SKILL:MECHANICS]\n}\n"
			
			for _, noutput in ipairs(wshop.outputs) do
				if noutput.id ~= output.id then
					local it = id.."_"..noutput.id
					
					out = out.."\n{DFHACK_REACTION_UPGRADE_BUILDING;"..me..";"..it..";output "..noutput.name..";"..wshop.Hook.."}\n\t[SKILL:MECHANICS]\n"
				end
			end
		end
	else
		rubble.abort("Attempt to generate reactions for workshop without changeable outputs: "..id)
	end
	
	return string.trimspace(rubble.parse(out))
end

function GenBuildings(id)
	local out = ""
	
	local wshop = workshops[id]
	if wshop == nil then
		rubble.abort("Attempt to generate buildings for non-existent powered workshop: "..id)
	end
	
	function gen_shop(output)
		local hook
		if output == nil then
			hook = wshop.Hook
		else
			if output.id == wshop.outputs[1].id then
				hook = wshop.Hook
			else
				hook = "NULL"
			end
		end
		
		local outputid = ""
		if output ~= nil then
			outputid = "_"..output.id
		end
		
		if wshop.Small then
			out = out.."\n{!SHARED_BUILDING_WORKSHOP;"..id..outputid..";"..hook..[[;
	[NAME:]]..wshop.name..[[]
	[NAME_COLOR:7:0:1]
	[BUILD_LABOR:MECHANIC]
	[DIM:1:1]
	[WORK_LOCATION:1:1]
	[BLOCK:1:0]
	[TILE:0:1:42]
	[COLOR:0:1:0:7:0]
	[TILE:1:1:128]
	[COLOR:1:1:0:7:0]
	[TILE:2:1:15]
	[COLOR:2:1:0:7:0]
	[TILE:3:1:42]
	[COLOR:3:1:0:7:0]
	[BUILD_ITEM:1:BLOCKS:NONE:NONE:NONE]
		[BUILDMAT]
	[BUILD_ITEM:1:TRAPPARTS:NONE:NONE:NONE]
		[CAN_USE_ARTIFACT]
}
]]..wshop.ExtraItems
		elseif wshop.Large then
			out = out.."\n{!SHARED_BUILDING_WORKSHOP;"..id..outputid..";"..hook..[[;
	[NAME:]]..wshop.name..[[]
	[NAME_COLOR:7:0:1]
	[BUILD_LABOR:MECHANIC]
	[DIM:5:5]
	[WORK_LOCATION:3:3]
	[BLOCK:1:0:0:0:0:0]
	[BLOCK:2:0:0:0:0:0]
	[BLOCK:3:0:0:0:0:0]
	[BLOCK:4:0:0:0:0:0]
	[BLOCK:5:0:0:0:0:0]
	[TILE:0:1:128:32:32:128:32]
	[TILE:0:2:32:228:32:254:32]
	[TILE:0:3:32:32:32:32:32]
	[TILE:0:4:254:32:254:32:32]
	[TILE:0:5:32:32:32:128:32]
	[COLOR:0:1:7:0:0:0:0:0:0:0:0:7:0:0:0:0:0]
	[COLOR:0:2:0:0:0:0:0:1:0:0:0:7:0:0:0:0:0]
	[COLOR:0:3:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0]
	[COLOR:0:4:7:0:0:0:0:0:7:0:0:0:0:0:0:0:0]
	[COLOR:0:5:0:0:0:0:0:0:0:0:0:7:0:0:0:0:0]
	[TILE:1:1:42:32:31:32:42]
	[TILE:1:2:32:32:228:32:32]
	[TILE:1:3:16:32:228:32:254]
	[TILE:1:4:32:32:228:32:32]
	[TILE:1:5:42:32:254:32:128]
	[COLOR:1:1:7:0:0:0:0:0:7:0:0:0:0:0:7:0:0]
	[COLOR:1:2:0:0:0:0:0:0:0:0:1:0:0:0:0:0:0]
	[COLOR:1:3:7:0:0:0:0:0:0:0:1:0:0:0:7:0:0]
	[COLOR:1:4:0:0:0:0:0:0:0:0:1:0:0:0:0:0:0]
	[COLOR:1:5:7:0:0:0:0:0:7:0:0:0:0:0:7:0:0]
	[TILE:2:1:42:32:31:32:42]
	[TILE:2:2:32:61:228:61:32]
	[TILE:2:3:16:61:228:61:17]
	[TILE:2:4:32:61:228:61:32]
	[TILE:2:5:42:32:30:32:42]
	[COLOR:2:1:7:0:0:0:0:0:7:0:0:0:0:0:7:0:0]
	[COLOR:2:2:0:0:0:0:0:1:0:0:1:0:0:1:0:0:0]
	[COLOR:2:3:7:0:0:0:0:1:0:0:1:0:0:1:7:0:0]
	[COLOR:2:4:0:0:0:0:0:1:0:0:1:0:0:1:0:0:0]
	[COLOR:2:5:7:0:0:0:0:0:7:0:0:0:0:0:7:0:0]
	[TILE:3:1:42:32:31:32:42]
	[TILE:3:2:32:]]..wshop.Tiles[1][1]..":"..wshop.Tiles[2][1]..":"..wshop.Tiles[3][1]..[[:32]
	[TILE:3:3:16:]]..wshop.Tiles[1][2]..":"..wshop.Tiles[2][2]..":"..wshop.Tiles[3][2]..[[:17]
	[TILE:3:4:32:]]..wshop.Tiles[1][3]..":"..wshop.Tiles[2][3]..":"..wshop.Tiles[3][3]..[[:32]
	[TILE:3:5:42:32:30:32:42]
	[COLOR:3:1:7:0:0:0:0:0:7:0:0:0:0:0:7:0:0]
	[COLOR:3:2:0:0:0:]]..wshop.Colors[1][1]..":"..wshop.Colors[2][1]..":"..wshop.Colors[3][1]..[[:0:0:0]
	[COLOR:3:3:7:0:0:]]..wshop.Colors[1][2]..":"..wshop.Colors[2][2]..":"..wshop.Colors[3][2]..[[:7:0:0]
	[COLOR:3:4:0:0:0:]]..wshop.Colors[1][3]..":"..wshop.Colors[2][3]..":"..wshop.Colors[3][3]..[[:0:0:0]
	[COLOR:3:5:7:0:0:0:0:0:7:0:0:0:0:0:7:0:0]
	
	[BUILD_ITEM:4:BLOCKS:NONE:NONE:NONE]
		[BUILDMAT]
	[BUILD_ITEM:2:TRAPPARTS:NONE:NONE:NONE]
		[CAN_USE_ARTIFACT]
}
]]..wshop.ExtraItems
		else
			out = out.."\n{BUILDING_WORKSHOP;"..id..outputid..";"..hook..[[}
	[NAME:]]..wshop.name..[[]
	[NAME_COLOR:7:0:1]
	[BUILD_LABOR:MECHANIC]
	[DIM:3:3]
	[WORK_LOCATION:2:2]
	[BLOCK:1:0:0:0]
	[BLOCK:2:0:0:0]
	[BLOCK:3:0:0:0]
	[TILE:0:1:32:254:32]
	[TILE:0:2:128:32:128]
	[TILE:0:3:42:32:128]
	[COLOR:0:1:0:0:0:0:0:1:0:0:0]
	[COLOR:0:2:0:0:1:0:0:0:0:0:1]
	[COLOR:0:3:7:0:0:0:0:0:0:0:1]
	[TILE:1:1:32:32:32]
	[TILE:1:2:32:32:32]
	[TILE:1:3:32:32:32]
	[COLOR:1:1:0:0:0:0:0:0:0:0:0]
	[COLOR:1:2:0:0:0:0:0:0:0:0:0]
	[COLOR:1:3:0:0:0:0:0:0:0:0:0]
	[TILE:2:1:254:32:42]
	[TILE:2:2:32:42:17]
	[TILE:2:3:128:32:42]
	[COLOR:2:1:0:0:1:0:0:0:0:0:1]
	[COLOR:2:2:0:0:0:7:0:0:0:0:1]
	[COLOR:2:3:0:0:1:0:0:0:0:0:1]
	[TILE:3:1:42:31:42]
	[TILE:3:2:16:]]..wshop.Tiles[2][2]..[[:17]
	[TILE:3:3:42:30:42]
	[COLOR:3:1:0:0:1:0:0:1:0:0:1]
	[COLOR:3:2:0:0:1:]]..wshop.Colors[2][2]..[[:0:0:1]
	[COLOR:3:3:0:0:1:0:0:1:0:0:1]
	
	[BUILD_ITEM:4:BLOCKS:NONE:NONE:NONE]
		[BUILDMAT]
	[BUILD_ITEM:2:TRAPPARTS:NONE:NONE:NONE]
		[CAN_USE_ARTIFACT]
]]..wshop.ExtraItems
		end
	end
	
	if #wshop.outputs > 0 then
		for _, output in ipairs(wshop.outputs) do
			gen_shop(output)
		end
	else
		gen_shop(nil)
	end
	
	return string.trimspace(rubble.parse(out))
end

return _ENV
