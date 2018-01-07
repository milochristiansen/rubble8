
The geothermal plant produces 1 power for every unit of magma in a 5x5x3 area under the workshop
(for a maximum of 525 power). There does not need to be a hole under the workshop, and the magma can
be in several unconnected pockets, the only thing that matters is how much there is.

Obviously this is best built over the magma sea or a large magma cistern.

The power output updates fairly slowly (to save FPS), so if your geothermal plant is producing the
wrong amount of power wait for a bit and it should correct itself.

If you want (and if you use `addon:Libs/DFHack/Powered/Drill`) you can build the geothermal plant
over a pipe from the drill, in that case the area used for the power calculation starts at the bottom
of the drill string. To do this simply drill down till you reach magma, then deconstruct the drill
(*without* retracting the pipe!) and build the geothermal power plant so it's center is over the
drill string.

Connecting machines must be built AFTER any mechanical workshop!
