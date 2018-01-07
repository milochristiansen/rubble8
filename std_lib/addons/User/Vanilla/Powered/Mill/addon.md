
The powered mill takes any item that has a mill recipe registered and mills it
into whatever products the recipe specifies.

Jugs or bags may be required, depending on the recipe.

When milling plants with the default recipe seeds are produced (if possible,
they will not be created for seedless plants).

Recipe selection is completely automatic, the first one it finds that OKs the input
item being considered is the one used.

Mods may add new mill recipes via a simple but powerful Lua API.

Input items MUST be on an input tile (a special one tile workshop), output is placed
beyond an output tile (which is also required). If multiple output tiles are provided
one is chosen at random each time (so output may be split).

Connecting machines must be built AFTER any mechanical workshop!
