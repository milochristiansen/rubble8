
The templates provided by this addon can be used to bind sets of workshops and reactions together into a single coherent
unit that may be added to an entity without needing to specify the addon hooks for each building or reaction individually.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!ATTACH_INDUSTRY;<INDUSTRY_ID>;<CLASS>}

Register all buildings and reactions with the given `<INDUSTRY_ID>` to `<CLASS>`.

Example:

	{!ATTACH_INDUSTRY;EXAMPLE;ADDON_HOOK_PLAYABLE}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!SHARED_INDUSTRY_REACTION;<ID>;<INDUSTRY_ID>;<RAWS>}

Works exactly like `!SHARED_REACTION` except it calls the `INDUSTRY_REACTION` template instead of `REACTION`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!SHARED_INDUSTRY_WORKSHOP;<ID>;<INDUSTRY_ID>;<RAWS>}

Works exactly like `!SHARED_BUILDING_WORKSHOP` except it calls the `INDUSTRY_WORKSHOP` template instead of `BUILDING_WORKSHOP`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!SHARED_INDUSTRY_FURNACE;<ID>;<INDUSTRY_ID>;<RAWS>}

Works exactly like `!SHARED_BUILDING_FURNACE` except it calls the `INDUSTRY_FURNACE` template instead of `BUILDING_FURNACE`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{INDUSTRY_REACTION;<ID>;<INDUSTRY_ID>}

A custom version of `REACTION` that registers it's reaction with the given industry instead of an addon hook or tech class.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{INDUSTRY_WORKSHOP;<ID>;<INDUSTRY_ID>}

A custom version of `BUILDING_WORKSHOP` that registers it's building with the given industry instead of an addon hook or
tech class.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{INDUSTRY_FURNACE;<ID>;<INDUSTRY_ID>}

A custom version of `BUILDING_FURNACE` that registers it's building with the given industry instead of an addon hook or
tech class.
