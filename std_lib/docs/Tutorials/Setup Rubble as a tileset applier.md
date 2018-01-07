
How to install Rubble for applying tilesets
====================================================================================================

This tutorial will show you how to install Rubble for use in installing
tilesets as a backend for a third-party launcher.

This will mostly be of use to authors of starter packs and the like, normal
users can just install Rubble as normal and skip all this extra setup.

I assume that you have some kind of launcher at `.`, Rubble will be placed
at `./Utilities/Rubble`, DF is at `./DwarfFortress`, and tileset addons are
at `./Data/Tilesets`. If this does not describe your situation adjust the
paths as needed.

Unpack Rubble to `./Utilities/Rubble`, then delete everything except the
`addons` directory and `rubble.exe`. In the `addons` directory delete
everything except the contents of the `Libs/Base` directory.

The first hurdle is where to place `rubble.ini`, this depends on how the
launcher works. `rubble.ini` MUST be in the current working directory.
Obviously the best policy is to launch Rubble so that it's current working
directory is `./Utilities/Rubble` (that is what I will assume here).
If you cannot do that you will need to place `rubble.ini` in whatever will
be the current working directory and modify the paths to suit.

Create a new file named `rubble.ini` in `./Utilities/Rubble`, this file
will contain some command line options so they do not need to be specified
every time Rubble is run.

Using the paths given above this should be your `rubble.ini`:

	[rubble]
	dfdir=./../../DwarfFortress
	addonsdir=./../../Data/Tilesets
	addonsdir=rubble/addons

If you need to place `rubble.ini` anywhere other than where the Rubble
binary is you will probably also need to add:

	rbldir=<path to rubble>

Now install any tileset addons you want to the `./Data/Tilesets` directory.

To install a tileset run (with `./Utilities/Rubble` as the working directory):

	rubble tset -region=raw -addons="<name of tileset>"

A non-zero exit code indicates an error, `./Utilities/Rubble/rubble.log`
and stdout will both have a detailed log of actions taken and the results.

If you want to switch tilesets on a world in progress simply replace `raw`
with the name of the region.
