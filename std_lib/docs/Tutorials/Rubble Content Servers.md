
How to use Rubble Content Servers
========================================================================================================================

Rubble uses special "content servers" to store information about what addon packs are available, and what DF/Rubble
versions they work with.

Every time Rubble starts it queries the content servers for information about each addon pack it wants to load. If any
content server knows about the addon pack in question it returns the information about the newest version of that pack
that will work with the client's DF and Rubble version.

The only time you will ever have to interact with a content server directly is when you are changing or adding a listing
for an addon pack.

Rubble comes with a list of all content servers that where known to me at the moment I packed it for distribution. If you
want to add more servers simply add the server's address to "addons/content_servers.txt"


Interacting With a Content Server
------------------------------------------------------------------------------------------------------------------------

Before you can interact with the server directly you will need a user name. This is easy to get, simply run the following
command:

	rubble srvrclient -addr="<the server address>" -user="<your user name>" -newuser

If you have ever used this user name on a different server Rubble will use the same token file for this server too, if
not it will create a new token file containing random bytes. If you want to use a particular token file make sure it is
correctly named and installed in "rubble/users", as once you create an account on the server the only way you can change
your token file would be for you to contact the server administrator!

Make sure you don't lose your token file! (it's stored in "rubble/users")

* * *

Listing addon packs on a server is easy.

To properly advertise your addon pack on a content server it needs to have a pack.meta file with most of the keys filled
out. In particular you should have everything pertaining to versions (especially the pack version) filled out. You will
then need to upload your pack to someplace that allows direct HTTP downloads (DFFD works great).

URLs for addon packs need to be direct HTTP downloads and they *must* be complete. For example `www.example.com/somefile.zip`
will not work, use `http://www.example.com/somefile.zip`. Currently the only valid protocol is HTTP (HTTPS may also work).

Instead of a URL you may use a DFFD ID. Obviously this only works if your addon pack is hosted on DFFD :P

Once you have your pack uploaded somewhere, it is time to list it on the server:

	rubble srvrclient -addr="<the server address>" -user="<your user name>" -pack="<the addon pack ID>" -url="<your pack's download URL>"

Or, if you have a DFFD ID:

	rubble srvrclient -addr="<the server address>" -user="<your user name>" -pack="<the addon pack ID>" -dffd="<your pack's DFFD ID>"

If the URL or ID you give matches an earlier upload, the earlier version's entry is replaced. If the URL of your new version
does not match the old URL, but the old URL is no longer valid you can either use the `-ver` argument or you can delete
the old entry.

* * *

To delete an entry you no longer want to advertise, all you need to do is issue the following command:

	rubble srvrclient -addr="<the server address>" -user="<your user name>" -delete -pack="<the addon pack ID>" -ver="<the version to delete>"

You will need to delete each advertised version separately, there is no way to delete all entries for a particular pack.


Running Your Own Server
------------------------------------------------------------------------------------------------------------------------

Running your own content server is not something most users will ever want to do, but it is possible, in fact very easy.

Take a fresh copy of Rubble and delete everything except the main Rubble binary, then run the following command:

	rubble cntntsrvr

Congratulations! You now have a content server of your very own! Of course to make it useful you will have to make sure
it can be accessed by other Rubble users, and you will have to add addon pack information to it...

The only customization you can do to a server is changing the address it listens on. By default content servers listen on
`127.0.0.1:2220` (local host, TCP port 2220). This means that unless you explicitly allow it no other computer can talk
to your content server.

This version of the server is mostly for small-scale use or local testing, if you want to run a dedicated content server
there is a special Rubble interface (available on request) for that.
