
Building Rubble from Source:
==============================================

* To build Rubble you need to have Go (golang.org) installed.
* To build the universal interface "web" mode on windows you will need a C compiler, mingw works. If you do not have a
  C compiler you will need to comment out the line importing the "web" action at the top of the universal interface.

Once you have Go installed just:

	go get github.com/milochristiansen/rubble8


Now all you need to do is fire up a command prompt and run:

	go build github.com/milochristiansen/rubble8/interface/universal

* * *

If you want to apply a custom version tag you will need the following song and dance *before building*!

	set "VERSION_TAG=Your Tag Here"
	go generate github.com/milochristiansen/rubble8

The commands may be slightly different on Linux, but I suspect that if you are building on Linux you will already
know how to set an environment variable in you chosen shell :P Note that you will need to have Lua installed for
the generate step to work.

When building Rubble you then use the following command instead of the one given above:

	go build -tags="vertag" github.com/milochristiansen/rubble8/interface/universal

Version tags are mostly cosmetic, the only real function they serve is to differentiate official builds from custom
builds of various types. By default all custom builds will receive the tag "Unofficial Build". Building without a
version tag (like the official builds) is not recommended!
