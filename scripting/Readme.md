
This directory contain "script runners" for various scripting languages I have tried at one time or another.

Rubble interfaces may use these runners to provide scripting languages to the Rubble engine. Each of these runners
contains everything needed to use the associated language for Rubble scripts.

* * *

A Rubble script runner wraps everything needed to run a script together with the API required to interact with the
internals of the Rubble engine. Before a runner can be considered fully functional it needs to provide (at a *minimum*):

* Read/write access to the AXIS VFS file system of the current Rubble State (`(*rubble8.State).FS`).
* Read/write access to the following fields in the current Rubble State:
	* `(*rubble8.State).Files`
	* `(*rubble8.State).GlobalFiles`
	* `(*rubble8.State).ScrRegistry`
	* `(*rubble8.State).VariableData`
	* `(*rubble8.State).CurrentFile`
	* `(*rubble8.State).Init`
	* `(*rubble8.State).D_Init`
* Read only access to the following fields in the current Rubble State:
	* `(*rubble8.State).Addons`
* Write only access to the following fields in the current Rubble State:
	* `(*rubble8.State).Banks`
* Functions to print to the log.
* Functions to print warnings and raise aborts.
* Access to the various Rubble version constants.
* Functions to define templates, both script templates (in this language and others) and those defined in RTL.

Access to the other Rubble APIs (the raw parser, the match/merge engine, etc) is optional, but recommended.

* * *

Active/Maintained Runners:

* "dctech_lua": Fully functional Lua 5.3 API for the DCLua VM (github.com/milochristiansen/lua).

* * *

Other Runners:

* Several runners were dropped from the code base in the v7 -> v8 transition. Look in the v7 code base for these runners.
