
Creating a tileset addon
====================================================================================================

This tutorial will show you how to write an addon for installing a tileset.

These are two basic kinds of tileset addon: "basic" addons only install raw
and init mappings for a tileset, "full service" addons not only modify the
raws and the init files they also install the tile images as well.

Most of the default tileset addons are of the "basic" type (so the user can
install their own tile image), but most modders will want to create "full
service" addons for their tilesets.

Both types are exactly the same for the most part, "full service" addons just
need a few extra steps.

I will assume you are porting an existing tileset, I will note places where
you need to do something different if this is not the case.

Step 1 - Raw Mappings
----------------------------------------------------------------------------------------------------

The first thing you need is the raw mapping file. This is the file that Rubble
uses to patch your raws with the needed tile numbers/colors. If your tileset
uses a mapping (like ASCII or Phoebus) that is already included with Rubble
skip to step 2 and put `"Activates"="<the name of the mapping addon>"` in your
addon.meta file (see [Rubble Basics][RB1] for information about addon.meta).

To generate this file simply put your tileset's raws into a temportary addon
and generate *just* that addon. In the output directory (`df/raw` by default)
will be a file named `current.tset.rbl`, this is the file you need.

If you are creating a new tileset from scratch simply copy the `.tset.rbl` file
from the ASCII mapping addon and modify that.

[Rubble Basics][RB2] has more information about `.tset.rbl` files.

Anyway, once you have a `.tset.rbl` file copy it to your addon and rename it to
something appropriate (keeping the `.tset.rbl` extension).

Step 2 - Init Mappings
----------------------------------------------------------------------------------------------------

Now for your init file mappings. This is exactly like the raw mapping file,
just with a different set of objects. By convention this is a separate file
from the raw mappings, but you could put both in the same file with no ill
effects.

If you do not need to modify either init file then you can skip this step.

Create a new file and add the following two tags: (The first one is only
useful/required if you are making a "full service" tileset addon.)

	[AUX_FILE:INIT.TXT]
	
	[AUX_FILE:D_INIT.TXT]

After the `D_INIT.TXT` tag put any tags from `df/data/init/d_init.txt` that
your tileset needs to modify. Only tags related to tilesets will have an
effect here, any tileset related tags that are not specified are set to their
default value.

The `INIT.TXT` tag is where you place any tags you need to modify in
`df/data/init/init.txt`, only the font settings can be modified this way
(so no playing with the `PRINT_MODE` for example, at least not without
specifying custom merger rules).

Step 3 - Install Your Tilesheets
----------------------------------------------------------------------------------------------------

Now you install any tilesheets you need.

Installing tilesheets is as simple as changing their extension from `.bmp` or
`.png` to `.tset.bmp` or `.tset.png`, Rubble will then automatically install
them. When Rubble writes a tilesheet out it will strip the `.tset` part from
the extension, so don't include it when setting the font names in your
`AUX_FILE:INIT.TXT` section.

[RB1]: /doc/Rubble%20Basics#AddonMeta
[RB2]: /doc/Rubble%20Basics#TilesetAddon
