
The announcements work via specialized variants of the DFHACK_REACTION and DFHACK_REACTION_BIND templates.

The templates added by this addon are always available (even when the addon is not active).

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{DFHACK_REACTION_ANNOUNCE;<ID>;<CLASS>;<TEXT>;[<COLOR>=COLOR_WHITE]}

Write an announcement to the screen and gamelog when the reaction completes, works exactly like
the REACTION base template.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{DFHACK_ANNOUNCE;<TEXT>;[<COLOR>=COLOR_WHITE];[<ID>=nil]}

Write an announcement to the screen and gamelog when the reaction `<ID>` completes, works exactly
like the DFHACK_REACTION_BIND base template.

If `<ID>` is nil then the ID of the last reaction defined by a `REACTION `template is used.
(Specialized variants of `REACTION`, such as `DFHACK_REACTION`, work as well)
