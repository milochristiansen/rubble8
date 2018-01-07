
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!ADD_WORLDGEN_PARAM;<ID>;<RAWS>}
	{ADD_WORLDGEN_PARAM;<ID>;<RAWS>}
	{#ADD_WORLDGEN_PARAM;<ID>;<RAWS>}

Adds a new worldgen parameter (or replaces an existing one).

`<ID>` should be the contents of the `TITLE` tag, the `TITLE` and `WORLDGEN` tags should not be included.

The result is not written out immediately, instead the body is parsed anew each stage (by returning
a template call for the next stage) before being stored in the registry and written out by a post script.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!ADD_EMBARK_PROFILE;<ID>;<RAWS>}
	{ADD_EMBARK_PROFILE;<ID>;<RAWS>}
	{#ADD_EMBARK_PROFILE;<ID>;<RAWS>}

Adds a new embark profile (or replaces an existing one).

`<ID>` should be the contents of the `TITLE` tag, the `TITLE` and `PROFILE` tags should not be included.

The result is not written out immediately, instead the body is parsed anew each stage (by returning
a template call for the next stage) before being stored in the registry and written out by a post script.
