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

package rubble8

import "rubble8/rblutil"
import "rubble8/rblutil/errors"
import "rubble8/rblutil/addon"

import "github.com/milochristiansen/axis2"
import "github.com/milochristiansen/axis2/sources"

// IAModeRun applies one or more save safe addons to the specified region.
// The addon's scripts are run and any DFHack scripts are installed. Raw files
// and the like are not parsed and tileset information is NOT applied!
func IAModeRun(region, dfdir string, addons []string, data *addon.Database, fs *axis2.FileSystem, log rblutil.Logger) (err error) {
	output := dfdir
	if region == "raw" {
		output += "/raw"
	} else {
		output += "/data/save/" + region + "/raw"
	}
	
	rblutil.LogSeparator(log)
	log.Println("Entering Independent Application Mode for Region:", region)
	
	defer errors.TrapError(&err, log)
	
	old := fs.SwapMount("out", sources.NewOSDir(output), true)
	if old == nil {
		errors.RaiseError("Could not remount the \"out\" mount point")
	}
	defer fs.SwapMount("out", old, true)
	
	oops, state := NewState(data, fs, log)
	if oops != nil {
		return oops
	}

	state.VariableData["_RUBBLE_NO_CLEAR_"] = "true"

	err = state.Activate(addons, nil)
	if err != nil {
		return err
	}

	state.Files.Update(state.Addons.List, state.Active)
	state.Files = state.Files.Copy()

	runScript := func(file *addon.File) error {
		state.CurrentFile = file.Name
		state.Log.Println("  " + file.Name)

		_, err := state.Script.RunScriptFile(file)
		if err != nil {
			return err
		}
		return nil
	}

	rblutil.LogSeparator(state.Log)
	state.Log.Println("Running Init Scripts...")
	err = state.GlobalFiles.RunAction(map[string]bool{
		"Skip":       false,
		"InitScript": true,
	}, runScript)
	if err != nil {
		return err
	}

	rblutil.LogSeparator(state.Log)
	state.Log.Println("Running Prescripts...")
	err = state.Files.RunAction(map[string]bool{
		"Skip":      false,
		"PreScript": true,
	}, runScript)
	if err != nil {
		return err
	}

	rblutil.LogSeparator(state.Log)
	state.Log.Println("Running Postscripts...")
	err = state.Files.RunAction(map[string]bool{
		"Skip":       false,
		"PostScript": true,
	}, runScript)
	if err != nil {
		return err
	}

	state.CurrentFile = ""

	// Simulate the important parts of state.Write.
	rblutil.LogSeparator(state.Log)
	state.Log.Println("Writing Files...")
	for _, writer := range state.Addons.Writers {
		if writer.AllowIA {
			state.Log.Println("  Writing "+writer.Desc+"...")
			err =  state.writeFiles(state.Files, writer.Dir, writer.Filter, writer.Comment, writer.ExtHas, writer.ExtGive, writer.AddHeader)
			if err != nil {
				return err
			}
		}
	}

	state.Log.Println("  Writing File Banks...")
	for id, reqs := range state.Banks {
		source, ok := state.Addons.Banks[id]
		if !ok {
			state.Log.Println("    Request(s) to write nonexistent bank: \""+id+"\" Skipping.")
			continue
		}
		for _, req := range reqs {
			state.Log.Println("    \""+id+"\" To: \""+req.To+"\"")
			state.copyBank(source, req.To, "", req.Black, req.White)
		}
	}
	
	state.Log.Println("  Writing Init Files...")
	state.Log.Println("    init.txt")
	err = state.FS.WriteAll("df/data/init/init.txt", state.Init)
	if err != nil {
		return err
	}
	state.Log.Println("    d_init.txt")
	err = state.FS.WriteAll("df/data/init/d_init.txt", state.D_Init)
	if err != nil {
		return err
	}
	return nil
}
