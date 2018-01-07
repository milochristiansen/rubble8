
Rubble Changelog:
========================================================================================================================

Rubble versions follow a somewhat odd `rewrite.major.minor` format. The "rewrite" number changes only rarely, generally
when I make sweeping structural changes and/or make a major compatibility break. "Major" versions usually contain new
engine features, while "minor" version usually contain only addon (standard library) changes and engine bugfixes.

For purposes of this changelog Rubble is divided into three parts, the engine (the native code that runs everything else),
the standard library (addons and scripts), and "other" (which generally refers to the documentation). The engine is by
far the most important part as far as the version number goes, almost any engine changes will make a version worthy of a
new "major" version. The standard library, while more visible to most users than the engine, is usually only worthy of a
new "minor" version.

Please read this changelog carefully, all kinds of interesting/critical tidbits tend to get stuck in here.


8.5.3 (For DF 44.3) Fixed raw errors.
------------------------------------------------------------------------------------------------------------------------

This version fixes some errors in the raws, mainly I missed a pair of files when updating last time, and several creature
ID changes got lost in the noise.

Engine Changes:

* None.

Addon and Standard Library Changes:

* Fixed a few errors in the `addon:Base` addon, as pointed out by bay12 user "somebears".

Other Changes:

* None.

8.5.2 (For DF 44.3) Minor tweaks and new DF.
------------------------------------------------------------------------------------------------------------------------

This version fixes a possible OSX error, updates the base for the new DF, and updates my tileset for TWBT Next. Nothing
major.

Engine Changes:

* Made some minor tweaks to the Lua script API. These changes are to support minor changes in the latest version of the
  native API exposed by the VM. The only user-visible change is that some script API functions now respect the `__pairs`
  metamethod for table arguments.

Addon and Standard Library Changes:

* Updated `addon:Base` for the new DF.
* Made a few tweaks to `addon:Tilesets/MLC/TWBT - 24px` to support TWBT Next, nothing major.
* Fixed? the OSX launch script. I have no idea if it worked or not, but it looks like I changed the way the install script
  worked at some point without fixing the launch script. I think the launch script would have ended up starting itself over
  and over the way things were...

Other Changes:

* Fixed some minor documentation errors.
* Removed a few links to an non-existent addons from some addons in the `addon:User/Powered` group.


8.5.1 (For DF 43.5) Minor internal cleanup.
------------------------------------------------------------------------------------------------------------------------

I finally released certain of my best libraries publicly as separate products. Since Rubble depends on some of these
libraries it required minor changes to account for changed import paths. While I was at it I cleaned up some other minor
dependency issues.

This version basically consists entirely of internal cleanup and bugfixes.

There is one major change, not with Rubble but with the distribution. Now that there is a 64 bit DFHack to go with the
64 bit DF I will no longer be including 32 bit builds in the standard Rubble distribution. It is still possible (and
will always be possible) to build your own 32 bit binaries, I just won't provide them prebuilt anymore.


Engine Changes:

* Rubble no longer ships with source code for DCLua or AXIS VFS. This code is now on GitHub, see the compile guide
  for more info.
* Eliminated the dependency on `dctech/position`.
* Fixed a bug with the dedicated content server logger. It was not closing old log files and once the log grew to a
  certain size it would create a new file for each new log entry. Good thing the dedicated server was never deployed
  anywhere...
* The addon loader now has a way for native APIs to add file tags again, clearly I wasn't thinking when I removed this... 
* Separated the Lua script runner and API from the universal interface compiler mode. They are now two separate packages.
* The Lua script runner now registers the custom file tag it needs directly.
* Renamed some of the packages containing universal interface actions. Many of these had nonsensical package names that
  had nothing to do with their import paths. This wasn't a big deal, as these packages are always imported anonymously.
* Fixed a few bits of unreachable code and one or two old debugging `panic`s exposed by `go vet`.

Addon and Standard Library Changes:

* Removed file tagger rules for the defunct "CLua" script syntax.
* The extra file tag for the Lua script runner is no longer registered in the standard library.
* At Meph's request I reworked the script at the heart of `addon:Libs/Colors/Swap Palette` into a seasonal palette
  switcher. This wouldn't effect Rubble except that as part of this work I greatly improved the palette file load
  function. These improvements have been back-ported to `addon:Libs/Colors/Swap Palette`.

Other Changes:

* Made some changes to the compile guide (in "other/src"), mostly to document version tags and external dependencies in
  greater detail.
* 32 bit binaries are no longer included in the standard Rubble distribution. This required minor changes to the automated
  install script.
* Fixed a typo in the independent/tileset apply web UI template that prevented it from working. I am 100% sure I tested
  this page before, but not with the web browser I am using now...

8.5.0 (For DF 43.5) UI Improvements!
------------------------------------------------------------------------------------------------------------------------

I recently began experimenting with jQuery, and since I needed a project to use it on to cement my knowledge I turned to
my "default project", Rubble. The result is a shiny new look for the web UI. OK, OK, it's not really all that different
from the old look, but there are some important functionality improvements.

The biggest improvement is that the "apply tileset" and "independent apply" pages now have access to the configuration
variable editor. This is a very nice functionality improvement, particularly when you consider addons such as `addon:Util/Pop Cap`
which work really well with independent apply, but make heavy use of configuration variables.


Engine Changes:

* As part of changes to `dctech/lua` in preparation for public release (as a separate product) I removed the "CLua"
  experimental syntax, so I had to remove this option from Rubble as well.
* AXIS links in the web UI now set the `Content-Type` header from the file extension of the retrieved file.
* Default HTML templates, CSS files, etc are no longer stored in the Rubble binary. It is no longer possible to drop
  Rubble anywhere and have it create the files it needs to run the web UI. In practice this wasn't something you would
  want to do anyway.
* Some special URLs used to serve CSS and such like are now gone, AXIS links are used instead.
* jQuery and jQuery UI are now shipped with Rubble.
* The web UI has been redesigned using jQuery UI.
	* The new "download addon packs" page has not been tested, since there are no content servers available, and I didn't
	  feel like setting one up just to test one page.
	* The syntax for spoilers in documents and addon descriptions is greatly simplified. The old way still works for now,
	  but the new way is much nicer.
	* The "choose addons" page and the configuration variable editor are now unified on a single page. As part of this
	  change the "independent apply" and "apply tileset" pages also have access to the configuration variable editor.

Addon and Standard Library Changes:

* Nope

Other Changes:

* Tweaked the documentation a little here and there to account for UI changes.


8.4.3 (For DF 43.5)
------------------------------------------------------------------------------------------------------------------------

This version fixes some fairly minor bugs, not much else.


Engine Changes:

* Fixed a longstanding issue with the Lua compiler Rubble uses, it is now possible to redeclare local variables and get
  proper behavior.

Addon and Standard Library Changes:

* Fixed reversed caste arguments in the `@CH_CASTES_GENERIC` template from `addon:Libs/Creature Helper`. The male/female
  extras arguments now effect the proper caste instead of being reversed.
* `addon:Libs/Edit Init` no longer deletes the last item in the file it is editing.
* Trying to replace an object with `addon:Libs/Edit Init` no longer deletes the object instead of replacing it.
* Fixed several incorrect tiles in pretty much every tilesheet used by the included tileset addons.

Other Changes:

* Not even one.


8.4.2 (For DF 43.5)
------------------------------------------------------------------------------------------------------------------------

This version is, once again, mostly minor tweaks...

Unless you run OSX or Linux, in which case it greatly enhances and streamlines the install process :) (particularly for
OSX, as the install section for that used to consist mostly of some fancy words saying "I don't know")


Engine Changes:

* Changed the way version tags are applied. This means that I can tag special builds fairly easily.
	* Obviously this does not effect normal Rubble builds at all.
	* Unless you build Rubble in a special way it will automatically get a version tag identifying it as an unofficial
	  build.

Addon and Standard Library Changes:

* Made a small tweak to `addon:Libs/Creature Helper`.

Other Changes:

* Added the beginnings of a [RTL tips and tricks section][RB3] to Rubble Basics.
* Added more details for installing on Linux and OSX to [Rubble Basics][RB4].
* Added a much nicer "universal" browser script. It should work on both Linux and OSX without changes.
* Added a script to automate the process of preparing Rubble to run on Linux or OSX. This should greatly improve the
  installation experience on these operating systems. The script is packed into a TAR archive in the "other" directory,
  so you do not need to set any file permissions, just unpack and run.
* Added some scripts to help launch the OSX version of Rubble. These scripts are the result of work done by jecowa, if
  you use Rubble on OSX remember to thank him/her!


8.4.1 (For DF 43.5) Creature helper templates.
------------------------------------------------------------------------------------------------------------------------

I have recently started porting the old 34.11 Underhive Settlement mod to modern DF versions. As part of this effort I
have been doing far more creature modding than I ever have before. I forgot just how much I hate creature modding...

Anyway, to ease my suffering I wrote a set of templates that greatly reduce the amount of "stuttering" your average group
of creatures has. There are certain sets of tags that almost every creatures has, and other sets that differ only slightly.
A few Rubble templates and suddenly creatures are much less verbose and far easier to manage :)


Engine Changes:

* Not even one!

Addon and Standard Library Changes:

* Added `addon:Libs/Creature Helper`, a powerful set of templates to simplify the most annoying parts of making a creature.
* Changed the status of the internal template `#ADDON_HOOK`, it is now a documented part of the standard library.
	* It's usage has changed slightly, but this should not effect anything since it was not part of the public API.
* Updated `addon:Base` to DF 43.5 (not that there were many changes).
* Stopped Rubble from writing auxiliary text files to the main raw directory (in addition to writing them to where they
  are supposed to go).
* The web UI now properly initializes the active addon information again.

Other Changes:

* Nope.


8.4.0 (For DF 43.4) More file bank flexibility...
------------------------------------------------------------------------------------------------------------------------

This version brings more new abilities for file banks. This time I added support for file white and black lists (so you
can skip some files if you like). You can add more files to the lists after you register a bank copy, so the system is
fairly flexible.

I considered, but decided not to, add templates for interacting with AXIS VFS. There are simply too many ways to shoot
your foot off when dealing with direct file IO, better to leave it up to scripts where errors can be properly handled.

Rubble will no longer complain about an invalid tag in "creature_standard.txt" (Toady *finally* fixed it), so if you see
any warnings after generation they are probably worth worrying about now :)

I also added a minor tweak to the core template parser function that will allow clients to conditionally parse Rubble
template code. Rubble itself does not use this ability, but I do use it in one of my external utilities.

In other news: I have recently remembered that *many* addons from Rubble 6 never made the leap to 7 (or 8), so the next
few versions should start to add more content. Provided, of course, I don't get too busy with other things...


Engine Changes:

* Made a minor tweak to the Rubble template parser. This does not effect Rubble itself in any way, but it is very useful
  for certain external programs that use Rubble as a library :)
* White or black lists may now be added to file bank copy requests.
* You may now copy a single file bank to more than one location (white and black lists are unique to an individual copy
  request).
	* The documentation claimed you could do this already, but it was wrong (oops).
* Added a few new script functions for interacting with file banks.

Addon and Standard Library Changes:

* Added `addon:Util/Fix Gays`: A DFHack script that automatically fixes the gender issues of all creatures in your fort.
* Updated `addon:Base` to DF 43.4.
* Added several new templates for handling file banks.

Other Changes:

* Added missing documentation for `@COPY_FILE_BANK`, as well as adding entries for the new file bank functions and templates.


8.3.0 (For DF 43.3) File bank flexibility!
------------------------------------------------------------------------------------------------------------------------

This version adds a new ability for file banks, namely they are mounted to specific AXIS paths so that it is possible to
read individual files from a bank without lots of non-trivial effort.


Engine Changes:

* File banks are now (re)mounted at "banks/<bank ID>". All data sources mounted in "banks" are read-only.

Addon and Standard Library Changes:

* Updated the `addon:Base` addon to 43.3

Other Changes:

* None


8.2.0 (For DF 43.2) Content server browser!
------------------------------------------------------------------------------------------------------------------------

This version adds a page to the web UI that allows you to view and download addon packs advertised on content servers.
This feature isn't as cool as it sounds, since I still haven't managed to get a content server hosted, and even if I did
there are only a few addon packs that would make use of it.

Now that the normal-user part of the client code and interface is done, I just need to improve the interface for modders
and other advanced users. Coming soon? Maybe...

Engine Changes:

* The web UI now features a "content server browser" that allows you to view and download addon packs from inside Rubble.
* The content server no longer requires a valid login to list addon packs (oops).
* Web UI doc links with a query in the URL (addon file doc links) now work properly.

Addon and Standard Library Changes:

* None

Other Changes:

* None


8.1.1 (For DF 43.2) New DF, and nothing else...
------------------------------------------------------------------------------------------------------------------------

Boring version this time, just some minor changes for the new DF.

Engine Changes:

* None

Addon and Standard Library Changes:

* Updated the `addon:Base` addon to 43.2

Other Changes:

* None


8.1.0 (For DF 42.6) Content Server!
------------------------------------------------------------------------------------------------------------------------

This version provides a fix for the problem that has plagued every attempt at making an auto-update/auto-download system
since the .webload system was new: Lack of a good way to decide if a new version was available. Before now Rubble would
make a HEAD request to any provided URL to try to decide if the server copy matched the local copy of whatever it was
supposed to be updating. This worked (kinda), but had the effect of being counted as a download by sites such as DFFD,
leading to inaccurate (inflated) download counts.

Starting with this version Rubble will attempt to find a "Rubble Content Server" and ask it for detailed information
about the addon pack it is considering. This will allow much more detailed/accurate decisions to be made about what
version to download (if a download is needed). These servers do not keep the files on hand, they simply keep track of
what versions are available and where to get them.

Content servers keep track of each version available for download, where it is located, what DF version it is for, what
Rubble version it requires, a short description of the pack, and a set of tags that apply to it. Eventually some of this
information will power an "addon pack browser" that will allow you to download new addons from inside the web UI.

Currently there are no content servers available. I am looking for someone to host and administrate one, as I am unable
to do so.

Until a content server is available it is possible to specify a DFFD file ID. This does not work nearly as well as a
content server does, but it works *much* better than the old system... I will likely keep this functionality as a fall
back, so if you don't want/need the extra power a content server provides and don't mind dealing with some minor warts,
this system will continue to work into the future.

Engine Changes:

* Added several new interface modes to provide a content server, allow remote administration, remote pack information
  update, etc.
	* Access to the server is magic token based. Only the user who originally uploaded the item (or anyone who has a copy
	  of the uploader's token and user name) is allowed to modify the listing remotely. The server administrator may make
	  any changes they like locally (although such changes may require a server restart).
		* The token takes the form of a small (1024 bytes) binary file named "<user name>.tkn" stored in "rubble/users".
		* You do not need an account to query the server for data, only to update an existing listing or add a new one.
	* There are no interfaces for certain actions as of now. Interface actions are provided for adding or deleting a
	  listing and adding a new user, but you cannot query a server for information on a pack outside of the addon loader
	  and you cannot query a server for a list of all packs at all. This is a simply laziness on my part. The server
	  supports the required actions, but I haven't written client interface code for them.
	* There is a better dedicated content server (with some special features that make it more suitable for unsupervised
	  operation) available, but I don't include binaries for it in the normal distribution for fairly obvious reasons.
	  Anyone interested in hosting a content server should contact me for more information. 
* Removed the `Updates` pack.meta key, it is a poor solution to the auto-update problem, use `DFFDID` or a content server.
* Changed the way the `Dependencies` pack.meta key works, it no longer lists URLs, just the names.
* Added a bunch of new pack.meta keys to support the content server, see [Rubble Basics][RB1] for information.
* The addon loader now uses DF and Rubble version information from pack.meta to enforce version requirements of addon packs.
	* If the addon pack does not say it is compatible with the current versions it will be skipped.
	* If a pack does not provide version information it defaults to being compatible with everything.
* Rubble now comes with a DF version number hardcoded into it. This number may be changed via "./rubble.ini" or the
  command line, but this is unlikely to be required as long as you keep up with Rubble versions.
	* Rubble will attempt to confirm any version number by reading "df/release notes.txt". A detailed message will be
	  written to the log stating the source of the version number used, and how confident Rubble is that it is correct.
* The addon loader will now fall back to querying DFFD for information if an addon pack is not listed on a content server
  and a DFFD file ID is provided.
	* See [Rubble Basics][RB1] for more information.
	* Please note that this is completely untested! (I can't get DFFD at home) It almost certainly works, but if not let
	  me know and I'll try to fix it.
* Added a new Lua function: `rubble.rparse.maketree`, parse raws into a tree based on a set of raw merger rules.
	* There is a native API to do the same thing, but I'm sure nobody but me is interested in that :P
* The way Rubble uses loggers has changed, interfaces may now provide any logger they like, so long as it implements the
  required interface.
	* This is important for the dedicated content server, as it needs an "industrial strength" logger.
* The default logger is now synced for concurrent access and if the log gets too large it will truncate the in-memory buffer.
	* This allows the basic version of the content server to use the default logger (as it needs the log to be thread
	  safe).
	* The log buffer truncation helps prevent excessive scrolling when trying to read the end of the log in long web UI
	  sessions.
* Fixed some file permission problems with created directories in the Linux version (this was an AXIS bug).
* Running template unit tests (`rubble test`) no longer clears the output directory.

Addon and Standard Library Changes:

* Added a new standard Lua function: `rubble.rparse.formattree`, pretty-print a tree returned by `rubble.rparse.maketree`.
* Removed `metaconv.exe` from the default distribution. This program was an internal tool designed to help port addon.meta
  files from the Rubble 6 format to the Rubble 7 format, it should not have been distributed in the first place.
* Fixed a bad AXIS path in the script that clears the output directory that prevented it from clearing the creature graphics.

Other Changes:

* Added the new script functions to the Lua docs.
* Added [a document/tutorial][CNTNTSRVR] detailing how to interact with a content server.


8.0.0 (For DF 42.6) Addon loading rewrite!
------------------------------------------------------------------------------------------------------------------------

This version brings a much needed update to AXIS VFS and a powerful new addon loader to go with it. Rubble 7 was all about
long term maintainability, this version is all about addons, loading them, updating them, and in general making the addon
pack system into the powerful tool it should be.

The new addon loader is much more flexible. Addons are loaded once, and reused over and over as needed, so Rubble should
run faster (no more annoying pauses while the web UI waits for the loader!). Addon packs may now provide a "pack.meta"
file with information about the addon pack, in particular an auto-update URL.

I ran into some file order problems caused by the convention that mod ID elements in file names should be uppercase.
This convention was causing certain files to sort earlier than they should. As I rather like this convention, I fixed
the problem by changing the way Rubble sorts files and addons. Any items sorted by name are now sorted in a case
insensitive manner (basically everything is temporarily converted to lowercase while sorting).

Most of the changes that are not directly related to the new AXIS and loader are the result of suggestions by my loyal
crew of users. More suggestions are always welcome! There is nothing more valuable than vocal users :)

Engine Changes:

* New AXIS VFS!
	* This required *every single file path* to be changed (as AXIS 2 uses a different path syntax from AXIS 1).
	* The new AXIS is much more flexible, and is far easier to extend.
	* The AXIS script API remains functionally unchanged.
* New addon loader!
	* Addons are now loaded once, and stored together with certain other bits of (mostly) immutable data. This makes State
	  creation much faster, eliminating the the annoying pause when going to the main menu in the web UI.
	* .webload files and the `Downloads` addon.meta key are gone. They made implementing certain parts of the new loader
	  far too hard. Replacements based on the "pack.meta" system are provided.
* Addon packs now are allowed a special meta file that covers all addons in the pack. This "pack.meta" file is a JSON
  file, just like addon.meta, but with a different set of supported keys.
	* Addon packs may request automatic updates via a pack.meta key.
		* It is possible to forcibly prevent addon packs from updating by listing them in "addons/update_blacklist.txt".
	* Take the time to read [the documentation on pack.meta][AddonPacks], it (pack.meta) is critical to many new features.
* Changed the way file output is handled:
	* Any addon pack may now add more tag-based "writers" via a pack.meta key.
	* All the hardcoded write actions have been moved to "addons/global.meta".
		* This file is global, and not part of any addon, basically it is a pack.meta file for the standard addons, but
		  with some special handling.
	* File extension compaction/transformation is now more flexible. Nothing uses this flexibility, but it is there if
	  needed.
* The file tagger is now more flexible.
	* There are no hardcoded file tagging rules anymore, the default rules are loaded from "addons/global.meta".
	* Addon packs may also specify their own tagging rules via a pack.meta key, but these rules then only apply to addons
	  that belong to that pack.
* Dropped JavaScript support. It has never been feature complete, and due to limitations in the API of the VM I was
  using it probably never will be.
* Addon information exposed to scripts is now read only (it has to be this way to prevent scripts from clobbering the
  stored addons).
* Activation state is no longer a property of the addon, it is now stored separately.
	* Lua scripts can use `rubble.addonactive` to query addon activation state.
* Other changes all over the place as required by the new loader or the new AXIS or both.
* Added a new first part extension (".speech") and file tag ("SpeechText") to support speech files. Correctly tagged files
  will be written to "df/data/speech" after generation.
* Added a new "file bank" system:
	* Addons tagged "FileBank" will not be loaded, instead they will have their path added to a list of file banks.
		* Child directories of these addons will not be considered by the loader!
		* The name field of the addon.meta file still works (except it sets the bank name instead of the addon name).
	* You can request that a file bank be written to a specific AXIS path, if you do so all files and directories will
	  be recursively copied to the path you specified.
	* Since Rubble does not actually load files from a file bank they will not be available for editing via the normal
	  methods!
	* See [Rubble Basics][RB2] for more information.
* Added new script function: `rubble.copyfilebank`, requests a file bank copy.
* Files and addons now sort in strict alphabetical order (case is ignored). This prevents certain odd sorting issues.
	* For items that have the same name with different case (which is a very bad idea BTW) order is undefined.

Addon and Standard Library Changes:

* Tracked down and fixed every AXIS path I could find, luckily there aren't very many. (I hope I got them all...)
* Shared object templates added by `addon:Dev/SO Insert` now use the class `ADDON_HOOK_PLAYABLE` instead of `NULL` (if
  applicable). Items with rarity are given the rarity `COMMON`.
* `rubble.expandargs` will now convert any nil parameters into empty strings (since this is more likely to be what the
  user wants).
* Added new standard template: `SHARED_OBJECT_DELETE`, makes a good effort to eradicate all mention of a specific shared
  object.
* Added new standard template: `@COPY_FILE_BANK`, requests a file bank copy.
* Added new library addon: `addon:Libs/Edit Init` provides templates for adding new embark profiles or worldgen parameters.

Other Changes:

* Lots. This version broke documentation all over the place (mostly in minor ways, but some major).
* [Rubble Basics][RB] now has a table of contents!


[RB]: /doc/Rubble%20Basics.md
[RB1]: /doc/Rubble%20Basics.md#AddonPacks
[RB2]: /doc/Rubble%20Basics.md#FileBank
[RB3]: /doc/Rubble%20Basics.md#RTLTip
[RB4]: /doc/Rubble%20Basics.md#OSSpecific

[CNTNTSRVR]: /doc/Tutorials/Rubble%20Content%20Servers.md
