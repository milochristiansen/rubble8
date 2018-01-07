
Color palettes are generally seen as a personal choice. Many tilesets come with one, but generally you can use any
palette you like.

Sometimes authors of total conversion mods may want more colors than the standard palette allows. While it is not
possible to have more than 16 colors, it is possible to redefine some of the standard colors to either other colors
entirely or to shades significantly different than the norm.

This addon installs a DFHack script that automatically overrides the default color settings when a world that uses this
addon is loaded, and resets the colors back to the default when the world is unloaded.

To provide a custom color setting simply write your custom color file ("colors.txt") directly to the root of the output
directory and make sure this addon is in your addon's `Activates` list in your addon.meta file. The script will
automatically look for this file when the world is loaded and read the color information from it. When the world is
unloaded the process is reversed by reading the color information from "<df>/data/init/colors.txt".
