
The powered screw press takes any item that has a press recipe registered and presses it
into whatever products the recipe specifies.

By default recipes are provided to match the vanilla screw press.

Jugs are required.

Recipe selection is completely automatic, the first one it finds that OKs the input
item being considered is the one used.

Mods may add new press recipes via a simple but powerful Lua API.

Input items MUST be on an input tile (a special one tile workshop), output is placed
beyond an output tile (which is also required). If multiple output tiles are provided
one is chosen at random each time (so output may be split).

Connecting machines must be built AFTER any mechanical workshop!
