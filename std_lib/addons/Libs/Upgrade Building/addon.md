
	{DFHACK_REACTION_UPGRADE_BUILDING;<SOURCE>;<DEST>;<NAME>;<CLASS>}

Change a custom workshop/furnace from one type to another (via a reaction).
	
* `<SOURCE>` and `<DEST>` are the IDs of the workshop to upgrade and what it should be changed to.
* `<NAME>` is the user visible name for the upgrade reaction
* `<CLASS>` is the addon hook to register the reaction with.
	
This template provides a full featured reaction with no products or reagents, if you need either
just add them after the template.

May be used with all the normal templates that are designed to work with REACTION.

Basically this expands to a `REACTION`, `NAME`, and `BUILDING` tag and otherwise acts much like the
`DFHACK_REACTION` template.
	
You should only change workshop -> workshop or furnace -> furnace!

Blocked and work tiles should match up and size should be the same.
