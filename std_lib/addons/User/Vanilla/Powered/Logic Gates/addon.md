
This addon adds simple boolean logic gates.

The gates added are:

	Name  Operation
	AND   Returns true if all inputs are powered
	OR    Returns true if at least one input is powered
	NOT   Returns true if no inputs are powered
	XOR   Returns true if at least one powered and one unpowered input

A new gate defaults to AND, use the adjustment reactions to change types.

Logic gates only receive input from axles (windmills and waterwheels make
no sense, and gear assemblies are used as outputs).

Output is by setting the state of a variety of buildings:

* building (true state/false state)
* gear assemblies (engaged/disengaged)
* doors (open/closed)
* hatch covers (open/closed)
* wall and floor grates (open/closed)
* vertical and floor bars (open/closed)
* floodgates (open/closed)
* upright spike traps (extended/retracted)
* bridges (extended/retracted)
* levers (on/off)

Levers in particular have lots of potential, place your logic wherever
it fits best and use a lever to hook it into complicated machines!

Connecting machines must be built AFTER any mechanical workshop!
