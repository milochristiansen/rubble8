
Rubble Lua API Documentation:
========================================================================================================================

Rubble provides an API for using Lua scripts to extend it's functionality. This is the documentation for that API.

The language tag used for Lua scripts is "LangLua", this tag will be auto applied to any file that has ".lua" as a
last part extension.

The Lua VM used by Rubble is compatible with Lua 5.3 with the following differences:

The following standard functions/variables are not available:

* `collectgarbage` (not possible, VM uses the Go collector)
* `dofile` (violates Rubble's security policy)
* `loadfile` (violates Rubble's security policy)
* `xpcall` (VM has no concept of a message handler)
* `package.config` (violates Rubble's security policy)
* `package.cpath` (VM has no support for native modules)
* `package.loadlib` (VM has no support for native modules)
* `package.path` (violates Rubble's security policy)
* `package.searchpath` (violates Rubble's security policy)
* `string.gmatch` (No pattern matching support, yet...)
* `string.gsub` (No pattern matching support, yet...)
* `string.match` (No pattern matching support, yet...)
* `string.pack` (too lazy to implement, ask if you need it)
* `string.packsize` (too lazy to implement, ask if you need it)
* `string.unpack` (too lazy to implement, ask if you need it)

The following standard modules are not available:

* `coroutine` (no coroutine support yet, ask if you need it)
* `utf8` (too lazy to implement it, ask if you need it)
* `io` (violates Rubble's security policy)
* `os` (violates Rubble's security policy)
* `debug` (violates Rubble's security policy, if you really need something from here ask)

In addition to the stuff that is not available at all the following functions are not implemented exactly as the Lua
5.3 specification requires:

* `string.find` does not allow pattern matching yet (the fourth option is effectively always set to `true`).
* Only one searcher is added to `package.searchers`, the one for finding modules in `package.preloaded` (the Rubble
  standard library adds another searcher).
* `next` is not reentrant for a single table, as it needs to store state information about each table it is used to iterate.
  Starting a new iteration for a particular table invalidates the state information for the previous iteration of
  that table. *Never* use this function for iterating a table unless you absolutely *have* to, use the non-standard
  `getiter` function instead. `getiter` works the way `next` should have, namely it uses a single iterator value that
  stores all required iteration state internally (the way the default `next` works is only possible if your hash table
  is implemented a certain way).

The pattern matching functions from the `string` module are not implemented yet.

Coroutine support is not available. I can implement something based on goroutines (Go's builtin concurrency system)
fairly easily, but I will only do so if someone actually needs it and/or if I get really bored...

The following *core language* features are not supported:

* Hexadecimal floating point literals are not supported at this time. This "feature" is not supported for two reasons:
  I hate floating point in general (so trying to write a converter is pure torture), and when have you *ever* used 
  hexadecimal floating point literals? Lua is the only language I have ever used that supports them, so they are not
  exactly popular...
* Weak references of any kind are not supported. This is because I use Go's garbage collector, and it does not support
  weak references.
* I do not currently support finalizers. It would probably be possible to support them, but it would be a lot of work
  for a feature that is of limited use for something like Rubble. If you have a compelling reason why you need finalizers
  I could probably add them...

This VM fully supports binary chunks, so if you want to precompile your script it is possible. To precompile a script
for use with Rubble you can either build a copy of `luac` (the reference Lua compiler), use the Lua compiler mode provided
by the Rubble universal interface, or use any other third party Lua complier provided that it generates code compatible
with the reference compiler.

If you want to use a third-party compiler it will need to produce binaries with the following settings:

* 64 *or* 32 bit pointers (C type `size_t`), 64 bit preferred.
* 32 bit integers (C type `int`).
* 64 bit float numbers.
* 64 bit integer numbers.
* Little Endian byte order.

When building the reference compiler on most systems these settings should be the default.


`rubble` Module
------------------------------------------------------------------------------------------------------------------------

This module contains functions and variables for working with addons and the Rubble engine.

The standard library loads this module into a global variable named `rubble`, but it can also be `require`d if you like.

* * *

	rubble.version

The current Rubble version as a string.

* * *

	rubble.vmajor
	rubble.vminor
	rubble.vpatch

The current Rubble version number broken into it's parts. Each of these values is an integer.

Generally `rubble.version == rubble.vmajor.."."..rubble.vminor.."."..rubble.vpatch`. Some special
Rubble versions may have an extra version tag that is added to the version string. Such versions are
generally pre-releases and/or special test builds

* * *

	rubble.files

An interface to the current active file list. Not valid in load scripts. Index with the file name.

This variable can be iterated over in filename lexical order via `pairs`.

Entries in this are references to the file objects. The file references have the following fields:

* `Name`: The file name.
* `Content`: The file's contents.
* `Source`: Where the file was loaded from as a string AXIS path.
* `Tags`: The file's tags. This may be iterated with `pairs`.

* * *

	rubble.gfiles

An interface to the current global file list. Valid in load scripts but contains only global scripts, otherwise exactly
like `rubble.files`.

* * *

	rubble.addons

A list of all the loaded addons. Index by integer from 1, supports the length operator and `pairs`/`ipairs`.

All of these keys are read only, as Rubble is not capable of handling addon changes after loading.

The returned addon reference has the following fields:

* `Source`: Where this addon was loaded from.
* `Files`: A list of all the files in the addon indexed by file name. The returned references are the same as those
  gotten from `rubble.files`. Supports `pairs`.
* `Meta`: A reference to the addon meta-data.

The meta-data reference has the same keys as an addon.meta file.

* `Tags`: The addon tags, name -> value. Supports `pairs`.
* `Name`: Addon name as a string.
* `Header`: Addon header as a HTML string.
* `Description`: Addon description as a HTML string.
* `DescFile`: If the addon description was loaded from a file this will be the file name.
* `Activates`: A list of addons activated by this one. Index with integers starting from 1. Supports the length operator
  and `pairs`/`ipairs`.
* `Incompatible`: A list of addons incompatible with this one. Index with integers starting from 1. Supports the length
  operator and `pairs`/`ipairs`.
* `Vars`: A list of references to this addon's configuration variables, index by variable name. Supports `pairs`.
* `LoadPriority`: The integer load priority of this addon.
* `Author`: Addon author name(s) as a string.
* `Version`: Addon version string.

A configuration variable reference has the following keys:

* `Name`: The user friendly name of this variable.
* `Values`: A list of all possible values for this variable with the first value being the default. If there is only one
  value here (or no values) then the variable may be set to any string. You may add new values to this list by trying to
  set a key one past the end. Indexable with integers from 1. Supports the length operator and `pairs`.

* * *

	rubble.addonstbl

Contains the same data as `rubble.addons`, except it is indexed by addon name. Supports `pairs`.

* * *

	rubble.addonactive

If you index this value with a addon name it will return true if the addon is active, nil or false otherwise. You cannot
discriminate between inactive addons and nonexistent addons with this.

* * *

	rubble.registry

This value contains a reference to the shared script data registry.

To access a value in the registry first you need to know it's "master key". Conventionally the master key is the name of
the addon where the data is going to be used. If an addon needs more than one master key (a not uncommon occurrence) the
key name will be the addon name followed by a colon (`:`) and the name of the template the data is for, for example
`Libs/Base:@GENERATE_ID`. If a *template* requires more than one key it generally tacks on another colon and some kind
of extra identifier.

You cannot tell if a specific master key exists in the registry via normal methods, the very act of trying to read a
master key will ensure it exists! To check if a master key exists simply use `rubble.registry.exists`, this is a reference
to the same data as `rubble.registry`, except it returns true or false based on whether the given key exists. Obviously
this means that `exists` is not a valid master key :)

Once you have the master key you index `rubble.registry` with it to get the data for the key. The data has two fields
and one method:

* `list`: Contains a reference to a string slice (array) that is indexable with integers (starting from 1), supports the
  length operator, may be iterated with `pairs` or `ipairs`, and may have new keys added by setting the index one past
  the end.
* `table`: Contains a reference to a map (hash table) with string keys and values that is indexable with strings,
  supports the length operator (useful to see if the map is empty) and may be iterated with `pairs`.
* `listappend(self, item)`: A convenience method that adds an item to the end of the data stored at the `list` key.

Both `list` and `table` return nil if you try to access an invalid or empty key, and may only store strings. Trying to
store any other type will trigger a string conversion. This conversion cannot fail, and will trigger any `__tostring`
meta-methods the value may have.

So why would you use this registry when you could just use a table? Simple, the registry is available to every scripting
language Rubble supports in a more-or-less uniform manner. This allows scripts written in different languages to share data.

Examples:
	
	local data = rubble.registry["Example/Addon"]
	data.list[1] -- == nil, as nothing is at the given index
	data.table["example"] = "A String..."
	
	for k, v in pairs(data.table) do
		print(k, v)
	end
	
	data.list[#data.list+1] = "test"
	# Better way:
	data:listappend("test")

* * *

	function rubble.random()

Returns a random number generator.

The returned value has two read only keys, one read/write key, and one method.

Read Only:

* `int`: Returns an unsigned 63 bit integer.
* `float`: Returns a 64 bit floating point number in the range [0.0, 1.0].

Read/Write:

* `seed`: Set with an integer to seed the generator, when queried returns the current 64 bit timestamp (**not** the
  current seed!). You may also use a string as the seed, it will be converted into a 64 bit integer using some
  unspecified hash function (which may not remain the same between Rubble versions).

Method:

* `function intn(self, n)`: Returns a 63 bit integer in the range [0, n].

* * *

	function rubble.print(...)

Prints it's arguments to the Rubble log. No spaces or new lines are added to the output.

* * *

	function rubble.warning(...)

Prints it's arguments to the Rubble log as a warning message. No spaces or new lines are added to the output.

* * *

	function rubble.abort(msg)

Aborts generation with `msg` being given as the reason.

`msg` will be logged with the prefix "Abort:". If called from inside a template the template name will automatically
be applied after the prefix.

* * *

	function rubble.error(msg)

Aborts generation with `msg` being given as the reason.

`msg` will be logged with the prefix "Error:". If called from inside a template the template name will automatically
be applied after the prefix.

* * *

	function rubble.currentfile()

Returns the name of the file currently being processed.

* * *

	function rubble.configvar(name, [value])

If a value is provided set variable `name` to `value`, otherwise return the value of variable `name`.

* * *

	function rubble.parse(raws, [stage])

Parse Rubble code and return the result. Stage should be an integer specifying the parse stage (0 means pre parse, 1 parse,
and 2 post parse). If stage is not specified or set to -1 then the current parse stage is used, obviously this will only
work during parsing.

* * *

	function rubble.execscript(code, [tag])

Run some script code. `tag` is the script language tag, this defaults to "LangLua". This function can be used to run
code in any language Rubble supports, not just Lua.

If there is an error running the code this returns `false, <error message>`, else returns `true, <script result as string>`.

* * *

	function rubble.calltemplate(name, [...])

Call a rubble template and return the result. The parse stage to use is guessed by looking at the template prefix, `@`
templates will use the current parse stage. Returns the parse result as a string.

* * *

	function rubble.expandvars(str, [openchar, [nest, [data]]])

Expand variables in a string. `openchar` defaults to "$", `nest` to false, and `data` to the Rubble configuration variables.

If `nest` is true then variables inside of curly brackets (assumed to be enclosing template calls) are expanded.
`data` can be a table of names to values.

* * *

	function rubble.template(name, code)

Create a new Lua template. `code` should be a string containing Lua code *or* a Lua function. If `code` is a string then
it is compiled and the compiled form is saved as a binary chunk, if `code` is a function it is also saved as a binary
chunk. This means that you cannot use a function that has upvalues (aside from `_ENV`) unless the function can handle
them being set to nil.

* * *

	function rubble.scripttemplate(name, tag, code)

Create a new template using any of the Rubble supported languages. `tag` should be a script language tag.

Unlike `rubble.template` the code is not precompiled and you cannot use a function as the template body.

* * *

	function rubble.usertemplate(name, args, body)

Create a new user template. `args` should be a table of tables, where each child table should have two items, the first
being the argument name and the second it's default value.

Note that arguments are passed raw, they are not unquoted or stripped of whitespace, so this is not exactly equivalent
to `!TEMPLATE`.

* * *

	function rubble.fileaction(filter, action)

Carry out an action for every file in the active file list that matches the filter.

* `filter` should be a table of tag names to bool, Rubble comes with a bunch of predefined filters in the
  `rubble.filters` table.
* `action` should be a function that takes a single argument, a reference to the file.

See `rubble.files` for description of the file reference.

* * *

	function rubble.rawmerge(rules, source, dest)

Merge `source` into `dest` as specified by the merging rules contained in `rules`.

This uses the same underlying system as the tileset applier, there is a section of Rubble Basics that documents the
rule format.

This returns two things:

1. `dest` with the changes from `source` merged in.
2. `source` with all tags that do not match the rules stripped out.

This property allows the function to be used for two things, as a raw merger and as a raw reducer.

* * *

	function rubble.auxfile(name, [contents])

Read or write the given axillary file buffer.

Currently the only valid values for `name` are:

* "init.txt"
* "d_init.txt"

Passing an invalid name will result in nothing happening.

If `contents` is specified then the file buffer is overwritten with `contents`, else the buffer's current contents are
returned.

* * *

	function rubble.copyfilebank(id, path, [reqID])

Requests that the file bank `id` be copied to `path`. Bank existence is not checked until the bank is actually written
during the write stage. If `reqID` is provided it is used as the copy instance ID for adding black and white lists to the
copy request.

* * *

	function rubble.whitelistbankfile(reqID, file)

Adds `file` to the white list for the file bank copy instance `reqID`.

* * *

	function rubble.blacklistbankfile(reqID, file)

Adds `file` to the black list for the file bank copy instance `reqID`.

Black list entries take precedence over white list entries.

* * *

	function rubble.placeholder(name, silent)

The function generates a simple template of the given `name` that either does nothing silently (if `silent` is true) or
returns a message stating that the addon that contains the template is not active.

This function is implemented in Lua as part of the Rubble standard library.

* * *

	function rubble.targs(args, defaults, noexpand)

This function provides standard argument handling for templates. `args` is a table of the arguments passed to the template,
generally gotten like so: `{...}`. `defaults` is a table of the default values that this template will use for missing
arguments, if nil then this function will return `args` as a table instead of as individual items. Set `noexpand` to true
to prevent variables from being expanded in the parameters.

If `noexpand` is a table you can set each entry to `true` or `false` to control variable expansion individually.

Calling this function with `defaults` nil and `noexpand` true effectively does nothing.

Example:

	rubble.template("EXAMPLE", [[
		local a, b, c = rubble.targs({...}, {"", "", ""})
	]])

This function is implemented in Lua as part of the Rubble standard library.

* * *

	function rubble.expandargs(...)

This function, much like `rubble.targs`, provides standard argument handling for templates. Unlike `rubble.targs` this
is intended for use with the new-style template syntax where the template body is a function rather than a string
containing Lua code.

Any nil parameters are returned as empty strings.

Example:

	rubble.template("EXAMPLE", function(a, b, c)
		a, b, c = rubble.expandargs(a, b, c)
	end)

This function is implemented in Lua as part of the Rubble standard library.

* * *

	function rubble.tobool(opt, t, f)

Convert a string to a boolean value of some kind. Set `t` and `f` to specify what should be returned in true and false
cases (`true` and `false` by default).

This function is implemented in Lua as part of the Rubble standard library.

* * *

	function rubble.getarraypacked(array, fitem, len)

Return `len` items from the sequence `array` starting with the item at `fitem`. This is intended for reading items from
"packed arrays", a way to store multiple items in an array by treating the array as a group of fixed length segments.

This is commonly used when storing complex data in the script data registry.

Example:

	-- Store some stuff in the registry
	local data = rubble.registry["EXAMPLE"]
	data.table[item] = #data.list+1
	data:listappend(item)
	data:listappend(a)
	data:listappend(b)
	
	-- Read it back somewhere else
	local _, b, c = rubble.getarraypacked(data.list, data.table[item], 3)

This function is implemented in Lua as part of the Rubble standard library.

* * *

	function rubble.inverttable(tbl)

Returns a copy of the table `tbl` where the keys are the values and the values are the keys.

This function is implemented in Lua as part of the Rubble standard library.

* * *

	function rubble.checkversion(addon, major, minor, patch)

This function ensures that the Rubble version number is equal to or greater than the given version. If the version is
exactly equal and the version string has no extra tags then nothing happens, but if the version requested is newer than
the current version Rubble aborts.

If the current version is newer than requested or the Rubble version string has an extra tag applied (which is common
for beta or test versions) then a message saying so is printed to the log.

`addon` is only used in the printed messages, this function does not check to see if it is a valid addon name.

If you use this function in a load script make sure you make it's execution conditional on the addon being active!

Example:

	rubble.checkversion("Some/Addon", 7, 0, 0)

This function is implemented in Lua as part of the Rubble standard library. Unlike most such functions it works in load
scripts.


`rubble.rparse` Library
------------------------------------------------------------------------------------------------------------------------

This little library is a simple interface to the standard Rubble raw parser.

This is **not** the Rubble template parser! This is a parser for normal (untemplated) raws.

Rubble uses a raw parser for certain auxiliary tasks, and sometimes it is nice to be able to use this parser from scripts.
Keep in mind that that this parser is not particularly fast, it sacrifices efficiency for simplicity and ease of use.

The standard library loads this module into a global variable named `rubble.rparse`, but it can also be `require`d if
you like.

* * *

	function rubble.rparse.parse(raws)

Parse the given string into a table of raw tags.

The returned raw tags are references to data structures with the following keys:

* `ID`: The first element of the raw tag, for example the tag `[FOO:BAR]` would have this set to `FOO`.
* `Params`: A list of all the tag elements after the first. This field is indexable with integers (starting from 1),
  supports the length operator, may be iterated with `pairs` or `ipairs`, and may have new keys added by setting the
  index one past the end. As a special case you can assign this key a Lua table to replace the whole list with the values
  from the table.
* `Comments`: Any non-tag text (including whitespace) that was found between this tag and the next tag.
* `CommentsOnly`: A boolean that specifies if this tag has no valid data aside from the comments field. Every table
  returned by the parser starts with a tag that has this property set to contain the leading whitespace.
* `Line`: The source line on which this tag was defined. Not used for anything, but could be nice for error messages and
  the like.

* * *

	function rubble.rparse.format(tags)

Takes a table of tag references and turns it into a string.

* * *

	function rubble.rparse.newtag()

Returns a new, empty, tag reference. See `rubble.rparse.parse` for a description of these references.

Calling `rubble.rparse.format({rubble.rparse.newtag()})` will return `"[]"`.

* * *

	function rubble.rparse.maketree(raws, rules)

Parses `raws` into a tree based on the raw merger rules given in `rules`.

If you want a shortcut for making rules look at the rules for the raw consistency checker, they will work for
this with only minor modification.

Any tags that do not match the rules are discarded. Make sure your rules cover all the tags you care about!
Rules for complicated raw objects (such as reactions or creatures) can run to hundreds of lines. Have fun!

Don't try to feed the returned tree into `rubble.rparse.format`, it won't like it :) If you want to turn
a tree back into a string you may use `rubble.rparse.formattree`.

Example:

The following call:

	rubble.rparse.maketree("[A][B][C][D]", [[
		A|{
			B|C
			D
		}
	]])

Will return the following table structure (tag references are displayed as strings):

	tree = {
		me = nil,
		parent = nil,
		
		[1] = {
			me = "[A]",
			parent = tree,
			
			[1] = {
				me = "[B]",
				parent = tree[1],
				
				[1] = {
					me = "[C]",
					parent = tree[1][1],
				},
			},
			[2] = {
				me = "[D]",
				parent = tree[1],
			},
		}
	}

* * *

	function rubble.rparse.formattree(tree, depth, i)

Formats a tree returned by `rubble.rparse.maketree` as a string. Output is indented, but proper indentation depends
on having proper rules.

This function has special rules for inserting extra lines around tags with children (and some extra special rules to
prevent it from inserting too many), plus a rule to prevent children of an `OBJECT` tag from being indented. This results
in very nicely formated output.

In most cases `depth` should not be provided (leave it nil). If you are formating an object that needs more indentation
pass it in as depth.

*Never* specify a value for `i`! This parameter is used internally to allow a leaf of the tree to access it's neighbors
for special purposes.

This function is implemented in Lua as part of the Rubble standard library.

* * *

	function rubble.rparse.walk(raws, action)

Parses the given `raws`, calling `action` for each tag. Once finished the result is fed to `rubble.rparse.format` and
returned.

Basically this implements an interface much like the old Rubble 6 script raw parser, but probably slower.

This function is implemented in Lua as part of the Rubble standard library.


`axis` Library
------------------------------------------------------------------------------------------------------------------------

This library contains IO functions that use the AXIS VFS API. The AXIS Virtual File System handles all file IO for Rubble.

The standard library loads this module into a global variable named `axis`, but it can also be `require`d if you like.

* * *

	function axis.read(path)

Read from the AXIS DataSource at the given path.

If the read succeeds it will return `true, string`, where "string" is the files contents.
On error this returns `false, msg`, where "msg" is an error message.

* * *

	function axis.write(path, data)

Write to the AXIS DataSource at the given path.

If the write succeeds it will return `true`.
On error this returns `false, msg`, where "msg" is an error message.

* * *

	function axis.exists(path)

Returns true if an AXIS DataSource exists at the given path.

* * *

	function axis.isdir(path)

Returns true if the AXIS DataSource at the given path is a directory.

* * *

	function axis.del(path, data)

Delete the AXIS DataSource at the given path. In most cases this will delete the backing file.

If the delete succeeds it will return `true`.
On error this returns `false, msg`, where "msg" is an error message.

* * *

	function axis.listdirs(path)

Return a table of all the directories in the AXIS DataSource at the given path.

* * *

	function axis.listfiles(path)

Return a table of all the files in the AXIS DataSource at the given path.


`string` Library
------------------------------------------------------------------------------------------------------------------------

The standard Lua string library is pretty pathetic in my opinion. Many simple operations are not possible without
lots of complicated code and/or regular expressions. Of course this is probably because Lua is written in C, and C
also has a pathetic string library (it doesn't even have an actual string type!).

I added some new string handling functions on top of the default. Some of these are similar to what Lua already has, but
without the regular expression support, others fill critical holes in the default API, and a few are lazy conveniences.

Most of these functions assume strings are UTF-8 (DF uses cp437), be careful.

* * *

	function string.count(str, sub)

Returns the number of non-overlapping occurrences of `sub` in `str`.

* * *

	function string.hasprefix(str, prefix)

Returns true if `str` starts with `prefix`.

* * *

	function string.hassuffix(str, suffix)

Returns true if `str` ends with `suffix`.

* * *

	function string.join(table, [sep])

Joins all the values in `table` with `sep`. If `sep` is not specified then it defaults to ", "

* * *

	function string.replace(str, old, new, [n])

Replaces `n` occurrences of `old` with `new` in `str`.
If `n` < 0 then there is no limit on replacements.

* * *

	function string.split(str, sep, [n])

Split `str` into `n` substrings at ever occurrence of `sep`.

* `n` > 0: at most n substrings; the last substring will be the unsplit remainder
* `n` == 0: the result is an empty table
* `n` < 0: all substrings

* * *

	function string.splitafter(str, sep, [n])

This is exactly like `strings.split`, except `sep` is retained as part of the substrings.

* * *

	function string.title(str)

Convert the first character of every word in `str` to it's title case.

* * *

	function string.trim(str, cut)

Returns `str` with any chars in `cut` removed from it's beginning and end.

* * *

	function string.trimprefix(str, prefix)

Returns `str` with `prefix` removed from it's start. `str` is returned unchanged if it does not start with `prefix`.

* * *

	function string.trimspace(str)

Returns `str` with all whitespace trimmed from it's beginning and end.

* * *

	function string.trimsuffix(str, suffix)

Returns `str` with `suffix` removed from it's end. `str` is returned unchanged if it does not end with `suffix`.

* * *

	function string.unquote(str)

If `str` begins and ends with a quote char (one of `` "'` ``) then it will be unquoted using the rules for the
[Go](golang.org) language. This includes escape sequence expansion.
