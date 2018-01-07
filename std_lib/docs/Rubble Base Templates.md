	
Rubble Template Documentation
====================================================================================================

The templates described here are all defined in the `addon:Libs/Base` addon.

Everything you can do with templates you can do with scripts, and the script version will be faster to run and easier to
read (at the cost of convenience). If you find yourself writing huge blocks of template code to do something really
complicated, it may be better to write a script powered template to do the entire task in one step (or at least to do the
hardest part). This will also usually result in shorter generation times (although it takes a *lot* of RTL code to make
a noticeable difference) RTL (Rubble Template Language) is a scripting language in it's own right, but it is a very slow
one with few fancy features.

Before passing template parameters to the template dispatcher, the Rubble parser carries out the following transforms on
each parameter:

1. Leading and trailing whitespace is stripped.
2. If the parameter begins and ends with matching quote characters (and otherwise matches all the requirements of a
   quoted string as defined by the [Go language](http://www.golang.org) the quoting will be stripped and any escape
   sequences that are valid for the type of quotes used will be expanded.

You usually cannot place template calls inside other templates' parameters. "User templates" (templates whose bodies are
written in RTL) may or may not allow this, as it depends on how the parameter is used. "Script templates" (templates whose
bodies are *not* written in RTL) decide if they want to parse their parameters or not on an individual basis. For both
kinds it is very rare that a parameter is parsed unless it is intended to be used as raws.

Many things mentioned in passing here are discussed in detail in [Rubble Basics](/doc/Rubble%20Basics.md).

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!TEMPLATE;<NAME>;[<PARAM>[=<DEFAULT_VALUE>]...];<CODE>}

Creates a new template definition with name `<NAME>`, subsequently calling `{<NAME>}` will return
a new parse of `<CODE>`.

Calling `{<NAME>;<ARGUMENT_1>;<ARGUMENT_2>}` will replace instances of `%<PARAM_1>` or `%{<PARAM_1>}`
with `<ARGUMENT_1>`, instances of `%<PARAM_2>` or `%{<PARAM_2>}` with `<ARGUMENT_2>`, etcetera. Default
values may be specified for parameters.

Variables (`$<VAR_NAME>` or `${<VAR_NAME>}`) will be expanded in the `<CODE>` after the parameters are
expanded (so variables in the parameters will work fine). Variables will NOT be expanded if they are
in the body of a nested template! To expand variables even inside nested templates use `&` instead of `$`.

You should be able to nest templates provided the nested templates are in the same parse stage as the
enclosing template *or* a later stage. Templates enclosed in another template's arguments should work
as well. The rules are a little different when passing arguments containing templates to script templates,
there whether or not to parse arguments is up to the template (most will for arguments that are supposed
to be raws).

The template parse sequence is very simple:

1. Expand the parameters (`%PARAM_NAME` or `%{PARAM_NAME}` becomes `<PARAM_VALUE>`) in the `<BODY>`
2. Expand any configuration variables that use "normal" expansion syntax (`$VAR_NAME` or `${VAR_NAME}`
   becomes `<VAR_VALUE>`) in the `<BODY>`, but not if they are contained in a nested template.
3. Expand any configuration variables that use "immediate" expansion syntax (`&VAR_NAME` or `&{VAR_NAME}`
   becomes `<VAR_VALUE>`) in the `<BODY>`.
4. `<BODY>` is passed to the Rubble template parser (to parse nested templates).
5. The template parser result is used to replace the template call.

Example:

	{!TEMPLATE;FOO;bar}
	{FOO}
	{FOO}
	{!TEMPLATE;GREET;thing;Hello %{thing}!}
	{GREET;World}
	{!TEMPLATE;GREET_DWARF;dwarf=Urist;{GREET;%{dwarf}}}
	{GREET_DWARF}
	{GREET_DWARF;Led}
	{@SET;TEST;‼Fun‼}
	{GREET;$TEST}

Evaluates to:

	bar
	bar
	Hello World!
	Hello Urist!
	Hello Led!
	Hello ‼Fun‼!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{COMMENT;<STUFF>...}
	{C;<STUFF>...}

Doesn't parse or return anything.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@VOID;<PRERAWS>...}
	{!VOID;<PRERAWS>...}
	{VOID;<PRERAWS>...}
	{#VOID;<PRERAWS>...}
	{V;<PRERAWS>...}

Parses `<PRERAWS>`, but doesn't return anything. Useful for suppressing the normal output of a
template.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@ECHO;<PRERAWS>...}
	{!ECHO;<PRERAWS>...}
	{ECHO;<PRERAWS>...}
	{#ECHO;<PRERAWS>...}
	{@;<PRERAWS>...}
	{!;<PRERAWS>...}
	{E;<PRERAWS>...}
	{#;<PRERAWS>...}

Returns `<PRERAWS>`. Used to strip leading and trailing whitespace for better formatting of output,
for controlling variable expansion, and controlling exactly when an `@` template is parsed.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!ABORT;<MESSAGE>}
	{ABORT;<MESSAGE>}
	{#ABORT;<MESSAGE>}

Forces Rubble to exit, `<MESSAGE>` is displayed.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!PRINT;<MSG>...}
	{PRINT;<MSG>...}
	{#PRINT;<MSG>...}

Writes `<MSG>` to the console. Each parameter gets it's own line. The parameters are not parsed, but
variables are expanded.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!WARN;<MSG>...}
	{WARN;<MSG>...}
	{#WARN;<MSG>...}

Writes `<MSG>` to the console. Each parameter gets it's own line. The parameters are not parsed, but
variables are expanded.

Messages generated by this template are printed twice, once when the template is parsed and once at
the end of the log.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@SCRIPT;<CODE>;[<TAG>="LangLua"]}

Runs script code and returns the result (as a string). Use `<TAG>` to tell Rubble what language the
`<CODE>` is, this defaults to Lua.

Variables are **not** expanded in this template's parameters! This is to prevent possible clobbering of
script code by the expander.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@SET;<NAME>;<VALUE>;[<EXPAND>=true]}

Sets a variable of name `<NAME>` to value `<VALUE>`. Returns nothing. To read the variable back simply
prefix it's name with a dollars sign (`$`) in a template parameter or template body.

In general variables should be declared in your addon.meta file so that users may modify them before
generation (provided that the variable is not strictly internal). Make sure you give your variables
unique names, a good way to do this is to include your addon name as part of the variable name.

By convention variable names are always all uppercase, but there is no reason why they can't be any
string you want, see [Rubble Basics](/doc/Rubble%20Basics.md#CFGVars) for more information.

If `<EXPAND>` is set to `false` then variables in `<VALUE>` are *not* expanded. This allows you to
set variables to things that the expander would mangle or that you want to expand later.

Example:

	{@SET;TEST;Hello!}{ECHO;$TEST}

Result:

	Hello!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@IF;<STRING1>;<STRING2>;<THEN_PRERAWS>;[<ELSE_PRERAWS>=""]}

If `<STRING1>` and `<STRING2>` are equal, then `<THEN_PRERAWS>` are parsed and returned. Else,
`<ELSE_PRERAWS>` are parsed and returned. This is very useful with variables, see `@SET`.

Example:

	{@IF;$TEST_VAR;YES;[FOO];[BAR]}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@IF_ACTIVE;<ADDON>;<THEN_PRERAWS>;[<ELSE_PRERAWS>=""]}

If `<ADDON>` is active, then `<THEN_PRERAWS>` are parsed and returned. Else, `<ELSE_PRERAWS>` are
parsed and returned.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@IF_SKIP;<STRING1>;<STRING2>}

If `<STRING1>` and `<STRING2>` are equal then skip the current file. This does **not** abort the
current parsing pass!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!SHARED_OBJECT;<ID>;<DEFINITION>}

Adds a common object with the id `<ID>` to the dictionary. `<DEFINITION>` may be any raws. If this
template call is the first with this `<ID>`, then the given `<DEFINITION>` will be used in the
finished raws.

Note that the contents of `<DEFINITION>` are always parsed, whether or not the results will appear
in the raws.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!SHARED_CREATURE;<ID>;<DEFINITION>}
	{!SHARED_PLANT;<ID>;<DEFINITION>}
	{!SHARED_INORGANIC;<ID>;<DEFINITION>}
	{!SHARED_MATERIAL_TEMPLATE;<ID>;<DEFINITION>}
	{!SHARED_CREATURE_VARIATION;<ID>;<DEFINITION>}
	{!SHARED_TISSUE_TEMPLATE;<ID>;<DEFINITION>}
	{!SHARED_BODY_DETAIL_PLAN;<ID>;<DEFINITION>}
	{!SHARED_INTERACTION;<ID>;<DEFINITION>}
	{!SHARED_BODY;<ID>;<DEFINITION>}
	{!SHARED_TRANSLATION;<ID>;<DEFINITION>}
	{!SHARED_SYMBOL;<ID>;<DEFINITION>}
	{!SHARED_WORD;<ID>;<DEFINITION>}
	{!SHARED_COLOR;<ID>;<DEFINITION>}
	{!SHARED_COLOR_PATTERN;<ID>;<DEFINITION>}
	{!SHARED_SHAPE;<ID>;<DEFINITION>}

Specialized variants of `!SHARED_OBJECT`.

When using these templates do not include the object header tag (for example `[PLANT:<ID>]`) or you will get
raw duplication errors!

To access shared objects created with this template you will need to prefix `<ID>` with the object type (for
an inorganic the actual ID of the created shared object would be `INORGANIC:<ID>`, the others are similar).

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!SHARED_REACTION;<ID>;<CLASS>;<DEFINITION>}
	{!SHARED_BUILDING_WORKSHOP;<ID>;<CLASS>;<DEFINITION>}
	{!SHARED_BUILDING_FURNACE;<ID>;<CLASS>;<DEFINITION>}
	{!SHARED_ENTITY;<ID>;<PLAYABLE_FORT>;<PLAYABLE_ADV>;<DEFINITION>}

These templates are exactly like the other specialized `!SHARED_OBJECT` variants except they also insert calls to
`REACTION`, `BUILDING_WORKSHOP`, `BUILDING_FURNACE`, and `!ENTITY_PLAYABLE` as appropriate.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!SHARED_OBJECT_CATEGORY;<ID>;<CATEGORY>}

Add shared object `<ID>` to category `<CATEGORY>`. You may add a single object to as many categories
as you like. By default this template is auto-inserted by the specialized `!SHARED_OBJECT` variants
with the category being the name of the raw tag the template replaces.

The category information may then be queried by scripts, or if you know what you are doing, it is possible
to use templates. For example `@FOREACH_LIST` with the master key `Libs/Base:!SHARED_OBJECT_CATEGORY:<CATEGORY>`
will allow you to iterate all object in a category. You will probably want to use `@IF` with `@READ_TABLE`
and `@PARSE_TO` to make sure the object has not been invalidated since it was added.

Example:

	# Print the IDs of all inorganics.
	{E;{@FOREACH_LIST;Libs/Base:!SHARED_OBJECT_CATEGORY:INORGANIC;
		{@PARSE_TO;TEMP;{@READ_TABLE;Libs/Base:!SHARED_OBJECT_CATEGORY:INORGANIC;%val}
		}{@IF;$TEMP;t;"\t%{val}\n"}
	}}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{SHARED_OBJECT_EXISTS;<ID>;<THEN_PRERAWS>;[<ELSE_PRERAWS>=""]}
	{#SHARED_OBJECT_EXISTS;<ID>;<THEN_PRERAWS>;[<ELSE_PRERAWS>=""]}

If a `!SHARED_OBJECT` with the id `<ID>` exists then `<THEN_PRERAWS>` are parsed and returned. Else,
`<ELSE_PRERAWS>` are parsed and returned.

This is very useful for making addons with additional behavior that depends on things (items,
materials, ect) from other addons.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{SHARED_OBJECT_ADD;<ID>;<PRERAWS>}

Appends the result of parsing `<PRERAWS>` to the end of `!SHARED_OBJECT` `<ID>`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{REGISTER_REACTION_CLASS;<ID>;<CLASS>}

Adds a `[REACTION_CLASS:<CLASS>]` tag to a `!SHARED_OBJECT`.

This is just a specialized version of `SHARED_OBJECT_ADD`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{REGISTER_REACTION_PRODUCT;<ID>;<CLASS>;<PRODUCT>}

Adds a `[MATERIAL_REACTION_PRODUCT:<CLASS>:<PRODUCT>]` tag to a `!SHARED_OBJECT`.

This is just a specialized version of `SHARED_OBJECT_ADD`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{SHARED_OBJECT_KILL_TAG;<ID>;<TAG>}

Disable **all occurrences** of `<TAG>` in shared object `<ID>`. The tag is disabled by replacing it's
square brackets with dashes (`-`).

`<TAG>` is the ID of the tag you wish to disable, do not add square brackets. For more precise targeting
you may specify parameters, use `&` as a wild card parameter. If you specify parameters you do not need
to specify them all, all you specify will be matched in order.
	
This will only modify tags present in the body passed to the initial call to `!SHARED_OBJECT`,
anything added by `SHARED_OBJECT_ADD` is not effected.

More complicated editing of an object will require scripts.

Example:

	{SHARED_OBJECT_KILL_TAG;SLADE;UNDIGGABLE}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{SHARED_OBJECT_REPLACE_TAG;<ID>;<TAG>;<REPLACEMENT>}

Replace **all occurrences** of `<TAG>` in shared object `<ID>` with `<REPLACEMENT>`.

`<TAG>` is the ID of the tag you wish to replace, do not add square brackets. For more precise targeting
you may specify parameters, use `&` as a wild card parameter. If you specify parameters you do not need
to specify them all, all you specify will be matched in order.

This will only modify tags present in the body passed to the initial call to `!SHARED_OBJECT`,
anything added by `SHARED_OBJECT_ADD` is not effected.

More complicated editing of an object will require scripts.

Example:

	{SHARED_OBJECT_REPLACE_TAG;SLADE;UNDIGGABLE;[AQUIFER]}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!SHARED_OBJECT_DUPLICATE;<OLD_ID>;<NEW_ID>;[<EDIT_RAWS>=true];[<ADD_CATEGORY>=true]}

Duplicate shared object `<OLD_ID>` using the name `<NEW_ID>`. Shared object `<OLD_ID>` must exist,
make sure this is evaluated *after* that object! If a shared object with the ID `<NEW_ID>` already
exists this does nothing (so addons may override each other).

Setting `<EDIT_RAWS>` to anything other than `true` will make this template not try to fix the raws,
which may lead to duplicate raw objects!

Setting `<ADD_CATEGORY>` to anything other than `true` will make this template not auto-insert a call
to `!SHARED_OBJECT_CATEGORY`. This will only take effect if raw auto-correction is in effect, as otherwise
there is no way to know what default category to use.

The raw fixer is kinda simple minded, but it should work in common cases. The raw fixer simply changes
the first parameter of the first raw tag to the new ID. If you need to do something complicated it is
better to set `<EDIT_RAWS>` to false and fix the raws yourself (using a script or clever use of
`SHARED_OBJECT_REPLACE_TAG` and other similar templates).

This template *will* accept standard two part object IDs, but unless the "type" part of the ID matches
the name of the first tag in the object having auto-correction activated will abort generation with an
error.

Generally it is better to use a custom template to create multiple similar objects, but this is nice
to have when working with objects from other addons.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{SHARED_OBJECT_MERGE;<ID>;<RULES>;<SOURCE>}

Apply rule-based changes to the shared object with `<ID>`.

This one is hard to explain without an example, so here you go:

	{!SHARED_OBJECT;TEST;[FOO:BAR:BAZ]}
	{SHARED_OBJECT_MERGE;TEST;$:?:&;[FOO:BAZ:BAR]}

Result:

	[FOO:BAZ:BAZ]

Documentation of the rule format is in [Rubble Basics](/doc/Rubble%20Basics.md#MergeRules).

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{BUILDING_WORKSHOP;<ID>;<CLASS>}

Register a workshop to class `<CLASS>`.

Used with `ADDON_HOOKS`, `#USES_TECH`, or `#USES_BUILDINGS`.

Returns `[BUILDING_WORKSHOP:<ID>]`

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{BUILDING_FURNACE;<ID>;<CLASS>}

Register a furnace to class `<CLASS>`.

Used with `ADDON_HOOKS`, `#USES_TECH`, or `#USES_BUILDINGS`.
	
Returns `[BUILDING_FURNACE:<ID>]`

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{BUILDING_ADD_CLASS;<CLASS>;[<ID>=nil]}

Adds a class to an existing building.

Used with `ADDON_HOOKS`, `#USES_TECH`, or `#USES_BUILDINGS`.

If `<ID>` is not present the name of the last building defined by a `BUILDING_WORKSHOP` or
`BUILDING_FURNACE` template is used.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{REMOVE_BUILDING;<ID>;<CLASS>}

Removes a building from a class.

The building does not need to exist yet, this template will work regardless of evaluation order.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{REMOVE_BUILDING_FROM_PLAYABLES;<ID>}

Removes a building from all addon hooks that describe playable races.

The playability information comes from the `!ENTITY_PLAYABLE` template group.
Make sure this is not evaluated until playability information is in it's final state!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{#USES_BUILDINGS;<CLASS>}

Usable in entity definitions. Expands to a list of building permissions for the `<CLASS>`.

It is a very good idea to use `ADDON_HOOKS` instead of this template!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{REACTION;<ID>;<CLASS>}

Register a reaction to class `<CLASS>`.

Used with `ADDON_HOOKS`, `#USES_TECH`, or `#USES_REACTIONS`.

In most cases you will want to use `!SHARED_REACTION` instead.

Returns `[REACTION:<ID>]`

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{DFHACK_REACTION;<ID>;<COMMAND>;<CLASS>}

Exactly like `REACTION`, except that `<COMMAND>` is run whenever the reaction is completed (provided
that DFHack is installed of course).

I suggest you use `DFHACK_REACTION_BIND` with `!SHARED_REACTION` instead.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{DFHACK_REACTION_BIND;<COMMAND>;[<ID>=nil]}

Binds a command to a reaction, like `DFHACK_REACTION` except for an already existing reaction.

If `<ID>` is not present the name of the last reaction defined by a `REACTION` template is used.
(Specialized variants of `REACTION`, such as `DFHACK_REACTION`, work as well)

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{REACTION_ADD_CLASS;<CLASS>;[<ID>=nil]}

Adds a class to an existing reaction.

Used with `ADDON_HOOKS`, `#USES_TECH`, or `#USES_REACTIONS`.

If `<ID>` is not present the name of the last reaction defined by a `REACTION` template is used.
(Specialized variants of `REACTION`, such as `DFHACK_REACTION`, work as well)

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{REMOVE_REACTION;<ID>;<CLASS>}

Removes a reaction from a class.

The reaction does not need to exist yet, this template will work regardless of evaluation order.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{REMOVE_REACTION_FROM_PLAYABLES;<ID>}

Removes a reaction from all addon hooks that describe playable races.

The playability information comes from the `!ENTITY_PLAYABLE` template group.

Make sure this is not evaluated until playability information is in it's final state!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{#USES_REACTIONS;<CLASS>}

Usable in entity definitions. Expands to a list of reaction permissions for the `<CLASS>`.

It is a very good idea to use `ADDON_HOOKS` instead of this template!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!REACTION_NEW_CATEGORY;<ID>;<NAME>;<DESCRIPTION>;[<KEY>="";[<PARENT>=""]]}

Defines a new reaction menu category for use with `REACTION_CATEGORY`. Use `<PARENT>` to create nested menus.

This template creates a new dummy reaction named `_REACTION_CATEGORY_<ID>_`. This reaction will
not show to the user and is only used to guarantee that the menus are created in the required order by the game.
If a parent is specified it must have been already defined with this template.

I am not sure if DF requires parent categories to be defined before children, but this templates does, so you
will always want to define your categories at the top of the first reaction file to use them, parents then children.

Example:

	{!REACTION_NEW_CATEGORY;CATEGORY_TEST;test;A reaction category test.;CUSTOM_T}

Returns:

	[REACTION:_REACTION_CATEGORY_CATEGORY_TEST_]
		[CATEGORY:CATEGORY_TEST]
			[CATEGORY_NAME:test]
			[CATEGORY_DESCRIPTION:A reaction category test.]
			[CATEGORY_KEY:CUSTOM_T]

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{REACTION_CATEGORY;<ID>}

Inserts a previously defined category into a reaction. You must have the category already defined with
`!REACTION_NEW_CATEGORY`.

There is nothing inherently wrong with the default reaction category system, but this introduces a small bit
of typo protection in that it will only allow you to use categories that are predefined.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{#USES_TECH;<CLASS>}

Combo of `#USES_BUILDINGS` and `#USES_REACTIONS`.

It is a very good idea to use `ADDON_HOOKS` instead of this template!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!SHARED_ITEM;<TYPE>;<ID>;<DEFINITION>}

Registers an item `<ID>` of type `<TYPE>`. Used later with `ADDON_HOOKS`, `#USES_ITEMS`, and
`ITEM_CLASS`.

Returns:

	{!SHARED_OBJECT;<ID>;
	[ITEM_<TYPE>:<ID>]
		<DEFINITION>
	}{!SHARED_OBJECT_CATEGORY;ITEM_<TYPE>:<ID>;ITEM_<TYPE>}

`<TYPE>` must be one of `AMMO`, `ARMOR`, `DIGGER`, `FOOD`, `GLOVES`, `HELM`, `INSTRUMENT`, `PANTS`,
`SHIELD`, `SHOES`, `SIEGEAMMO`, `TOOL`, `TOY`, `TRAPCOMP` or `WEAPON`.

Type `DIGGER` is treated like type `WEAPON` except in entities, there it translates into a `DIGGER`
tag.

Type `FOOD` just translates directly to a call to `!SHARED_OBJECT`, no support for items classes is
initiated (as foods do not need to be registered). The only reason `SHARED_ITEM` supports `FOOD` at
all is for consistency.

`SHARED_ITEM` is just a (very) specialized version of `!SHARED_OBJECT`, look there for more info.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!ITEM_CLASS;<CLASS>;[<RARITY>=COMMON]}
	{!ITEM_CLASS;<TYPE>;<ITEM>;<CLASS>;[<RARITY>=COMMON]}

Sets an items class and rarity. 

The first form of an `ITEM_CLASS` template always refers to the last `!SHARED_ITEM` template before it.

The second form is for use in addons or other places where the call cannot follow the item
definition.

`<RARITY>` can be `RARE`, `UNCOMMON`, `COMMON` and `FORCED`.

In case of tow or more calls with the same `<TYPE>`, `<ITEM>`, and `<CLASS>` the most common `<RARITY>` is used.

Example:

	{!SHARED_ITEM;WEAPON;ITEM_WEAPON_TEST;
		The weapon definition...
	}{ITEM_CLASS;TEST_WEAPONS}
	
	{#USES_ITEMS;TEST_WEAPONS} -> [WEAPON:ITEM_WEAPON_TEST]

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{REMOVE_ITEM;<ID>;<CLASS>}

Removes an item from a class.

The item does not need to exist yet, this template will work regardless of evaluation order.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{REMOVE_ITEM_FROM_PLAYABLES;<ID>}

Removes an item from all addon hooks that describe playable races.

The playability information comes from the `!ENTITY_PLAYABLE` template group.

Make sure this is not evaluated until playability information is in it's final state!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{#USES_ITEMS;<CLASS>}

Usable in entity definitions. Expands to a list of item permissions of the `<CLASS>`. When using
multiple `#USES_ITEMS` calls make sure every item is returned by at most one `#USES_ITEMS` call.

It is a very good idea to use `ADDON_HOOKS` instead of this template!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{ADDON_HOOKS;<ID>}

Usable in entity definitions, `ADDON_HOOKS` expands to a list of addon hooks for the entity (Addon
hooks are tech/item classes).

By default the following hooks are installed:

	ADDON_HOOK_GENERIC
	ADDON_HOOK_<ID>

`<ID>` should be the same ID you pass to `!ENTITY_PLAYABLE`.

If the entity is playable in fortress mode (according to `!ENTITY_PLAYABLE` and friends) then the
`ADDON_HOOK_PLAYABLE` hook is also installed.

This template interacts at a low level with `!ENTITY_PLAYABLE`, `SHARED_ITEM`, `BUILDING_WORKSHOP`,
`BUILDING_FURNACE`, and `REACTION` as well as their many variants and supporting templates. Use this
template and it's supports in all your entities for maximum compatibility with the standard
addons.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{#ADDON_HOOK;<ID>}

Creates a single addon hook named `ADDON_HOOK_<ID>`. This is mostly for internal use, but rarely it may be
helpful on it's own. `ADDON_HOOKS` is just a string of calls to this template.

Use this only if you want to create a common object class used by multiple entities and documented for external
use. Internal classes should not use this template.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!ENTITY_PLAYABLE;<ID>;<FORT>;<ADV>}

Sets an entity's playability state.

* `<FORT>` is whether or not the entity is playable in fortress mode.
* `<ADV>` controls adventure mode playability.

Acceptable values are `true`/`false`, `t`/`f`, `yes`/`no`, `y`/`n`, `-1`/`0`, and `1`/`0` (not case sensitive).

`<ID>` should be the same ID you pass to `ADDON_HOOKS`.

This template interacts at a low level with `ADDON_HOOKS`, `SHARED_ITEM`, `BUILDING_WORKSHOP`,
`BUILDING_FURNACE`, and `REACTION` as well as their many variants and supporting templates. Use this
template and it's supports in all your entities for maximum compatibility with the standard addons.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{ENTITY_PLAYABLE_EDIT;<ID>;<KEY>;<VALUE>}

Edits an entity's playability state (as set by `!ENTITY_PLAYABLE`).
	
`<KEY>` may be `FORT` or `ADV` (not case sensitive).

Acceptable values are `true`/`false`, `t`/`f`, `yes`/`no`, `y`/`n`, `-1`/`0`, and `1`/`0` (not case sensitive).

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@IF_ENTITY_PLAYABLE;<ID>;<KEY>;<THEN>;[<ELSE>=""]}

If an entity is playable for a specific mode parse `<THEN>` else parse `<ELSE>`.
	
`<KEY>` may be `FORT` or `ADV` (not case sensitive).

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{#ENTITY_NOBLES;<ID>;<DEFAULT>}

Write the nobles to the entity.
	
If `ENTITY_REPLACE_NOBLES` was called use that value, else use `<DEFAULT>`, then add anything added
by `ENTITY_ADD_NOBLE`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{ENTITY_ADD_NOBLE;<ID>;<NOBLE>}

Add nobles to the end of the existing ones for the specified entity.

This can be called more than once, as the nobles are simply added together.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{ENTITY_REPLACE_NOBLES;<ID>;<NOBLES>}

Replace the nobles for the specified entity.

Does not effect nobles that may have been added via `ENTITY_ADD_NOBLE`,

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{DFHACK_RUNCOMMAND;<COMMAND>}

Sets a DFHack command up to run when the world is loaded.

Example:

	{DFHACK_RUNCOMMAND;workflow enable drybuckets auto-melt}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@ADV_TIME;<COUNT>;<UNIT>}

Generates a time value for use in interactions and the like.

This version is adventure mode centric.
	
Using values like ".5" for the `<COUNT>` value should work but "1/2" will not.
	
Valid values for `<UNIT>` are:

	SECOND
	SECONDS
	MINUTE
	MINUTES
	HOUR
	HOURS
	DAY
	DAYS
	WEEK
	WEEKS
	MONTH
	MONTHS
	SEASON
	SEASONS
	YEAR
	YEARS

Example:

	{@ADV_TIME;5;DAYS} -> 432000

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@FORT_TIME;<COUNT>;<UNIT>}

Generates a time value for use in interactions and the like.
Exactly like `@ADV_TIME` except for fortress mode.

Units below `MINUTE` may be less than useful, as fortress mode time units lack precision.

Example:

	{@FORT_TIME;5;DAYS} -> 6000

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@GROWDUR;<COUNT>;<UNIT>}

A direct replacement for the `GROWDUR` tag that lets you specify time in real-world units.

Uses the same unit types as `@ADV_TIME`.
	
Units below `DAY` may be less than useful, as growth duration time units lack precision.
	
Example:

	{@GROWDUR;5;DAYS} -> [GROWDUR:60]

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@BUILD_KEY;<KEY>;[<FURNACE>=false]}

A replacement for the BUILD_KEY tag that automatically works out key conflicts.

`<KEY>` should be of the form: `X`, `SHIFT_X`, `CTRL_X` or `ALT_X`.
`<FURNACE>` should be `true` or `false`, set to `true` if the building is a furnace.

If the requested key is already used it chooses the next open key in this order:

	X
	SHIFT_X
	CTRL_X
	ALT_X

For example if you try to set a workshop key to `M` (which is used by the Mason's Workshop)
you will get `[BUILD_KEY:CUSTOM_CTRL_M]` (as `SHIFT_M` is used by the millstone).
`ALT_Z` will wrap around to `A`, so no worries about running out (unless you use more than 104
buildings per category).

Please note that while this template "knows" about the hard coded vanilla build keys it will not
magically work with other build keys that do not use this template.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CLEAR_KEY;<KEY>;[<FURNACE>=false]}

This template allows you to tell `@BUILD_KEY` that a key is unused, even when it isn't. This is not
useful most of the time, but if you are using DFHack to remove vanilla workshops it can come in handy.

Keys are specified with the same syntax used by `@BUILD_KEY`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@STR_LOWER;<STRING>}

Returns the lowercase version of `<STRING>`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@STR_UPPER;<STRING>}

Returns the uppercase version of `<STRING>`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@STR_TITLE;<STRING>}

Returns `<STRING>` with the first letter of every word changed to it's title case.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@STR_REPLACE;<STRING>;<OLD>;<NEW>;[<N>=-1]}

Replaces `<N>` occurrences of `<OLD>` with `<NEW>` in `<STRING>` and returns the result. If `<N>` is `-1` then it replaces
all occurrences.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@STR_TO_ID;<STRING>}

Returns a version of `<STRING>` that is more appropriate for use as an ID, eg spaces and colons replaced with underscores
and converted to all uppercase.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@STR_SPLIT;<STRING>;<DELIM>;[<MAX>=-1]}

Splits `<STRING>` at every occurrence of `<DELIM>` and gives the result by setting sequential numeric config vars,
starting from 0 (see example).

If `<MAX>` is set the at most `<MAX>` items will be returned (the last item will be the unsplit remainder).

Example:

	{@STR_SPLIT;abc:xyz;:}
	{!PRINT;The first part is $0 and the second part is $1}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@GENERATE_ID;<PREFIX>}

Each time this is called it returns a new unique string in the form `<PREFIX>_<N>`, where `<N>` is an integer starting
from 0.

The value of `<N>` is tracked separately for each `<PREFIX>`.

This is useful for when you need to generate a long list of something (commonly reactions) where you don't care about
their IDs, but where the IDs need to be unique.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@GENERATE_COUNT;<NUMBER>}

If `<NUMBER>` is less than 2 then this returns nothing, else it returns `" (<NUMBER>)"` (without the quotes).

Use in reaction names where you want to inform the user how many items it will produce, but don't want this
displayed for the common case of one item.

This is such a common operation in reaction generator templates that I felt it deserved a template of it's own.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@MUL;<X>;<Y>}
	{@DIV;<X>;<Y>}
	{@IDIV;<X>;<Y>}
	{@MOD;<X>;<Y>}
	{@ADD;<X>;<Y>}
	{@SUB;<X>;<Y>}

Simple math operation templates. 

Each of these templates performs `<X> <OP> <Y>`, where `<OP>` is one of the following operators:

* `@MUL`: Multiplication
* `@DIV`: Division
* `@IDIV`: Integer Division
* `@MOD`: Modulus
* `@ADD`: Addition
* `@SUB`: Subtraction

Unlike most templates these do a full parse of their parameters, so you may have nested template calls, allowing you to
chain math operations very easily. These templates are much slower than proper scripts, so only use them for simple tasks.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@STORE_LIST;<MASTERKEY>;<INDEX>;<ITEM>;[<RTN>=false]}

This template provides primitive support for writing into the Rubble script data registry.
If you need to do something more complicated with the registry you will need to use a script.

`<ITEM>` is stored in `<MASTEKEY>`'s `list` data at `<INDEX>`, if `<INDEX>` is not a valid number
then `<ITEM>` is appended to the end of the list.

If `<RTN>` is `true` then the index at which the item was written will be returned.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@READ_LIST;<MASTERKEY>;<INDEX>}

This template provides primitive support for reading from the Rubble script data registry.
If you need to do something more complicated with the registry you will need to use a script.

Returns the string at `<INDEX>` in `<MASTEKEY>`'s `list` data key.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@FOREACH_LIST;<MASTERKEY>;<RAWS>}

This template provides primitive support for reading from the Rubble script data registry.
If you need to do something more complicated with the registry you will need to use a script.

Repeats `<RAWS>` once for each item stored in `<MASTERKEY>`'s `list` data key.

`<RAWS>` is treated like a user template body that has the parameters `key` and `val` defined.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@STORE_TABLE;<MASTERKEY>;<KEY>;<ITEM>}

This template provides primitive support for writing into the Rubble script data registry.
If you need to do something more complicated with the registry you will need to use a script.

`<ITEM>` is stored in `<MASTEKEY>`'s `table` data at `<KEY>`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@READ_TABLE;<MASTERKEY>;<KEY>}

This template provides primitive support for reading from the Rubble script data registry.
If you need to do something more complicated with the registry you will need to use a script.

Returns the string at `<KEY>` in `<MASTEKEY>`'s `table` data key.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@FOREACH_TABLE;<MASTERKEY>;<RAWS>}

This template provides primitive support for reading from the Rubble script data registry.
If you need to do something more complicated with the registry you will need to use a script.

Repeats `<RAWS>` once for each item stored in `<MASTERKEY>`'s `table` data key.

`<RAWS>` is treated like a user template body that has the parameters `key` and `val` defined.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@FOREACH;<ITEMS>;<RAWS>;[<SEPA=|>;[<SEPB>==]]}

Repeats `<RAWS>` once for each pair of items in `<ITEMS>`. `<ITEMS>` must be a specially formated string.

`<SEPA>` and `<SEPB>` **must not** be the same string! If they are, or if `<ITEMS>` is malformed, then
the output may not be what you are expecting!

`<ITEMS>` format example:

	key1=value1|key2=value2|...|keyn=valuen

Each item is stripped of leading and trailing whitespace, if an item is quoted the quotes are stripped and
any escape sequences are expanded (just like template parameters).

`<RAWS>` is treated like a user template body that has the parameters `key` and `val` defined.

Example:

	{@FOREACH;a=1|b=2|c=3;"\"%{key}\" = %{val},\n"}

Output:

	"a" = 1,
	"b" = 2,
	"c" = 3,

If you use `@FOREACH` inside of a user template's body you will need to delay expansion of it's parameters:

	{!TEMPLATE;T;a;
		{@FOREACH;a=1|b=2|c=3;"%a: \"%{}{key}\" = %{}{val},\n"}
	}
	{T;test}

Returns:

	test: "a" = 1,
	test: "b" = 2,
	test: "c" = 3,

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@PARSE_TO;<ID>;<RAWS>}

Parse `<RAWS>` and store the result to the configuration variable `<ID>`.

This is useful because most templates will expand variables in their parameters, but they won't
parse other templates unless the parameter is supposed to be raw text. By using this template you can
circumvent this limitation to do weird and wonderful things.

By convention if you need a temporary variable that will be used once and discarded immediately you should
name it `TEMP`. 

Example:

	{@PARSE_TO;TEMP;{@READ_TABLE;Libs/Base:!SHARED_OBJECT_CATEGORY:INORGANIC;INORGANIC:IRON}
	}{@IF;$TEMP;t;IRON is defined!;IRON is not defined!}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@COPY_FILE_BANK;<ID>;<PATH>;[<INSTANCE_ID>]}

Request that the file bank with the ID `<ID>` be copied to the path `<PATH>`.

`<INSTANCE_ID>` is an optional handle used to refer to this copy instance for the purpose of adding white
or black list entries.

Example:

	{@COPY_FILE_BANK;Example/Bank;df/stonesense}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@WHITE_LIST_BANK_FILE;<INSTANCE_ID>;<FILE>}
	{@BLACK_LIST_BANK_FILE;<INSTANCE_ID>;<FILE>}

Add `<FILE>` to the white or black list for the copy operation with the instance ID `<INSTANCE_ID>`.

Black list entries take precedence over white list entries.

Example:

	{@BLACK_LIST_BANK_FILE;Example/Bank;example/file.txt}
