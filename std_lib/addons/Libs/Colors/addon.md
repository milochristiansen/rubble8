
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!COLOR_DEF;<ID>;<IDX>;<DESCRIPTOR>}

Adds a new color to the color dictionary.

* `<ID>` is the name you want to use for this color entry.
* `<IDX>` is the color number you want to use for this entry. Remember, if you want the "bright"
  version of a color simply add 8 to the color number.
* `<DESCRIPTOR>` is the color descriptor ID as defined in `descriptor_color_standard.txt` or similar.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!SHARED_COLOR_DEF;<ID>;<IDX>;<DESCRIPTOR_RAWS>}

This is an advanced replacement for both `!SHARED_COLOR` and `!COLOR_DEF` intended for use in total
conversion mods that are replacing the default color descriptors.

This template registers a color named `<ID>` with the display color index `<IDX>`. A later call to
`!SHARED_COLOR_DEFS_INSERT` then inserts the result of calling `!SHARED_COLOR` with the ID `<ID>`
and the body `<DESCRIPTOR_RAWS>`.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!SHARED_COLOR_DEFS_INSERT}

This template must be called **after** all calls to `!SHARED_COLOR_DEF` *and* it must be inside a
color descriptor raw file.

Calling this template will insert raws for all the colors defined at the current location. Calling
this template more than once will do nothing, extra calls will simply return a message stating that
the template has already been called.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@COLOR;<FG>;<BG>}
	{@COLOR;<FG>;-}
	{@COLOR;<FG>}

Return a foreground-background-intensity color triplet for the given ID pair *or* a color descriptor
ID for a single color. The second form (where "-" is specified as the BG color ID) will cause the template
to return a foreground-intensity color pair as needed for the `BASIC_COLOR` material tag.

In FBI triplets the intensity value will always be 0, as the foreground intensity is encoded directly
into the foreground color number.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{@COLOR_MATTAGS;<FG>;<BG>}

Returns a `DISPLAY_COLOR` and a `STATE_COLOR:ALL` tag for the given color pair. Use this to define a
material's color with a minimum of fuss.
