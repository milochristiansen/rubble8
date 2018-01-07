
This addon adds a reaction that replaces the vanilla "Melt Metal Object" job in the smelter. This
custom melt reaction is much more balanced than the vanilla version, as you will never get more metal
from melting than it took to make the item. In most cases melt returns exactly match production
requirements, but it is possible to get a little less from some items.

Items that do not produce a full bar will produce partial bars, tracked in thousandths of a bar. This
means that melting, say, individual coins, will not produce more metal than was used to mint them in
the first place (as a single coin is worth .002 bars). To my knowledge no item will ever produce more
than was needed to create it.

Wafer metals are properly handled, with adamantine items (finally) melting without loss.

Stacks are properly handled, a stack of 5 bolts will melt to the same amount of metal as melting 5
individual bolts.

Basically this is powered by a giant table of every item type in the game and how many bars/wafers it
takes to produce them. Most items with subtypes (armor, weapons, etc) have special entries for each
subtype (but if a subtype lacks special values it will use the default for that type). To add items
to this table see the `addon:Libs/Melt Item` addon.
