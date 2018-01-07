
The "libs_change_build_list" module has some functions that allow you to add/remove workshops
and furnaces to/from different categories of the hard coded building menu. For example you could add
a user defined workshop to the machines menu instead of the workshops menu, or you could remove a
hard coded vanilla building so it is impossible to construct.

Examples:

	-- Remove the carpenters workshop.
	ChangeBuilding("CARPENTERS", "WORKSHOPS", false)
	
	-- Make it impossible to build walls.
	ChangeBuildingAdv(df.building_type.Construction, df.construction_type.Wall, -1, "CONSTRUCTIONS", false)
	
	-- Add the mechanic's workshop to the machines category.
	ChangeBuilding("MECHANICS", "MACHINES", true, "CUSTOM_E")

* * *

"ChangeBuilding" is the quick and easy function, it allows you to disable/enable workshops and furnaces.

	ChangeBuilding(id, category, add, key)

"id" is the workshop ID, either one of the following or the ID of a user defined workshop or furnace.

	CARPENTERS
	FARMERS
	MASONS
	CRAFTSDWARFS
	JEWELERS
	METALSMITHSFORGE
	MAGMAFORGE
	BOWYERS
	MECHANICS
	SIEGE
	BUTCHERS
	LEATHERWORKS
	TANNERS
	CLOTHIERS
	FISHERY
	STILL
	LOOM
	QUERN
	KENNELS
	ASHERY
	KITCHEN
	DYERS
	TOOL
	MILLSTONE
	
	WOOD_FURNACE
	SMELTER
	GLASS_FURNACE
	MAGMA_SMELTER
	MAGMA_GLASS_FURNACE
	MAGMA_KILN
	KILN

"category" is one of the following category IDs:

	MAIN_PAGE
	SIEGE_ENGINES
	TRAPS
	WORKSHOPS
	FURNACES
	CONSTRUCTIONS
	MACHINES
	CONSTRUCTIONS_TRACK

If you want you can also use numeric IDs for category. The ID number of a particular build page can
be gotten by running the following DFHack command when the page in question is showing:

	:lua df.global.ui_sidebar_menus.building.category_id

If "add" is true the workshop/furnace is added to the end of the list, if false it is removed from
the list (if it exists).

"key" is the key to use for the building if "add" is true. Any valid key name can be specified here
(exactly like you would for a `BUILD_KEY` tag). This value is optional.

If you prefer you can also specify numeric key IDs, get a list of these from the enum `df.interface_key`.

* * *

"ChangeBuildingAdv" is for advanced users, it allows you to disable/enable *any* building, not just
workshops and furnaces.

	ChangeBuildingAdv(typ, subtyp, custom, category, add, key)

"typ", "subtyp", and "custom" are the numeric ID numbers of the building you want to effect, all other
parameters are the same as those for ChangeBuilding.

Values for "typ" are found in the `df.building_type` enum.

Values for "subtyp" can be found in the `df.workshop_type` or `df.furnace_type` enum. There are
other enums for traps and suchlike, but I don't feel like looking them up now, do it yourself.
Many building types do not have a subtype, use `-1` for them.

"custom" is the raw index (where it is found in `df.global.world.raws.buildings.all`) of a user
defined workshop or furnace. Obviously only makes sense with workshop and furnace building types.
In most cases you will want to use `-1` for "custom".

* * *

"RevertBuildingChanges" allows you to revert a change made earlier with "ChangeBuilding" or "ChangeBuildingAdv".

	RevertBuildingChanges(id, category)

The parameters are the same as the parameters with the same names for "ChangeBuilding".

* * *

"RevertBuildingChangesAdv" allows you to revert a change made earlier with "ChangeBuilding" or "ChangeBuildingAdv".

	RevertBuildingChangesAdv(typ, subtyp, custom, category)

The parameters are the same as the parameters with the same names for "ChangeBuildingAdv".

* * *

"IsEntityPermitted" allows you to check if a workshop or furnace is permitted in the current entity.
This is very useful for adding workshops by script where you only want to add the workshop if the
entity should have it.

	IsEntityPermitted(id)

"id" should be the string ID of the workshop.
