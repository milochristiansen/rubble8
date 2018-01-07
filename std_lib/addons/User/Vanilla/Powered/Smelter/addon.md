
The powered smelter is really simple, ore and fuel goes in, bars come out.

Input items MUST be on an input tile (a special one tile workshop), output is placed
beyond an output tile (which is also required). If multiple output tiles are provided
one is chosen at random each time (so output may be split).

This is fully compatible with the `addon:User/Metallurgy/Smelter` addon. The only "issue" is
that it is impossible to smelt silver from the "poor" quality ores (tetrahedrite and galena).
These ores can only be smelted to their primary metal. This is due to the way that addon only
allows smelting to one kind of metal per ore.

To operate the powered smelter requires adjacent magma or fuel on an input (magma is given priority).

Connecting machines must be built AFTER any mechanical workshop!
