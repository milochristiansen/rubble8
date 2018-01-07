/*
Copyright 2015-2016 by Milo Christiansen

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

// Lua script related interface actions for the Rubble universal interface.
package actions

import "github.com/milochristiansen/lua"

import "rubble8"
import "rubble8/rblutil"
import "rubble8/rblutil/actions"

import "bytes"

func init() {
	// This enables a compile script action for the universal interface.
	actions.RegisterFunc("luac", func(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool {
		inFile, outFile := *options[0].(*string), *options[1].(*string)
		
		log.Println("Compiling Script:", inFile)
		log.Println("  Initializing AXIS VFS...")
		fs := rubble8.InitAXIS(rblDir, dfDir, outDir, addonDirs)
		
		log.Println("  Loading Script File...")
		script, err := fs.ReadAll(inFile)
		if err != nil {
			log.Println(err)
			return false
		}
		
		l := lua.NewState()
		
		log.Println("  Compiling...")
		err = l.LoadText(bytes.NewBuffer(script), inFile, 0)
		if err != nil {
			log.Println(err)
			return false
		}
		
		log.Println("  Writing Binary...")
		script = l.DumpFunction(-1, false)
		
		err = fs.WriteAll(outFile, script)
		if err != nil {
			log.Println(err)
			return false
		}
		
		return true
	}, "Compile a Lua script with the same compiler Rubble uses when generating.\nAll paths are AXIS paths. The AXIS filesystem has the same structure as normal.", []actions.Option{
		{
			Name: "script",
			Help: "The input `file`.",
			Flag: false,
			Multiple: false,
		},
		{
			Name: "out",
			Help: "The output `file`.",
			Flag: false,
			Multiple: false,
		},
	})
}
