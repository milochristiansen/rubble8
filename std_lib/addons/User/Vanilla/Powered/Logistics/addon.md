
This addon contains four critical logistics workshops. These workshops, when used carefully, allow
automation of item movement to a degree previously impossible.

All of these building appear in the machines list, not the workshops list, on the build screen!

Belts:
----------------------------------------------------------------------------------------------------

When powered this machine moves any items placed on top of it in its output direction (set the
output direction with the provided reactions).

If the output tile has a wall in it (or is otherwise blocked) the item will be placed on the tile
above, provided there is a hole in the ceiling of course. If there is no hole the item will not be
moved.

Belts do not actually require power because it would be basically impossible to connect them all up.

Items placed on a belt are forbidden just like if they were placed on an input. In addition to the
normal "items placed by outputs are forbidden" rule *any* item placed on a belt in *any* way (for
example, dumped by a minecart) is forbidden immediately. This is done to keep dwarves from taking
items before the belt can move them.

Minecart Launcher:
----------------------------------------------------------------------------------------------------

When powered this machine launches any adjacent minecarts that are sufficiently full in any direction
you choose.

If the cart launcher has an output it will launch the cart in the output tile, otherwise it will
launch any adjacent minecart.

To build a cart launcher you must build the basic building, then run a reaction to set the launch
direction and fullness threshold. Until these are set the building is useless.

Minecart Loader:
----------------------------------------------------------------------------------------------------

When powered this machine loads any items on it's inputs into mincarts *or* you can load any
adjacent magma and water.

Input items MUST be on an input tile (a special one tile workshop), items are then loaded
onto any adjacent minecart.

If the cart loader has an output it will load items into the cart in the output tile, otherwise
it will use any adjacent minecart.

To keep your settlers from stealing the items from the input tile either make sure they can't
path to the input or dump the items there with a sorter (which, like all machines, forbids
items that it places on an input).

Items are loaded one stack at a time once every 10 ticks.

A common problem with cart loaders is loading the wrong cart. If your cart loader seems
to not be loading properly make sure it is not putting the items into the wrong minecart!
(use an output tile to restrict loading to a specific cart)

Sorter:
----------------------------------------------------------------------------------------------------

The item sorter is very simple, you choose what kind of item it should sort and
it retrieves any of that item it finds in its inputs and moves them to it's outputs.

Sorters may sort by item type (and optionally subtype) and/or material, plus you may set
a "output item limit". If there are more items on the output tile(s) than the limit no
more items will be sorted until some of the items on the output are removed. This is good
to keep too many items piling up at workshop's inputs (which can starve other workshops).

If you wish you may "invert" the sorter settings, this means that the sorter will take
everything EXCEPT what you selected, very useful!

To sort items simply make several sorters share an input.

Due to the way sorters work you may sort at most eight types of items from a single tile.
Sorting more than eight item types is simply not possible (and eight can be awkward to
impossible in most cases), so design your factories so this is not required.

Did you know that input and output blocks could be placed diagonally? This property
can be VERY useful with sorters.

If you wish you can tell the sorter to take from adjacent tiles instead of limiting it
to inputs, this is useful for linking stockpiles to your productions lines.

If you say no to all options when setting the sorter it will take any item!

Sorters are designed to do simple tasks, like separating glass from empty bags at the
powered glass forge outputs, separating seeds from thread at the spinner, and other
tasks of that "sort".

Another good use is combining several production lines outputs into a single minecart
route and then splitting them at the destination.

This workshop does not actually require power (it would be too hard to connect up most of the time).
