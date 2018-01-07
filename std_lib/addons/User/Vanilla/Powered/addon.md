
If you are looking to produce high quality items, look elsewhere. The various production
buildings do a pretty good job, but nothing beats a skilled craftsman at a normal workshop
for quality. In particular it is impossible to make masterwork quality items.

I tested everything at least once, but there may still be bugs, so be careful. That said
many "bugs" turned out to be goofed setups, so make sure your inputs/outputs are correct
before complaining (for example one weird issue turned out to be a misplaced output tile).

The first thing you should do is read the description for the `addon:Libs/Powered`
addon. It has important general documentation for powered workshops.

Some workshops produce more than one type of item, for example the powered glass furnace
makes both glass and empty bags, use a sorter to separate dissimilar outputs (the sorter
may also discriminate based on material!).

An example of a bad sorter setup (that got me):
This was *supposed* to sort bags and send them right (to be loaded into a minecart) while
glass items went straight, but sometimes bags ended up on top of the glass furnace, can
you spot the issue?

	o: output
	i: input
	s: sorter
	►: east facing conveyor belt (other arrows for other directions)
	l: cart loader
	a: glass furnace
	
	 o
	 s
	 isoil
	 o
	aaa
	aaa
	aaa

The problem is that the bag sorter and the glass furnace shared an output, moving the sorters
(and their outputs) fixed the issue:

	o        o       o
	s soi    s       s
	 i   l   i   l   iil
	 o      so►►i   so▲
	aaa     aaa     aaa
	aaa     aaa     aaa
	aaa     aaa     aaa

There are several other ways this kind of situation may be handled, there is often no one
"right" way, do whatever is easiest. The second example here is more compact than the first,
but it uses more parts. The belts in the second example are required to move the input away
from the furnace (else you could end up with burned bags!). The third example is a super-compact
setup (it would be even more compact, but the loader and the sorters cannot share an input).

I suggest you play around with inputs and outputs until you fully understand how they work!
Much of the fun from using the powered workshops comes from puzzling out the most compact and
efficient way to build your desired factory.

The first input in a production chain is a little hard to feed without having your dwarves
insisting on taking the items to a stockpile, use a sorter to feed the items. As a sorter
without an input tile will take any adjacent items, just use a setup like this:

	=: input stockpile
	o: output
	i: input
	s: sorter
	a: workshop
	
	===
	=s=
	=o=
	 i
	aaa
	aaa
	aaa

If you do not want the above system to pile all the items of the correct type in your fortress
on the input tile it would probably be a good idea to set an output limit on the sorter!
Be aware that sorter output limits count ALL items on ALL of the sorter's output tiles!

Sorter output limits are particularly useful with a workshop that uses or produces items that
can rot. By keeping all but one item in stockpiles the chance of all your raw materials
rotting away is much reduced.

Make sure you read and understand the addon description for the sorter! This building plays
a critical role in any advanced factory!

If you like complicated computing setups the logic gates will be just what you need. AND,
OR, NOT, and XOR gates are available, and they output by toggling the state of many types
of buildings (doors, hatches, bridges, and gear assemblies to name a few, even levers!).

Most of the time you will want to regulate your factory with item sensors. Item sensors are
simple workshops that count all adjacent items and compare this count with a user settable limit,
if the item count is above the limit the output state goes from true to false. In order to save
FPS item sensors "tick" relatively slowly, so the item count may go a little over (it ticks about
as fast as most powered workshops, so the chance is low that this will happen). Item sensors output
in exactly the same way as the logic gates, so the possibilities are just about limitless.

Automatic workshop output limiter example:

	o: output
	s: item sensor
	*: gear assembly
	a: workshop
	<-: power input
	
	aaa
	aaa
	aaa*<-
	 os

This setup will automatically shutdown a workshop when the item sensor's limit is reached,
very useful for workshops that are generating some kind of raw material (keeps stuff from
piling up on the next workshop's input).

The cart loader and cart launcher make it possible to make fully automated minecart routes.
Normally you require dwarf power to, at a minimum, load items into the carts, but with the
cart loader it is possible to do this automatically. The cart launcher gives the ability to
start a minecart on it's way without the need for a dwarf to push it or the need for a complex
launcher system, simply set the launch direction and how full the cart needs to be (as a percent)
and it will automatically take care of starting the cart on it's way.

With the cart loader and launcher to help, minecarts can become an important part of any factory.
Often the best way to move items from one sub-line to another is a short point-to-point minecart
route. For example a sawmill can supply several wood furnaces, rather than trying to setup
everything so all fuel users end up near a wood furnace it is often easier to put the sawmill
and wood furnaces nearby and use minecarts to move the fuel to where it is required. If you
really want to get fancy you can use item sensors to make a single minecart line supply whoever
needs fuel at the moment! (Although depending on how large your factory is this could be something
of a mega project)

Many of the powered workshops are made to fill a specific slot in a production line, but
they work just as well by themselves. For example a powered wood furnace is mostly designed
as an intermediate stage between a powered sawmill and a powered kiln, glass forge, or smelter,
but it also works well with that unpowered sawmill that is scrapping all the wooden crap you
stole from the last elven caravan :p

Here are a few example factories (in GIF form):

The first is a cloth production and clothing recycling line.

![Cloth.gif](/addonfile?addon=User/Powered&file=Cloth.gif)

The top three workshops are (from left to right) a spinner, a loom, and a mill. The spinner feeds the
loom and the loom feeds the middle workshop (which is a decorator). The mill is grinding dye plants
and feeds directly into the decorator. The workshop at the bottom is an unraveller (which also feeds
into the decorator). There are some sorters to remove seeds from the outputs of the spinner and mill,
and a sorter and some belts to return bags from the decorator to the mill. This factory was built
with creature mangling turned off, if it was on you would want to drop products through a hole in the
floor or something like that.

Of course you need to use that cloth for something, so here is a clothing production line.

![Clothiers.gif](/addonfile?addon=User/Powered&file=Clothiers.gif)

There are five separate clothiers here, one for each item of clothing being produced (I am producing
shirts, pants, shoes, socks, and caps). The sorter with all the outputs in the center is working as
a distributer, since multiple outputs are used randomly this will more-or-less evenly spread any input
around. That long belt around the perimeter will gather any output and dump it in a single tile for
easy collection. Once again creature mangling was off, so input and output would have been slightly
more complicated if I had needed to worry about machine safety.

These two lines in tandem produce so much clothing that every citizen of the fortress has dozens of
suits of new clothes :)

* * *

This addon includes the mechanical arm trap component used by most of the powered workshops.
