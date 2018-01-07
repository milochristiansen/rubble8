
Basically just a gender aware and pared down version of `modtools/transform-unit` (with specialized 
versions of `DFHACK_REACTION` and `DFHACK_REACTION_BIND` for easy use).

Does not require `addon:Libs/Castes`, but it is designed to work with it.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{DFHACK_REACTION_CASTE_TRANSFORM;<ID>;<CLASS>;<CREATURE>;<CASTE>;[<DELAY>=0]}

Transforms a creature to the specified type when the reaction is run.
	
`<CASTE>` should be the ID passed to the CASTE or !DEFAULT_CASTE template used to create the caste
you want to transform into. DO NOT use a gender prefix! The transformation script adds this
automatically as needed.
	
`<DELAY>` is a time in ticks to wait before transforming, this allows you to sequence several
transformations.

This is a specialized variant of the REACTION template.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{DFHACK_CASTE_TRANSFORM;<CREATURE>;<CASTE>;[<DELAY>=0;[<ID>=nil]]}

Transforms a creature to the specified type when the reaction is run.

`<CASTE>` should be the ID passed to the CASTE or !DEFAULT_CASTE template used to create the caste
you want to transform into. DO NOT use a gender prefix! The transformation script adds this
automatically as needed.

`<DELAY>` is a time in ticks to wait before transforming, this allows you to sequence several
transformations.

If `<ID>` is nil then the ID of the last reaction defined by a REACTION template is used.
(Specialized variants of REACTION, such as DFHACK_REACTION, work as well)
