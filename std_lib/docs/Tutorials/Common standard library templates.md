
Common standard library templates
====================================================================================================

This tutorial introduces a few of the basic Rubble templates and explains how to create a simple addon.

In this tutorial I will be recreating the `addon:User/Bonfire` addon.

The bonfire is a simple furnace that lets you create two kinds of burning objects, one that burns out fairly quickly and
one that burns for quite a while.

First install Rubble as directed in it's readme.
Now create a new directory in the addons directory, call it something like "Bonfire Tutorial", this is your addon directory.

Let's start with the building. Create a new file in your addon directory and name it something like `building_bonfire_tutorial.txt`,
then paste the following code into that file.

	[OBJECT:BUILDING]
	
	{BUILDING_FURNACE;BONFIRE;ADDON_HOOK_PLAYABLE}
		[NAME:Bonfire]
		[NAME_COLOR:6:0:1]
		[DIM:1:1]
		{@BUILD_KEY;SHIFT_F;true}
		[WORK_LOCATION:1:1]
		[BLOCK:1:O]
		[TILE:0:1:240]
		[COLOR:0:1:6:0:0]
		[TILE:1:1:'#']
		[COLOR:1:1:6:0:0]
		[TILE:2:1:19]
		[COLOR:2:1:6:0:0]
		[TILE:3:1:30]
		[COLOR:3:1:6:0:0]

There are three things of note in this file.

* First there is no file header, Rubble adds this automatically, so renaming a file goes from an error-prone two step
process to just a simple file rename.

* Second you will note that the building tag is replaced by some weird thing that uses curly-brackets and has an extra
parameter, this is a Rubble template. This particular template is a direct replacement for the raw tag of the same name,
but it also has one other very important function. This template (as well as lots of other related Rubble templates)
registers a building with an object class. A Rubble object class is a list of items/buildings/reactions/whatever listed
under a name. By using other templates you can extract a list of a specified type of items from a class and do things
with them, in this case automatically add building permissions to entities. `ADDON_HOOK_PLAYABLE` is a special class that
can be used for items, reactions, and buildings, it is part of a special group of object classes created by the `ADDON_HOOKS`
template (which I will explain in more detail later).

* Third the `BUILD_KEY` tag has also been replaced with a template, this template will automatically resolve key conflicts,
so if another building already uses `SHIFT_F` it will choose the next open key (`ALT_F` in this case, unless it is in use
as well). The second parameter specifies whether the key is for a furnace, so in this case it should be true (this
parameter defaults to false, so it can be left off for workshops).

Now that we have a building we need some reactions. Create a new file and name it `reaction_bonfire_tutorial.txt`, then
paste the following code into that file.

	[OBJECT:REACTION]
	
	{REACTION;BONFIRE_BIG_START;ADDON_HOOK_PLAYABLE}
		[NAME:ignite large fire]
		[BUILDING:BONFIRE:CUSTOM_L]
		[REAGENT:A:5:WOOD:NONE:NONE:NONE]
			[PRESERVE_REAGENT]
		[PRODUCT:100:1:BOULDER:NO_SUBTYPE:INORGANIC:BIG_BONFIRE]
		[FUEL]
		[SKILL:SMELT]
	
	{REACTION;BONFIRE_SMALL_START;ADDON_HOOK_PLAYABLE}
		[NAME:ignite small fire]
		[BUILDING:BONFIRE:CUSTOM_S]
		[REAGENT:A:1:WOOD:NONE:NONE:NONE]
			[PRESERVE_REAGENT]
		[PRODUCT:100:1:WOOD:NO_SUBTYPE:INORGANIC:SMALL_BONFIRE]
		[SKILL:SMELT]

The `REACTION` template is almost exactly like the `BUILDING_FURNACE` template (except, of course, it replaces the
`REACTION` tag instead of the `BUILDING_FURNACE` tag).

Of course those reactions won't work without the inorganic materials `BIG_BONFIRE` and `SMALL_BONFIRE`.

Create a new file (name it `inorganic_bonfire_tutorial.txt`) and paste the following code into it.

	[OBJECT:INORGANIC]
	
	{!SHARED_INORGANIC;BIG_BONFIRE;
		[STATE_NAME_ADJ:ALL_SOLID:bonfire]
		[DISPLAY_COLOR:0:0:1]
		[TILE:15]
		[ITEM_SYMBOL:15]
		[IGNITE_POINT:11000]
		[MAT_FIXED_TEMP:20000]
		[MELTING_POINT:NONE]
		[BOILING_POINT:NONE]
		[SPEC_HEAT:10000]
		[SOLID_DENSITY:10000]
		[IS_STONE]
		[NO_STONE_STOCKPILE]
	}
	
	{!SHARED_INORGANIC;SMALL_BONFIRE;
		[STATE_NAME_ADJ:ALL_SOLID:firewood]
		[DISPLAY_COLOR:0:0:1]
		[TILE:15]
		[ITEM_SYMBOL:15]
		[IGNITE_POINT:11000]
		[MAT_FIXED_TEMP:20000]
		[HEATDAM_POINT:11000]
		[MELTING_POINT:NONE]
		[BOILING_POINT:NONE]
		[SPEC_HEAT:10000]
		[SOLID_DENSITY:10000]
		[IS_STONE]
		[NO_STONE_STOCKPILE]
	}

Wow, what's this `!SHARED_INORGANIC` thing? That is one of the `!SHARED_OBJECT` templates. `!SHARED_OBJECT` (and the
templates based off of it, like `!SHARED_INORGANIC`) provides a mechanism for replacing or modifying objects from other
addons. In this case it's not terribly useful, but using it every time you can is a good habit to get into. I will not
go into detail about exactly what `!SHARED_OBJECT` (or it's children) does, as that would take far too much time. I suggest
you go read the documentation for the [Base Templates](/doc/Rubble%20Base%20Templates) for the whole story.

Now there is one last detail, "How exactly do I make my building/reactions usable?". To put it simply, you already have.

Earlier I mentioned the `ADDON_HOOKS` template, this very useful template is already in every entity in the `addon:Base`
addon. Basically `ADDON_HOOKS` adds calls to all the required templates to insert entity permissions for items, reactions,
and buildings for the following classes:

* `ADDON_HOOK_GENERIC`
* `ADDON_HOOK_<entity name>` (For example `ADDON_HOOK_MOUNTAIN` or `ADDON_HOOK_PLAINS`)
* and if the entity is playable (dwarves only by default) `ADDON_HOOK_PLAYABLE`

This means that your new addon should be immediately usable by the dwarves and any other playable races that may be
added by other addons.

Of course for `ADDON_HOOKS` to work you need to have declared the item/building/reaction with the proper Rubble template,
but as you have seen that is a simple matter for buildings and reactions. For items it is a little more complicated, but
still fairly easy.
