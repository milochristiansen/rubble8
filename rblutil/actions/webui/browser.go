// +build !windows

/*
Copyright 2015-2018 by Milo Christiansen

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

package webui

import "github.com/milochristiansen/rubble8/rblutil"

import "os/exec"

//import "path/filepath"

// LaunchBrowser attempts to launch your web browser via an external script or other executable.
// This is the slim and trim version that does not make an attempt to use different scripts for
// different OSes. OSes that need special behavior should have a separate version of this function.
// Using an external script this way is a fallback anyway, if possible the browser should be
// launched directly using the OS APIs (it's not, AFAIK, possible on Linux, so this will always
// remain The Way there unless I find something else that works better).
func LaunchBrowser(log rblutil.Logger, rbldir, addr string) {
	log.Println("Attempting to Start Your Web Browser (wish me luck)...")
	log.Println("  Attempting to run: \"rubble:other/webUI/browser\" \"http://" + addr + "/menu\".")
	cmd := exec.Command(rbldir+"/other/webUI/browser", "http://"+addr+"/menu")
	err := cmd.Start()
	if err != nil {
		log.Println("  Failed to run browser script:\n    Error:", err)
	} else {
		log.Println("  The browser script ran successfully (your web browser should open, if not edit the script).")
	}
}

/*
// Here lies the old generic version of the function, just in case I ever want to use it again.
func LaunchBrowser(log rblutil.Logger, rbldir, addr string) {
	log.Println("Attempting to Start Your Web Browser (wish me luck)...")
	log.Println("  Attempting to Start: \"rubble:other/webUI/browser\" \"http://" + addr + "/menu\"")
	path, err := exec.LookPath(rbldir + "/other/webUI/browser")
	if err != nil {
		log.Println("    Browser Startup Failed:\n      Error:", err)
	} else {
		path, err := filepath.Abs(path)
		if err != nil {
			log.Println("    Browser Startup Failed:\n      Error:", err)
		} else {
			cmd := exec.Command(path, "http://" + addr + "/menu")
			err = cmd.Start()
			if err != nil {
				log.Println("    Browser Startup Failed:\n      Error:", err)
			} else {
				log.Println("  As far as I can tell everything went fine.")
			}
		}
	}
}
*/
