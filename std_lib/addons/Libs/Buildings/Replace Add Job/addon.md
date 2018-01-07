
This addon is for advanced use only! It is not in any way user friendly, but it makes up for this with flexibility.

It is possible to make multi-level menus like those in the vanilla forge, except much more flexible. The main
limitation is that you must do job creation in Lua, which is a pain. Lucky for you this module has a generic
helper function that can serve as an example for writing your own more specialized versions.

Unless you need multi-level menus is is often easier to use `addon:Libs/Change Build List` to replace the
building entirely.

The core of the this module is based on code by the Bay12 forum member "Bogus", without several critical bits from
his code I would still be fumbling around trying to figure out how adding a job works...
