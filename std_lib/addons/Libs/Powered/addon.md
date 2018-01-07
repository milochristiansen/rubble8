
This addon contains support for powered workshop addons, what follows is some general documentation
on how these workshops operate from a users point of view.

By default powered workshops are dangerous! This means that any active workshop that cannot
find an input item will try to grab a nearby creature. Sometimes (rarely) the creature will
survive but most times is is more a question of "how many pieces?" Keep your dwarves out
of any operating factory!

The powered workshops follow more or less the same pattern, they take any input items
from adjacent inputs and place any output items just beyond any outputs. If the workshop
deals with minecarts it generally will work with any adjacent one. Each workshop's addon
description details its needs, look there for specific help.

Input tiles and output tiles are specified with special one tile workshops. If an output
item is placed on an input tile it will be automatically forbidden. This will keep your
dwarves from disrupting the (hopefully) smooth operation of your production lines by
stealing half finished products.

The workshop input and output buildings are constructed from the "machines" menu, not the
"workshops" menu!

Note: If you place an output diagonally off a workshop's corner it will place the item
diagonally as well! This means that it is possible to chain workshops diagonally or even
cross two production lines (by sharing an output).

Shared/crossed output example:

	o: output
	i: input
	a: workshop from line 1
	b: workshop from line 2
	Items flow from top to bottom
	
	 aaa bbb
	 aaa bbb
	 aaa bbb
	    o
	   i i
	 bbb aaa
	 bbb aaa
	 bbb aaa

It is also possible to make a circle with three workshops!
(a gives to c and b, b gives to a and c, c gives to a and b)

	o: output
	i: input
	a: workshop 1
	b: workshop 2
	c: workshop 3
	
	 aaa
	 aaa
	 aaai
	  iobbb
	cccibbb
	ccc bbb
	ccc

These kinds of setups are less useful than a straight line in most cases, but they should
give you some kind of idea of what is possible.

Workshops will use ANY adjacent output or input! This makes things very flexible, but
sometimes this can make things difficult. I suggest that you spread things out as much
as possible to help keep sharing "issues" from occurring.

If a workshop has multiple output tiles it will choose one at random for each item it
produces, so using two or more outputs allows you to split a workshop's output more-or-less
evenly (subject to the whims of RNG of course).

If an input item matches one of the workshop's recipes that recipe is run and the results
are placed at a random output. If the item *does not* match a recipe the workshop will run
the item through it's "mangler". The exact effect that the mangler has depends on the workshop,
generally the workshop will try to use the item anyway, but with a no-quality result or less
results. For cases where that does not make sense something else is done, such as turning the
item into ash for a furnace, or passing the item and doing damage to the workshop components.

Output item quality will be equal to the average quality of all trap components and mechanisms
used to build the workshop or one to two levels lower, with the average being the most common
and one lower the second most common. Masterwork quality is impossible, so if your machine
has all masterwork components it will have a higher chance to produce exceptional items. If
components of the workshop are damaged (as can happen when you feed a workshop invalid items)
the average damage level will be subtracted from the quality. This has no relation to the
quality calculations used for workers, it is designed to produce more consistent results
(as befits a machine). Keep in mind that individual machines can handle quality however they
want, this is just the default.

There are several choices for output style (which tiles you want to be valid for inputs and outputs).

* Rubble: The default, every adjacent tile is a valid location.
* NoDiag: All adjacent tiles except those diagonally off a corner.
* Sides: All tiles along the sides, except those beside a corner, 2x2 or smaller workshops use the
  NoDiag rules.
* Masterwork: Only the tile in the exact center of each side, tending up and left for even sided workshops.

I suggest either the default Rubble setting (maximum flexibility) or NoDiag (slightly less flexible
but less error prone). All the default workshops are currently 1x1 or 3x3, so Masterwork and Sides
are effectively the same.

Here are some diagrams for the different styles:

	a = workshop
	o = valid input or output location
	
	1x1 (same for all styles except Rubble)
	 o
	oao
	 o
	
	Rubble (the default):
	
	1x1
	ooo
	oao
	ooo
	
	3x3
	ooooo
	oaaao
	oaaao
	oaaao
	ooooo
	
	5x5
	ooooooo
	oaaaaao
	oaaaaao
	oaaaaao
	oaaaaao
	oaaaaao
	ooooooo
	
	NoDiag:
	
	3x3
	 ooo
	oaaao
	oaaao
	oaaao
	 ooo
	
	5x5
	 ooooo
	oaaaaao
	oaaaaao
	oaaaaao
	oaaaaao
	oaaaaao
	 ooooo
	
	Sides (falls back to NoDiag for 2x2 or smaller):
	
	2x2
	 oo
	oaao
	oaao
	 oo
	
	2x3
	  o
	 aaa
	 aaa
	  o
	
	3x3
	  o
	 aaa
	oaaao
	 aaa
	  o
	
	5x5
	  ooo
	 aaaaa
	oaaaaao
	oaaaaao
	oaaaaao
	 aaaaa
	  ooo
	
	Masterwork:
	
	2x2
	 o
	oaao
	 aa
	 o
	
	3x3
	  o
	 aaa
	oaaao
	 aaa
	  o
	
	5x5
	   o
	 aaaaa
	 aaaaa
	oaaaaao
	 aaaaa
	 aaaaa
	   o

If a machine seems to not be working look at the DFHack console, if you don't see lots of errors
the problem is most likely a missing or incorrect input item. Read the workshop's addon description
for details about what it expects, you may have forgotten something.

Remember: The machine (axle, gear assembly, etc) connecting a powered workshop to your power grid
**must** be built **after** the powered workshop! If it's not animated it's probably not powered,
if it's not powered it won't work! Generally the first thing to try if a workshop is hooked up but
not powered is to deconstruct the workshop and the axle or gear assembly connected to it, then
reconstruct both of them, making sure the workshop is finished before starting the connecting
component.

* * *

This addon has a robust set of DFHack Lua modules designed to make it easy to make powered workshops.

Almost every task you will ever need to do has some kind of API support, in particular finding and
creating items is given special attention. This API is designed for use with the DFHack
"building-hacks" plugin, but most of the functions will work with any other powered workshop plugin
that may come along. The only part of the API that actually interacts with the workshop plugin is
the "workshops_libs_powered" module, every other part is fully generic.

There is also a set of templates that, when used with a bit of script and DFHack code, allows you to
create and register generic buildings suitable for powered workshops with minimal fuss. Currently
this API only works with Lua scripts, but it is not required to use the main part of the library.

Also included are the standard input and output buildings.
