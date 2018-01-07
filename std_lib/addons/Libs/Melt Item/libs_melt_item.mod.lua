
_ENV = mkmodule("libs_melt_item")

-- This is an array of reaction names to register with the melt item hook.
-- Any reagents that have an ID that ends with "_melt" will be flagged to only accept melt designated items.
reactions = {}

-- This array of item types to melt results is translated into a Lua table and provided
-- to DFHack scripts.
-- For items with subtypes it is possible to have a subtypes table attached to the item
-- type entry, this table matches subtype IDs to bar and wafer melt results.
-- 
-- By default melt results are the same as production requirements, with the minimum
-- return being 1/1000 of a bar (so coins melt without gain or loss).
-- 
-- The melt script this table is to be used with treats bar part counts of .999 as equaling 1
-- this allows three items with counts of .333 to make one bar.
-- 
-- Items that have bar and wafer counts of 0 cannot be made from metal in vanilla.
-- If you add a way to make these items (or add new subtypes for existing items)
-- you will need to "require" this table and edit it.
-- Do not edit this table here!
-- 
-- This table MUST be in the same order as the item types are defined in DF!
data = {
	{
		id = "BAR",
		bars = 1,
		wafers = 1,
	},
	{
		id = "SMALLGEM",
		bars = 0,
		wafers = 0,
	},
	{
		id = "BLOCKS",
		bars = 1,
		wafers = 1,
	},
	{
		id = "ROUGH",
		bars = 0,
		wafers = 0,
	},
	{
		id = "BOULDER",
		bars = 0,
		wafers = 0,
	},
	{
		id = "WOOD",
		bars = 0,
		wafers = 0,
	},
	{
		id = "DOOR",
		bars = 3,
		wafers = 9,
	},
	{
		id = "FLOODGATE",
		bars = 3,
		wafers = 9,
	},
	{
		id = "BED",
		bars = 0,
		wafers = 0,
	},
	{
		id = "CHAIR",
		bars = 3,
		wafers = 9,
	},
	{
		id = "CHAIN",
		bars = 1,
		wafers = 4,
	},
	{
		id = "FLASK",
		bars = 0.333,
		wafers = 0.333,
	},
	{
		id = "GOBLET",
		bars = 0.333,
		wafers = 0.333,
	},
	{
		id = "INSTRUMENT",
		bars = 1,
		wafers = 1,
	},
	{
		id = "TOY",
		bars = 1,
		wafers = 1,
	},
	{
		id = "WINDOW",
		bars = 0,
		wafers = 0,
	},
	{
		id = "CAGE",
		bars = 3,
		wafers = 6,
	},
	{
		id = "BARREL",
		bars = 3,
		wafers = 9,
	},
	{
		id = "BUCKET",
		bars = 1,
		wafers = 3,
	},
	{
		id = "ANIMALTRAP",
		bars = 1,
		wafers = 3,
	},
	{
		id = "TABLE",
		bars = 3,
		wafers = 9,
	},
	{
		id = "COFFIN",
		bars = 3,
		wafers = 9,
	},
	{
		id = "STATUE",
		bars = 3,
		wafers = 9,
	},
	{
		id = "CORPSE",
		bars = 0,
		wafers = 0,
	},
	{
		id = "WEAPON",
		bars = 1,
		wafers = 3,
		subtypes = {
			ITEM_WEAPON_AXE_BATTLE = {bars = 1, wafers = 4},
			ITEM_WEAPON_PICK = {bars = 1, wafers = 4},
		},
	},
	{
		id = "ARMOR",
		bars = 1,
		wafers = 1,
		subtypes = {
			ITEM_ARMOR_BREASTPLATE = {bars = 3, wafers = 9},
			ITEM_ARMOR_MAIL_SHIRT = {bars = 2, wafers = 6},
		},
	},
	{
		id = "SHOES",
		bars = 1,
		wafers = 1,
		subtypes = {
			ITEM_SHOES_BOOTS = {bars = 0.5, wafers = 2},
			ITEM_SHOES_BOOTS_LOW = {bars = 0.5, wafers = 1},
		},
	},
	{
		id = "SHIELD",
		bars = 1,
		wafers = 1,
		subtypes = {
			ITEM_SHIELD_SHIELD = {bars = 1, wafers = 4},
			ITEM_SHIELD_BUCKLER = {bars = 1, wafers = 2},
		},
	},
	{
		id = "HELM",
		bars = 1,
		wafers = 1,
		subtypes = {
			ITEM_HELM_HELM = {bars = 1, wafers = 2},
			ITEM_HELM_CAP = {bars = 1, wafers = 1},
		},
	},
	{
		id = "GLOVES",
		bars = 0.5,
		wafers = 2,
	},
	{
		id = "BOX",
		bars = 3,
		wafers = 9,
	},
	{
		id = "BIN",
		bars = 3,
		wafers = 9,
	},
	{
		id = "ARMORSTAND",
		bars = 3,
		wafers = 9,
	},
	{
		id = "WEAPONRACK",
		bars = 3,
		wafers = 9,
	},
	{
		id = "CABINET",
		bars = 3,
		wafers = 9,
	},
	{
		id = "FIGURINE",
		bars = 0.333,
		wafers = 0.333,
	},
	{
		id = "AMULET",
		bars = 0.333,
		wafers = 0.333,
	},
	{
		id = "SCEPTER",
		bars = 0.333,
		wafers = 0.333,
	},
	{
		id = "AMMO",
		bars = 0.04,
		wafers = 0.04,
	},
	{
		id = "CROWN",
		bars = 0.333,
		wafers = 0.333,
	},
	{
		id = "RING",
		bars = 0.333,
		wafers = 0.333,
	},
	{
		id = "EARRING",
		bars = 0.333,
		wafers = 0.333,
	},
	{
		id = "BRACELET",
		bars = 0.333,
		wafers = 0.333,
	},
	{
		id = "GEM",
		bars = 0,
		wafers = 0,
	},
	{
		id = "ANVIL",
		bars = 3,
		wafers = 9,
	},
	{
		id = "CORPSEPIECE",
		bars = 0,
		wafers = 0,
	},
	{
		id = "REMAINS",
		bars = 0,
		wafers = 0,
	},
	{
		id = "MEAT",
		bars = 0,
		wafers = 0,
	},
	{
		id = "FISH",
		bars = 0,
		wafers = 0,
	},
	{
		id = "FISH_RAW",
		bars = 0,
		wafers = 0,
	},
	{
		id = "VERMIN",
		bars = 0,
		wafers = 0,
	},
	{
		id = "PET",
		bars = 0,
		wafers = 0,
	},
	{
		id = "SEEDS",
		bars = 0,
		wafers = 0,
	},
	{
		id = "PLANT",
		bars = 0,
		wafers = 0,
	},
	{
		id = "SKIN_TANNED",
		bars = 0,
		wafers = 0,
	},
	{
		id = "PLANT_GROWTH",
		bars = 0,
		wafers = 0,
	},
	{
		id = "THREAD",
		bars = 0,
		wafers = 0,
	},
	{
		id = "CLOTH",
		bars = 0,
		wafers = 0,
	},
	{
		id = "TOTEM",
		bars = 0,
		wafers = 0,
	},
	{
		id = "PANTS",
		bars = 1,
		wafers = 1,
		subtypes = {
			ITEM_PANTS_GREAVES = {bars = 2, wafers = 6},
			ITEM_PANTS_LEGGINGS = {bars = 1, wafers = 5},
		},
	},
	{
		id = "BACKPACK",
		bars = 0,
		wafers = 0,
	},
	{
		id = "QUIVER",
		bars = 0,
		wafers = 0,
	},
	{
		id = "CATAPULTPARTS",
		bars = 0,
		wafers = 0,
	},
	{
		id = "BALLISTAPARTS",
		bars = 0,
		wafers = 0,
	},
	{
		id = "SIEGEAMMO",
		bars = 3,
		wafers = 4,
	},
	{
		id = "BALLISTAARROWHEAD",
		bars = 3,
		wafers = 4,
	},
	{
		id = "TRAPPARTS",
		bars = 1,
		wafers = 3,
	},
	{
		id = "TRAPCOMP",
		bars = 1,
		wafers = 1,
		subtypes = {
			ITEM_TRAPCOMP_GIANTAXEBLADE = {bars = 1, wafers = 5},
			ITEM_TRAPCOMP_ENORMOUSCORKSCREW = {bars = 1, wafers = 5},
			ITEM_TRAPCOMP_SPIKEDBALL = {bars = 1, wafers = 4},
			ITEM_TRAPCOMP_LARGESERRATEDDISC = {bars = 1, wafers = 4},
			ITEM_TRAPCOMP_MENACINGSPIKE = {bars = 1, wafers = 5},
		},
	},
	{
		id = "DRINK",
		bars = 0,
		wafers = 0,
	},
	{
		id = "POWDER_MISC",
		bars = 0,
		wafers = 0,
	},
	{
		id = "CHEESE",
		bars = 0,
		wafers = 0,
	},
	{
		id = "FOOD",
		bars = 0,
		wafers = 0,
	},
	{
		id = "LIQUID_MISC",
		bars = 0,
		wafers = 0,
	},
	{
		id = "COIN",
		bars = 0.002,
		wafers = 0.002,
	},
	{
		id = "GLOB",
		bars = 0,
		wafers = 0,
	},
	{
		id = "ROCK",
		bars = 0,
		wafers = 0,
	},
	{
		id = "PIPE_SECTION",
		bars = 3,
		wafers = 9,
	},
	{
		id = "HATCH_COVER",
		bars = 3,
		wafers = 9,
	},
	{
		id = "GRATE",
		bars = 3,
		wafers = 9,
	},
	{
		id = "QUERN",
		bars = 0,
		wafers = 0,
	},
	{
		id = "MILLSTONE",
		bars = 0,
		wafers = 0,
	},
	{
		id = "SPLINT",
		bars = 3,
		wafers = 2,
	},
	{
		id = "CRUTCH",
		bars = 3,
		wafers = 3,
	},
	{
		id = "TRACTION_BENCH",
		bars = 3,
		wafers = 9,
	},
	{
		id = "ORTHOPEDIC_CAST",
		bars = 0,
		wafers = 0,
	},
	{
		id = "TOOL",
		bars = 1,
		wafers = 1,
		subtypes = {
			ITEM_TOOL_MINECART = {bars = 2, wafers = 6},
			ITEM_TOOL_WHEELBARROW = {bars = 2, wafers = 6},
			ITEM_TOOL_STEPLADDER = {bars = 2, wafers = 6},
		},
	},
	{
		id = "SLAB",
		bars = 0,
		wafers = 0,
	},
	{
		id = "EGG",
		bars = 0,
		wafers = 0,
	},
	{
		id = "BOOK",
		bars = 0,
		wafers = 0,
	},
	{
		id = "SHEET",
		bars = 0,
		wafers = 0,
	},
}

local function formatstype(item)
	if item.subtypes == nil then
		return "nil"
	else
		local out = "{\n"
		for id, styp in pairs(item.subtypes) do
			out = out..'\t\t["'..id..'"] = {'..styp.bars..', '..styp.wafers..'},\n'
		end
		return out.."\t}"
	end
end

function generate_result()
	local out = "{\n"
	for _, item in ipairs(data) do
		out = out..'\t{"'..item.id..'", '..item.bars..', '..item.wafers..', '..formatstype(item)..'},\n'
	end
	return out.."}"
end

function generate_react()
	local out = "{\n"
	for _, react in ipairs(reactions) do
		out = out..'\t"'..react..'",\n'
	end
	return out.."}"
end

return _ENV
