/*
Copyright 2016 by Milo Christiansen

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

// Import this package to install the test mode.
package actions

import "rubble8"
import "rubble8/rblutil"
import "rubble8/rblutil/actions"
import "rubble8/rblutil/test"
import "rubble8/rblutil/addon"
import "rubble8/rblutil/parse"
import "rubble8/rblutil/errors"

import "bytes"
import "sort"
import "strings"
import "fmt"

func init() {
actions.RegisterFunc("test", func(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool {
	testAddon, testID, verbose := *options[0].(*string), *options[1].(*string), *options[2].(*bool)
	
	fs := rubble8.InitAXIS(rblDir, dfDir, outDir, addonDirs)
	data, err := addon.Load(fs, log)
	if err != nil {
		log.Println(err)
		return false
	}
	
	addons := []string{}
	for _, addon := range data.List { // DO NOT USE data.Meta! This needs to produce a list in load order.
		if addon.Meta.Tags["HasTests"] {
			addons = append(addons, addon.Meta.Name)
		}
	}
	
	testRunCount := 0
	testFailCount := 0
	resultBuffer := new(bytes.Buffer)
	
	rblutil.LogSeparator(log)
	log.Println("Running Specified Tests...")
	log.Println("  This will produce a *lot* of log file spam for every addon containing tests!")
	log.Println("  Results will be summarized at the end.")
	
	for _, name := range addons {
		if testAddon != "" && testAddon != name {
			continue
		}
		
		err, state := rubble8.NewState(data, fs, log)
		if err != nil {
			log.Println(err)
			return false
		}
		
		state.VariableData["_RUBBLE_NO_CLEAR_"] = "true"
		
		runScript := func(file *addon.File) error {
			state.CurrentFile = file.Name
			state.Log.Println("  " + file.Name)
			
			_, err := state.Script.RunScriptFile(file)
			if err != nil {
				return err
			}
			return nil
		}
		
		err = state.ActivateAny([]string{name}, nil)
		if err != nil {
			log.Println(err)
			return false
		}
		
		state.Log.Println("Generating Sorted Active File List...")
		state.Files.Update(state.Addons.List, state.Active)
		state.Files = state.Files.Copy()
		
		rblutil.LogSeparator(state.Log)
		state.Log.Println("Running Init Scripts...")
		err = state.GlobalFiles.RunAction(map[string]bool{
			"Skip":       false,
			"InitScript": true,
		}, runScript)
		if err != nil {
			log.Println(err)
			return false
		}
	
		rblutil.LogSeparator(state.Log)
		state.Log.Println("Running Prescripts...")
		err = state.Files.RunAction(map[string]bool{
			"Skip":      false,
			"PreScript": true,
		}, runScript)
		if err != nil {
			log.Println(err)
			return false
		}
		
		state.Log.Println("Running Test Files...")
		order := []string{}
		for fname := range state.Addons.Table[name].Files {
			order = append(order, fname)
		}
		sort.Strings(order)
		for _, fname := range order {
			file := state.Addons.Table[name].Files[fname]
			
			if file.Tags["Skip"] || !file.Tags["TemplateTest"] {
				continue
			}
			
			state.CurrentFile = file.Name
			state.Log.Println("  " + file.Name)
			
			tests := test.Parse(file.Content, file.Name, 1)
			for _, test := range tests {
				if testID != "" && testID != test.ID {
					continue
				}
				testRunCount++
				
				err := func() (err error) {
					defer errors.TrapError(&err, state.Log)
					
					state.Stage = parse.StgPreParse
					result := parse.Parse([]byte(test.In), file.Name, test.InLine, parse.StgPreParse, state.Dispatcher, nil)
					state.Stage = parse.StgParse
					result = parse.Parse(result, file.Name, test.InLine, parse.StgParse, state.Dispatcher, nil)
					state.Stage = parse.StgPostParse
					result = parse.Parse(result, file.Name, test.InLine, parse.StgPostParse, state.Dispatcher, nil)
					
					final := strings.TrimSpace(string(result))
					
					if final != test.Out {
						testFailCount++
						msg := test.FailMsg(name, final)
						fmt.Fprintln(resultBuffer, msg)
						state.Log.Println(msg)
					} else if verbose {
						msg := test.PassMsg(name, final)
						fmt.Fprintln(resultBuffer, msg)
						state.Log.Println(msg)
					}
					return nil
				}()
				if err != nil {
					testFailCount++
					msg := "    Unnamed Test in Addon: \"" + name + "\" Failed:\n"
					if test.ID != "" {
						msg = "    Test: " + test.ID + " in Addon: \"" + name + "\" Failed:\n"
					}
					msg += "      " + err.Error()
					fmt.Fprintln(resultBuffer, msg)
					state.Log.Println(msg)
				}
			}
		}
	}
	
	rblutil.LogSeparator(log)
	log.Printf("%v Tests Run.\n", testRunCount)
	if testFailCount > 0 {
		log.Printf("  %v Tests Failed.\n", testFailCount)
		log.Println("  Result Summary:")
		log.Print(resultBuffer.String())
	} else {
		log.Println("  All Tests Passed!")
		if verbose {
			log.Println("  Result Summary:")
			log.Print(resultBuffer.String())
		}
	}
	log.Println("Done.")
	return true
}, "Run template unit tests.", []actions.Option{
	{
		Name: "addon",
		Help: "Specify the name of an addon to only run tests contained in that addon.",
		Flag: false,
		Multiple: false,
	},
	{
		Name: "id",
		Help: "Specify a test ID to only run tests with that ID (several tests may\n\thave the same ID).",
		Flag: false,
		Multiple: false,
	},
	{
		Name: "verbose",
		Help: "Print verbose output.",
		Flag: true,
		Multiple: false,
	},
})
}
