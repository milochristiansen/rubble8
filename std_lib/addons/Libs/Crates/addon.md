
Most of the templates added by this addon are always available (even when the addon is not active).

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!CRATE;<ID>;<NAME>;<VALUE>;<PRODUCT>}

Define a new crate.

`<PRODUCT>` is written directly into the unpack reaction.

This template is always active even when it's addon is not enabled.
If the addon is not active then this template does nothing.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!CRATE_BARS;<ID>;<NAME>;<VALUE>;<PRODUCT>}

Define a new crate containing 10 bar items.

This is needed so that entities will not have access to the materials that are unpacked. Entities
will automatically have access to any inorganic that is produced in bar form in one of their
reactions, this avoids that (via material reaction products).

`<PRODUCT>` is a material token.
	
This template is always active even when it's addon is not enabled.
If the addon is not active then this template does nothing.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!CRATE_CLASS;[<ID>];<CLASS>}

Add a crate to a class.

If `<ID>` is not specified it defaults to the id of the last crate defined.

This template is always active even when it's addon is not enabled.
If the addon is not active then this template does nothing.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@CRATE_PRODUCT;<ID>;[<CHANCE>=100;[<COUNT>=1]]}

Returns a reaction product line for the given crate.

No checking is done to ensure the crate actually exists. This is just a convenience to insulate users
from internal details of the crate item/material implementation.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{CRATE_WORLDGEN_REACTION_PRODUCTS}

This generates a list of product lines for ALL crates, use in world gen reactions.

This template is always active even when it's addon is not enabled.
If the addon is not active then this template does nothing.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{CRATE_WORLDGEN_REACTION_PRODUCTS_CLASSED;<CLASS>}

This generates a list of product lines for all crates in a class, use in world gen reactions.

This template is always active even when it's addon is not enabled.
If the addon is not active then this template does nothing.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{CRATE_UNPACK_REACTIONS;<BUILDING>;<SKILL>;<TECHCLASS>;[<AUTO>=true]}

Generate unpack reactions for all crates.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{CRATE_UNPACK_REACTIONS_CLASSED;<BUILDING>;<SKILL>;<TECHCLASS>;<CRATECLASS>;[<AUTO>=true]}

Same as `CRATE_UNPACK_REACTIONS`, except for only a single crate class.
