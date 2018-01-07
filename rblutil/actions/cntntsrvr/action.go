/*
Copyright 2016-2018 by Milo Christiansen

This software is provided 'as-is', without any express or implied warranty. In
no event will the authors be held liable for any damages arising from the use of
this software.

Permission is granted to anyone to use this software for any purpose, including
commercial applications, and to alter it and redistribute it freely, subject to
the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim
that you wrote the original software. If you use this software in a product, an
acknowledgment in the product documentation would be appreciated but is not
required.

2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution.
*/

// Import to install modes for the content server and it's command line client.
package cntntsrvr

import "github.com/milochristiansen/rubble8"
import "github.com/milochristiansen/rubble8/rblutil"
import "github.com/milochristiansen/rubble8/rblutil/actions"
import "github.com/milochristiansen/rubble8/rblutil/addon"
import "github.com/milochristiansen/rubble8/rblutil/login"
import "github.com/milochristiansen/rubble8/rblutil/dffd"

import "net"
import "strconv"

func init() {
	actions.RegisterFunc("srvrclient", func(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool {
		addr, url, dffdid := *options[0].(*string), *options[1].(*string), *options[2].(*string)
		newuser, user, pack := *options[3].(*bool), *options[4].(*string), *options[5].(*string)
		ver, del := *options[6].(*string), *options[7].(*bool)

		fs := rubble8.InitAXIS(rblDir, dfDir, outDir, addonDirs)

		if user == "" {
			log.Println("You must provide a user name.")
			return false
		}

		err := login.EnsureToken(user, fs)
		if err != nil {
			log.Println(err)
			return false
		}

		tkn := login.GetToken(user, fs)
		if tkn == nil {
			log.Println("Could not load the token file for the given user name.")
			return false
		}

		if newuser {
			rcode, _, err := addon.ContactContentServer(addr, "AddUser", "", "", "", user, tkn)
			if err != nil {
				log.Println("Error communicating with server:", err)
				return false
			}
			if rcode != "OK" {
				log.Println("Response code does not indicate success:", rcode)
				return false
			}
			log.Println("New user successfully created on server!")
			return true
		}

		if pack == "" {
			log.Println("You must provide an addon pack name.")
			return false
		}

		if del {
			rcode, _, err := addon.ContactContentServer(addr, "Delete", pack, ver, "", user, tkn)
			if err != nil {
				log.Println("Error communicating with server:", err)
				return false
			}
			if rcode != "OK" {
				log.Println("Response code does not indicate success:", rcode)
				return false
			}
			log.Println("Listing deleted.")
			return true
		}

		if dffdid != "" {
			id, err := strconv.Atoi(dffdid)
			if err == nil {
				info, err := dffd.Query(int64(id))
				if err == nil {
					url = info.URL()
				}
			}
		}

		if url == "" {
			log.Println("When uploading you must provide a DFFD ID or URL.")
			return false
		}

		rcode, _, err := addon.ContactContentServer(addr, "Upload", pack, ver, url, user, tkn)
		if err != nil {
			log.Println("Error communicating with server:", err)
			return false
		}
		if rcode != "OK" {
			log.Println("Response code does not indicate success:", rcode)
			return false
		}
		log.Println("Addon pack successfully listed on server!")
		return true
	}, "Communicate with a content server.", []actions.Option{
		{
			Name:     "addr",
			Help:     "The address of the server to communicate with.",
			DS:       "127.0.0.1:2220",
			Flag:     false,
			Multiple: false,
		},
		{
			Name:     "url",
			Help:     "The url of the pack you are trying to list.",
			Flag:     false,
			Multiple: false,
		},
		{
			Name:     "dffd",
			Help:     "The DFFD ID of the addon pack.",
			Flag:     false,
			Multiple: false,
		},
		{
			Name:     "newuser",
			Help:     "Create a new user on the server. If the user does not need to exist locally, but\n\tif it does it will be reused.",
			Flag:     true,
			Multiple: false,
		},
		{
			Name:     "user",
			Help:     "Your user name.",
			Flag:     false,
			Multiple: false,
		},
		{
			Name:     "pack",
			Help:     "The addon pack ID you want to operate on.",
			Flag:     false,
			Multiple: false,
		},
		{
			Name:     "ver",
			Help:     "The addon pack version to delete or replace.",
			Flag:     false,
			Multiple: false,
		},
		{
			Name:     "delete",
			Help:     "Delete a listing instead of adding one.",
			Flag:     true,
			Multiple: false,
		},
	})

	actions.RegisterFunc("cntntsrvr", func(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool {
		addr := *options[0].(*string)

		fs := rubble8.InitAXIS(rblDir, dfDir, outDir, addonDirs)

		packs, err := addon.NewPackBase(fs)
		if err != nil {
			log.Println(err)
			return false
		}

		rblutil.LogSeparator(log)
		log.Println("Starting Server...")

		ln, err := net.Listen("tcp", addr)
		if err != nil {
			log.Println(err)
			return false
		}
		defer ln.Close()
		for {
			conn, err := ln.Accept()
			if err != nil {
				log.Println("Error accepting connection: ", err)
				continue
			}
			go packs.ServeConn(log, fs, conn)
		}
	}, "Starts an instance of the testing content server.", []actions.Option{
		{
			Name:     "addr",
			Help:     "The address to listen on (TCP).",
			DS:       "127.0.0.1:2220",
			Flag:     false,
			Multiple: false,
		},
	})
}
