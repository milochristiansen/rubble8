/*
Copyright 2013-2016 by Milo Christiansen

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

// Rubble Standard Interface
package main

import "os"
import "fmt"
import "io/ioutil"
import "runtime"

import "rubble8"
import "rubble8/rblutil"

// Most of the actual guts of this interface are over here
import "rubble8/rblutil/actions"

// The basic actions
import _ "rubble8/rblutil/actions/basic"
import _ "rubble8/rblutil/actions/webui"

// Extra actions
import _ "rubble8/rblutil/test/actions"
import _ "rubble8/rblutil/merge/actions"
import _ "rubble8/rblutil/actions/cntntsrvr"
import _ "rubble8/scripting/dctech_lua/actions"

import _ "rubble8/scripting/dctech_lua" // Includes an action in addition to enabling Lua scripting

func main() {
	err, log := rblutil.NewLogger()
	if err != nil {
		fmt.Println("Fatal Error:", err)
		os.Exit(1)
	}

	rblutil.LogHeader(log, rubble8.Version)

	defer func() {
		err := recover()
		if err != nil {
			log.Println("Unrecovered Error:")
			log.Println("  The following error was not properly recovered, please report this ASAP!")
			log.Printf("  %#v\n", err)
			log.Println("Stack Trace:")
			buf := make([]byte, 4096)
			buf = buf[:runtime.Stack(buf, true)]
			log.Printf("%s\n", buf)
			os.Exit(1)
		}
	}()
	
	log.Println("Starting Universal Interface...")
	
	// Load defaults from config if present
	log.Println("  Attempting to Read Config File: ./rubble.ini")
	ini := map[string][]string{}
	file, err := ioutil.ReadFile("./rubble.ini")
	if err == nil {
		log.Println("    Read OK, loading options from file.")
		rblutil.ParseINI(string(file), "\n", func(key, value string) {
			ini[key] = append(ini[key], value)
		})
	} else {
		log.Println("    Read failed (this is most likely ok)\n      Error:", err)
		log.Println("      Using hardcoded defaults.")
	}

	if len(os.Args) == 1 {
		actions.Exec("web", []string{}, log, ini) // Never returns!
	}
	actions.Exec(os.Args[1], os.Args[2:], log, ini) // Never returns!
}
