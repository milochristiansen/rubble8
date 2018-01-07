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

// Dedicated Content Server
package main

import "os"
import "os/exec"
import "fmt"
import "runtime"

import "net"
import "time"
import "flag"

import "rubble8"
import "rubble8/rblutil/addon"

var addr string
var nomonitor bool

const (
	countRestarts = 5
	loopThreshold = 15 * time.Second
)

func main() {
	flag.StringVar(&addr, "addr", ":2220", "Address the server should listen on.")
	flag.BoolVar(&nomonitor, "nomonitor", false, "Should this instance skip the monitor?")
	
	flag.Parse()
	
	name := ""
	if nomonitor {
		name = "content server"
	} else {
		name = "server monitor"
	}
	err, log := newLogger(name)
	if err != nil {
		fmt.Println("Fatal Error:", err)
		os.Exit(1)
	}
	
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
	
	if nomonitor {
		// Run the server.
		fs := rubble8.InitAXIS(".", ".", ".", []string{"rubble/addons"})
	
		packs, err := addon.NewPackBase(fs)
		if err != nil {
			log.Println(err)
			os.Exit(1)
		}
		
		ln, err := net.Listen("tcp", addr)
		if err != nil {
			log.Println(err)
			os.Exit(1)
		}
		defer ln.Close()
		for {
			conn, err := ln.Accept()
			if err != nil {
				log.Println("  Error accepting connection: ", err)
				continue
			}
			go packs.ServeConn(log, fs, conn)
		}
	}
	
	// Run the monitor.
	var restarts [countRestarts]time.Time
	
	// I really need an interactive console here, but that's impossible without
	// some way to open a new console window for it.
	
	for {
		if t := time.Since(restarts[0]); t < loopThreshold {
			log.Printf("%d restarts in %v.\n", countRestarts, t)
			log.Printf("  This server is DOWN at %v\n", time.Now().UTC().Format("06/01/02 15:04:05"))
			os.Exit(1)
		}
		
		copy(restarts[0:], restarts[1:])
		restarts[len(restarts)-1] = time.Now()

		log.Println("Monitor (re)starting server...")
		cmd := exec.Command(os.Args[0], "-nomonitor=true", fmt.Sprintf("-addr=%v", addr))
		
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		
		err := cmd.Start()
		if err != nil {
			log.Println("Could not restart:", err)
			log.Printf("  This server is DOWN at %v\n", time.Now().UTC().Format("06/01/02 15:04:05"))
			os.Exit(1)
		}
		
		err = cmd.Wait()
		if err == nil {
			log.Println("Monitored server exited intensionally, weird...")
			log.Printf("  This server is DOWN at %v\n", time.Now().UTC().Format("06/01/02 15:04:05"))
			os.Exit(0) // May be impossible?
		} else {
			log.Printf("Server died at %v\n", time.Now().UTC().Format("06/01/02 15:04:05"))
			log.Println("  Reported error:", err)
			log.Println("  Going for restart.")
		}
	}
}
