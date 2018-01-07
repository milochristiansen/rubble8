
-- Buildings: Generic functions for working with buildings.
_ENV = rubble.mkmodule("libs_buildings")

local utils = require "utils"

local wshop_type_to_id = {
	[df.workshop_type.Carpenters] = "CARPENTERS",
	[df.workshop_type.Farmers] = "FARMERS",
	[df.workshop_type.Masons] = "MASONS",
	[df.workshop_type.Craftsdwarfs] = "CRAFTSDWARFS",
	[df.workshop_type.Jewelers] = "JEWELERS",
	[df.workshop_type.MetalsmithsForge] = "METALSMITHSFORGE",
	[df.workshop_type.MagmaForge] = "MAGMAFORGE",
	[df.workshop_type.Bowyers] = "BOWYERS",
	[df.workshop_type.Mechanics] = "MECHANICS",
	[df.workshop_type.Siege] = "SIEGE",
	[df.workshop_type.Butchers] = "BUTCHERS",
	[df.workshop_type.Leatherworks] = "LEATHERWORKS",
	[df.workshop_type.Tanners] = "TANNERS",
	[df.workshop_type.Clothiers] = "CLOTHIERS",
	[df.workshop_type.Fishery] = "FISHERY",
	[df.workshop_type.Still] = "STILL",
	[df.workshop_type.Loom] = "LOOM",
	[df.workshop_type.Quern] = "QUERN",
	[df.workshop_type.Kennels] = "KENNELS",
	[df.workshop_type.Ashery] = "ASHERY",
	[df.workshop_type.Kitchen] = "KITCHEN",
	[df.workshop_type.Dyers] = "DYERS",
	[df.workshop_type.Tool] = "TOOL",
	[df.workshop_type.Millstone] = "MILLSTONE",
}
local wshop_id_to_type = utils.invert(wshop_type_to_id)

local furnace_type_to_id = {
	[df.furnace_type.WoodFurnace] = "WOOD_FURNACE",
	[df.furnace_type.Smelter] = "SMELTER",
	[df.furnace_type.GlassFurnace] = "GLASS_FURNACE",
	[df.furnace_type.MagmaSmelter] = "MAGMA_SMELTER",
	[df.furnace_type.MagmaGlassFurnace] = "MAGMA_GLASS_FURNACE",
	[df.furnace_type.MagmaKiln] = "MAGMA_KILN",
	[df.furnace_type.Kiln] = "KILN",
}
local furnace_id_to_type = utils.invert(furnace_type_to_id)

-- GetWShopID returns a workshop or furnace's string ID based on it's numeric ID triplet.
-- This string ID *should* match what is expected by eventful for hardcoded buildings.
function GetWShopID(btype, bsubtype, bcustom)
	if btype == df.building_type.Workshop then
		if wshop_type_to_id[bsubtype] ~= nil then
			return wshop_type_to_id[bsubtype]
		else
			return df.building_def_workshopst.find(bcustom).code
		end
	elseif btype == df.building_type.Furnace then
		if furnace_type_to_id[bsubtype] ~= nil then
			return furnace_type_to_id[bsubtype]
		else
			return df.building_def_furnacest.find(bcustom).code
		end
	end
end

-- GetWShopIDs returns a workshop or furnace's ID numbers as a table.
-- The passed in ID should be the building's string identifier, it makes
-- no difference if it is a custom building or a hardcoded one.
-- The return table is structured like so: `{type, subtype, custom}`
function GetWShopType(id)
	if wshop_id_to_type[id] ~= nil then
		-- Hardcoded workshop
		return {
			type = df.building_type.Workshop,
			subtype = wshop_id_to_type[id],
			custom = -1,
		}
	elseif furnace_id_to_type[id] ~= nil then
		-- Hardcoded furnace
		return {
			type = df.building_type.Furnace,
			subtype = furnace_id_to_type[id],
			custom = -1,
		}
	else
		-- User defined workshop or furnace.
		for i, def in ipairs(df.global.world.raws.buildings.all) do
			if def.code == id then
				local typ = df.building_type.Furnace
				local styp = df.furnace_type.Custom
				if getmetatable(def) == "building_def_workshopst" then
					typ = df.building_type.Workshop
					styp = df.workshop_type.Custom
				end
				
				return {
					type = typ,
					subtype = styp,
					custom = i,
				}
			end
		end
	end
	return nil
end

return _ENV