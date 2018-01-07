
Basic user templates
====================================================================================================

This tutorial introduces the simplest aspects of custom templates.

I will not be making a full addon in this tutorial, rather I will
just make a template and a few reactions.

Say you want to make a workshop that allows you to produce metal
weapons without needing an anvil. The first problem you will encounter
is that writing enough reactions to make such a workshop useful is a
tremendous amount of work. Using a Rubble template to cut out most of
the redundant parts of the reaction allows you to make such reactions
in as little as one line, allowing you to make dozens of reactions in
very little time.

Anyway enough talk, time for the template:

	{!TEMPLATE;FORGE_ITEM;id;name;type;mat;matname;count=1;
	{REACTION;FORGE_%{id}_%{mat};ADDON_HOOK_SWAMP}
		[NAME:forge %matname %name]
		[BUILDING:WARCRAFTER_SAURIAN:NONE]
		[REAGENT:metal:150:BAR:NONE:INORGANIC:%mat]
		[PRODUCT:100:%count:%type:%id:INORGANIC:%mat]
		[FUEL]
		[SKILL:METALCRAFT]
	}

The first thing to note is that the template body consists mostly of
normal Rubble code with a few odd little bits prefixed with a '%' symbol.
Each of these "Replacement Tokens" is defined just before the template
body and just after the template name. For example the first of these
tokens (also called "Template Parameters", or just "params") is named
"id" and can be accessed via "%id" or "%{id}". The value of a template
parameter is determined when the template is called.

Template parameter names may not have any non-alphanumeric characters in them.

A similar system is used for configuration variables with two key differences:

1. `$` is used instead of `%`.
2. Configuration variables will not be expanded inside nested templates.

To really describe how a user defined template like this works we need
values for the parameters, so here is an example call:

	{FORGE_ITEM;ITEM_WEAPON_SPEAR_SAURIAN;small spear;WEAPON;STEEL_WATER;water steel}

That call will expand into the following:

	{REACTION;FORGE_ITEM_WEAPON_SPEAR_SAURIAN_STEEL_WATER;ADDON_HOOK_SWAMP}
		[NAME:forge water steel small spear]
		[BUILDING:WARCRAFTER_SAURIAN:NONE]
		[REAGENT:metal:150:BAR:NONE:INORGANIC:STEEL_WATER]
		[PRODUCT:100:1:WEAPON:ITEM_WEAPON_SPEAR_SAURIAN:INORGANIC:STEEL_WATER]
		[FUEL]
		[SKILL:METALCRAFT]

As you can see it is just a straight forward variable expansion.

One thing sharp-eyed readers may have noticed is that there was never a
value defined for "count", if you will look up to the template definition
you will see that count is followed by an equals sign (=). If a parameter
name is followed by an equals sign whatever is after the equals sign is
used as the default value for that parameter, so in this case count defaults
to "1".

There are a few more interesting things that standard templates like this
can do, but most of them have been replaced by the much more flexible
script templates (which are too advanced to detail here). For more on how
templates work, and how they interact with other parts of Rubble, see "Rubble Basics".

(The templates/items/materials used in this tutorial come from the (long obsolete)
`Better Dorfs/Saurian/Warcrafter` addon)
