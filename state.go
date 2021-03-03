/*
Copyright 2013-2018 by Milo Christiansen

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

// Rubble main package, this contains everything that makes Rubble actually work.
package rubble8

import "strings"
import "bytes"
import "strconv"
import "io"

import "github.com/milochristiansen/axis2"
import "github.com/milochristiansen/axis2/sources"

import "github.com/milochristiansen/rubble8/rblutil"
import "github.com/milochristiansen/rubble8/rblutil/merge"
import "github.com/milochristiansen/rubble8/rblutil/parse"
import "github.com/milochristiansen/rubble8/rblutil/rparse"
import "github.com/milochristiansen/rubble8/rblutil/addon"
import "github.com/milochristiansen/rubble8/rblutil/errors"

// Used by the script registry in the state.
type ScrRegData struct {
	List  *[]string // This needs to be a pointer, don't ask.
	Table map[string]string
}

type BankCopyReq struct {
	ID    string // Optional, if set this request has an entry in State.BankTbl
	To    string
	Black map[string]bool
	White map[string]bool
}

// State is the core of Rubble, everything connects to the state at some level.
type State struct {
	Log rblutil.Logger

	// The global AXIS filesystem.
	FS *axis2.FileSystem

	// The current parse stage, only valid while parsing, obviously.
	Stage parse.Stage

	// The files of the active loaded addons.
	Files *addon.FileList

	// Global scripts (load and init scripts).
	GlobalFiles *addon.FileList

	// Active addons
	Active map[string]bool

	// File banks to write.
	Banks   map[string][]*BankCopyReq
	BankTbl map[string]*BankCopyReq

	// All the loaded addons. DO NOT MODIFY!
	Addons *addon.Database

	// Script is the script operation arbitrator.
	Script ScriptCore

	// Shared script data registry.
	ScrRegistry map[string]ScrRegData

	// This is where config variables are stored.
	VariableData map[string]string

	Templates map[string]*Template

	// Is Rubble in "tool mode"? If so "df/" does not exist in the AXIS filesystem.
	Tool bool

	// The file being parsed/executed right now or "".
	CurrentFile string

	// Some files that need special handling
	Init   []byte
	D_Init []byte
}

// NewState creates a new Rubble State with the addon database and AXIS filesystem provided.
func NewState(data *addon.Database, fs *axis2.FileSystem, log rblutil.Logger) (error, *State) {
	// First create the basic state.
	state := new(State)

	state.Log = log
	state.Log.ClearWarnings()

	rblutil.LogSeparator(state.Log)
	state.Log.Println("Creating New State...")

	state.FS = fs

	state.Tool = !fs.Exists("df")

	state.Addons = data
	state.GlobalFiles = data.Globals.Copy()

	state.Active = make(map[string]bool)
	state.Banks = make(map[string][]*BankCopyReq)
	state.BankTbl = make(map[string]*BankCopyReq)

	state.Files = addon.NewFileList()
	state.ScrRegistry = make(map[string]ScrRegData)
	state.VariableData = make(map[string]string)
	state.Templates = make(map[string]*Template)

	// Now setup the global stuff.

	state.Log.Println("  Loading Special Global Files...")

	if !state.Tool {
		state.Log.Println("    Reading DF Init Files...")
		var err error
		state.Init, err = state.FS.ReadAll("df/data/init/init.txt")
		if err != nil {
			return err, nil
		}
		state.D_Init, err = state.FS.ReadAll("df/data/init/d_init.txt")
		if err != nil {
			return err, nil
		}
	}

	state.Log.Println("  Creating Script Runners...")
	state.Script = NewScriptCore(state)

	return nil, state
}

// InitAXIS creates the standard AXIS filesystem used by Rubble.
// This may be used either to load addons and create a State or to do some Rubble-style IO directly.
func InitAXIS(rubbledir, dfdir, output string, addonsdir []string) *axis2.FileSystem {
	return initAXIS(rubbledir, dfdir, output, addonsdir, true)
}

// InitAXIS creates the standard AXIS filesystem used by Rubble, assuming that DF is not installed.
// This may be used either to load addons and create a State or to do some Rubble-style IO directly.
func InitAXISTool(rubbledir, output string, addonsdir []string) *axis2.FileSystem {
	return initAXIS(rubbledir, "", output, addonsdir, false)
}

func initAXIS(rubbledir, dfdir, output string, addonsdir []string, hasDF bool) *axis2.FileSystem {
	// Massage some of the path variables to allow AXIS paths before AXIS is setup.
	dfdir = rblutil.ReplacePrefix(dfdir, "rubble", rubbledir)

	output = rblutil.ReplacePrefix(output, "rubble", rubbledir)
	if hasDF {
		output = rblutil.ReplacePrefix(output, "df", dfdir)
	}

	for i := range addonsdir {
		addonsdir[i] = rblutil.ReplacePrefix(addonsdir[i], "rubble", rubbledir)
		if hasDF {
			addonsdir[i] = rblutil.ReplacePrefix(addonsdir[i], "df", dfdir)
		}
		addonsdir[i] = rblutil.ReplacePrefix(addonsdir[i], "out", output)
	}

	fs := new(axis2.FileSystem)

	if hasDF {
		fs.Mount("df", sources.NewOSDir(dfdir), true)
	}
	fs.Mount("rubble", sources.NewOSDir(rubbledir), true)
	fs.Mount("out", sources.NewOSDir(output), true)

	for i := range addonsdir {
		fs.Mount("addons", sources.NewOSDir(addonsdir[i]), true)
	}

	return fs
}

// Run runs a full Rubble parse cycle.
// See *State.Activate for parameter descriptions.
func (state *State) Run(addons, config []string) (err error) {
	err = state.Activate(addons, config)
	if err != nil {
		return err
	}

	err = state.RunActivated()
	if err != nil {
		return err
	}

	return nil
}

// RunActivated runs a full Rubble parse cycle, minus activating addons.
func (state *State) RunActivated() (err error) {
	rblutil.LogSeparator(state.Log)
	state.Log.Println("Preparing for Generation...")
	state.Log.Println("  Updating the Default Addon List File...")
	err = state.UpdateAddonList("addons/addonlist.ini")
	if err != nil {
		return err
	}

	state.Log.Println("  Generating Sorted Active File List...")
	state.Files.Update(state.Addons.List, state.Active)
	state.Files = state.Files.Copy()

	err = state.Parse()
	if err != nil {
		return err
	}

	err = state.ApplyTileSet()
	if err != nil {
		return err
	}

	err = state.Write()
	if err != nil {
		return err
	}

	err = state.WriteReport()
	if err != nil {
		return err
	}

	return nil
}

// Activate determines which addons should be active, then writes the default addon list file.
// This is where most of the configuration magic happens...
// addons contains addon activation information.
// Each entry must be either:
//	A list of addon names delimited by semicolons (each addon given is activated)
//	The name of an INI file that contains addon names and their activation state, paths must use the AXIS syntax.
// If addons is empty the default addons file is used (addons/addonlist.ini).
// config is exactly the same as addons, just for configuration variables.
func (state *State) Activate(addons, config []string) (err error) {
	return state.activate(addons, config, false)
}

// ActivateAny is the same as Activate, except it also allows direct activation of library addons.
func (state *State) ActivateAny(addons, config []string) (err error) {
	return state.activate(addons, config, true)
}

func (state *State) activate(addons, config []string, libsOK bool) (err error) {
	defer errors.TrapError(&err, state.Log)

	rblutil.LogSeparator(state.Log)
	state.Log.Println("Activating...")

	state.Log.Println("  Clearing Leftover Addon State Information...")
	state.Active = map[string]bool{}

	state.Log.Println("  Loading Config Variables...")
	if config != nil && len(config) != 0 {
		for _, val := range config {
			file, err := state.FS.ReadAll(val)
			if err == nil {
				state.Log.Println("    Loading Config File: " + val)
				rblutil.ParseINI(string(file), "\n", func(key, value string) {
					state.VariableData[key] = value
				})
				continue
			}
			rblutil.ParseINI(val, ";", func(key, value string) {
				state.VariableData[key] = value
			})
		}
	} else {
		state.Log.Println("    No variables specified.")
	}

	state.Log.Println("  Generating Active Addon List...")
	if len(addons) == 0 {
		state.Log.Println("    No addons specified, using default addon list file.")
		addons = []string{"addons/addonlist.ini"}
	}

	addonNames := make([]string, 0, 10)
	for _, val := range addons {
		file, err := state.FS.ReadAll(val)
		if err == nil {
			state.Log.Println("    Loading List File: " + val)
			rblutil.ParseINI(string(file), "\n", func(key, value string) {
				value = strings.ToLower(value)
				if ok, _ := strconv.ParseBool(value); ok {
					addonNames = append(addonNames, key)
				}
			})
		} else {
			addonNames = append(addonNames, strings.Split(val, ";")...)
		}
	}

	state.Log.Println("  Activating Addons from Generated List...")
	for _, name := range addonNames {
		if _, ok := state.Addons.Table[name]; ok {
			state.Active[name] = true
		}
	}

	if !libsOK {
		state.Log.Println("  Pruning Library Addons...")
		for _, addon := range state.Addons.List {
			if addon.Meta.Tags["Library"] {
				delete(state.Active, addon.Meta.Name)
			}
		}
	} else {
		state.Log.Println("  OK to Activate Libraries Directly, Skipping Pruning Step.")
	}

	state.Log.Println("  Activating Required Addons from Meta Data...")
	var activate func(string)
	activate = func(me string) {
		for j := range state.Addons.Table[me].Meta.Activates {
			it := state.Addons.Table[me].Meta.Activates[j]
			if _, ok := state.Addons.Table[it]; !ok {
				errors.RaiseAbort("The \"" + state.Addons.Table[me].Meta.Name + "\" addon requires the \"" + it + "\" addon!\n" +
					"The required addon is not currently installed, please install the required addon and try again.")
			}

			if !state.Addons.Table[it].Meta.Tags["Library"] {
				state.Log.Println("    The \"" + me + "\" Addon is Activating Non-Library Addon: \"" + it + "\"")
			}

			state.Active[it] = true
			activate(it)
		}
	}
	for me, ok := range state.Active {
		if ok {
			activate(me)
		}
	}

	state.Log.Println("  Running Loader Scripts...")
	err = state.GlobalFiles.RunAction(map[string]bool{
		"Skip":       false,
		"DFHack":     false,
		"LoadScript": true,
	}, func(file *addon.File) error {
		state.CurrentFile = file.Name
		state.Log.Println("    " + file.Name)

		_, err := state.Script.RunScriptFile(file)
		if err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return err
	}

	state.Log.Println("  Active Addons:")
	for addon, ok := range state.Active {
		if ok {
			state.Log.Println("    " + addon)
		}
	}

	state.Log.Println("  Checking for Incompatible Addons from Meta Data...")
	for _, addon := range state.Addons.List {
		if state.Active[addon.Meta.Name] {
			for _, incompat := range addon.Meta.Incompatible {
				if state.Active[incompat] {
					errors.RaiseAbort("The \"" + addon.Meta.Name + "\" addon is incompatible with the \"" + incompat + "\" addon!\n" +
						"Please deactivate one of these addons and try again.")
				}
			}
		}
	}

	state.Log.Println("  Setting Unset Config Variables to Their Defaults...")
	state.Log.Println("    Attempting to load rubble/userconfig.ini...")
	file, err := state.FS.ReadAll("rubble/userconfig.ini")
	if err == nil {
		rblutil.ParseINI(string(file), "\n", func(key, value string) {
			if _, ok := state.VariableData[key]; !ok {
				state.Log.Println("      " + key)
				state.VariableData[key] = value
			}
		})
	} else {
		state.Log.Println("      Could not load rubble/userconfig.ini:", err)
		state.Log.Println("      (This is probably OK.)")
	}
	state.Log.Println("    Setting Remaining Variables from Meta-Data...")
	for _, addon := range state.Addons.List {
		if state.Active[addon.Meta.Name] {
			for name, vdat := range addon.Meta.Vars {
				if _, ok := state.VariableData[name]; !ok && len(vdat.Values) > 0 {
					state.Log.Println("      " + name)
					state.VariableData[name] = vdat.Values[0]
				}
			}
		}
	}
	state.Log.Println("    (Any variables not listed above were explicitly set elsewhere.)")

	return nil
}

// VarDefaults loads all information related to configuration variables and determines the default values for
// every variable listed in any addon's meta data, userconfig.ini, or on the command line.
//
// This is intended for use by interfaces providing variable editors.
func (state *State) VarDefaults(config []string) map[string]string {
	rtn := map[string]string{}

	state.Log.Println("Finding Config Variable Defaults...")
	state.Log.Println("  Processing command line...")
	if config != nil && len(config) != 0 {
		for _, val := range config {
			file, err := state.FS.ReadAll(val)
			if err == nil {
				state.Log.Println("    Loading Config File: " + val)
				rblutil.ParseINI(string(file), "\n", func(key, value string) {
					rtn[key] = value
				})
				continue
			}
			rblutil.ParseINI(val, ";", func(key, value string) {
				rtn[key] = value
			})
		}
	} else {
		state.Log.Println("    No variables specified on command line.")
	}

	state.Log.Println("    Attempting to load rubble/userconfig.ini...")
	file, err := state.FS.ReadAll("rubble/userconfig.ini")
	if err == nil {
		rblutil.ParseINI(string(file), "\n", func(key, value string) {
			state.Log.Println("      " + key)
			rtn[key] = value
		})
	} else {
		state.Log.Println("      Could not load rubble/userconfig.ini:", err)
		state.Log.Println("      (This is probably OK.)")
	}

	state.Log.Println("    Loading remaining defaults from meta-data...")
	for _, addon := range state.Addons.List {
		for name, vdat := range addon.Meta.Vars {
			if _, ok := rtn[name]; !ok && len(vdat.Values) > 0 {
				state.Log.Println("      " + name)
				rtn[name] = vdat.Values[0]
			}
		}
	}

	return rtn
}

// Parse handles everything from running init scripts to running post scripts.
// If an error is returned state.CurrentFile will still be set to its last value.
func (state *State) Parse() (err error) {
	defer errors.TrapError(&err, state.Log)

	runScript := func(file *addon.File) error {
		state.CurrentFile = file.Name
		state.Log.Println("  " + file.Name)

		_, err := state.Script.RunScriptFile(file)
		if err != nil {
			return err
		}
		return nil
	}

	rawFile := map[string]bool{"Skip": false, "AUXText": false, "TileSet": false, "RawFile": true}
	parseRaw := func(stage parse.Stage) func(file *addon.File) error {
		state.Stage = stage
		return func(file *addon.File) error {
			state.CurrentFile = file.Name
			state.Log.Println("  " + file.Name)

			file.Content = parse.Parse(file.Content, file.Name, 1, stage, state.Dispatcher, nil)
			return nil
		}
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
	state.Log.Println("Preparsing...")
	state.Files.RunAction(rawFile, parseRaw(parse.StgPreParse))

	rblutil.LogSeparator(state.Log)
	state.Log.Println("Parsing...")
	state.Files.RunAction(rawFile, parseRaw(parse.StgParse))

	rblutil.LogSeparator(state.Log)
	state.Log.Println("Postparsing...")
	state.Files.RunAction(rawFile, parseRaw(parse.StgPostParse))

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
	return nil
}

// ApplyTileSet does exactly what it's name suggests.
// Tileset information is loaded from all active addons that have it and is
// applied to all normal raw files.
func (state *State) ApplyTileSet() error {
	rblutil.LogSeparator(state.Log)
	state.Log.Println("Applying Tileset...")

	state.Log.Println("  Loading Rules Files...")
	rules := new(merge.RuleNode)
	err := state.Files.RunAction(map[string]bool{
		"Skip":       false,
		"TileSet":    true,
		"MergeRules": true,
	}, func(file *addon.File) error {
		state.Log.Println("    " + file.Name)
		return merge.ParseRules(file.Content, rules)
	})
	if err != nil {
		return err
	}

	state.Log.Println("  Loading Tileset Files...")
	set := new(merge.TagNode)
	state.Files.RunAction(map[string]bool{
		"Skip":    false,
		"RawFile": true,
		"TileSet": true,
	}, func(file *addon.File) error {
		state.Log.Println("    " + file.Name)

		merge.PopulateTree(rparse.ParseRaws(file.Content), set, rules)
		return nil
	})

	state.Log.Println("  Applying Tileset Information...")
	state.Files.RunAction(map[string]bool{
		"Skip":             false,
		"NoWrite":          false,
		"AUXText":          false,
		"CreatureGraphics": false,
		"TileSet":          false,
		"RawFile":          true,
	}, func(file *addon.File) error {
		state.Log.Println("    " + file.Name)

		tags := rparse.ParseRaws(file.Content)
		merge.Apply(tags, set)
		file.Content = rparse.FormatFile(tags)
		return nil
	})

	state.Log.Println("  Applying init Patches...")

	tags := rparse.ParseRaws(state.Init)
	// tags[0] is always a dummy tag used to preserve leading comments, so let's
	// use it for something useful.
	tags[0].ID = "AUX_FILE"
	tags[0].Params = []string{"INIT.TXT"}
	tags[0].CommentsOnly = false // Clear the comments flag so the merger can see the tag.
	merge.Apply(tags, set)
	tags[0].CommentsOnly = true // Then set the flag again so the formatter does not include it.
	state.Init = rparse.FormatFile(tags)

	tags = rparse.ParseRaws(state.D_Init)
	tags[0].ID = "AUX_FILE"
	tags[0].Params = []string{"D_INIT.TXT"}
	tags[0].CommentsOnly = false
	merge.Apply(tags, set)
	tags[0].CommentsOnly = true
	state.D_Init = rparse.FormatFile(tags)

	state.Log.Println("  Running Tileset Scripts...")
	err = state.Files.RunAction(map[string]bool{
		"Skip":    false,
		"TileSet": true,
	}, func(file *addon.File) error {
		if !state.Script.IsScriptFile(file) {
			return nil
		}

		state.CurrentFile = file.Name
		state.Log.Println("    " + file.Name)

		_, err := state.Script.RunScriptFile(file)
		if err != nil {
			return err
		}
		return nil
	})
	state.CurrentFile = ""
	if err != nil {
		return err
	}
	return nil
}

// Write handles writing the files to their output directories.
func (state *State) Write() error {
	rblutil.LogSeparator(state.Log)

	state.Log.Println("Checking Raw Files for Consistency...")
	state.Log.Println("  Loading Consistency Checker Rules...")
	rules := new(merge.RuleNode)
	err := state.Files.RunAction(map[string]bool{
		"Skip":       false,
		"TileSet":    false,
		"MergeRules": true,
	}, func(file *addon.File) error {
		state.Log.Println("  " + file.Name)
		return merge.ParseRules(file.Content, rules)
	})
	if err != nil {
		return err
	}
	state.Log.Println("  Running Raw Consistency Checker...")
	pw := state.Log.WarnCount()
	err = state.Files.RunAction(map[string]bool{
		"Skip":       false,
		"NoWrite":    false,
		"AUXText":    false,
		"SpeechText": false,
		"TileSet":    false,
		"RawFile":    true,
	}, func(file *addon.File) error {
		a := bytes.Count(file.Content, []byte("["))
		b := bytes.Count(file.Content, []byte("]"))
		if a != b {
			state.Log.WarnOnlyln("    Consistency warnings for: " + file.Name)
			state.Log.WarnOnlyExtraf("      Opening brace count does not match closing brace count (%v/%v).\n", a, b)
			state.Log.WarnOnlyExtraln("        This may indicate bad output, disabled raw tags, or simply literal braces in text.")
			state.Log.WarnOnlyExtraln("        Problem lines:")

			// Redo the test line by line to get a list of problem lines
			// TODO: At some point I should write a custom function to do all the tests at once.
			for i, line := range bytes.Split(file.Content, []byte("\n")) {
				a := bytes.Count(line, []byte("["))
				b := bytes.Count(line, []byte("]"))
				if a != b {
					state.Log.WarnOnlyExtraf("          %v: (%v/%v)\n", i+1, a, b)
				}
			}
		}

		errs := merge.Match(rparse.ParseRaws(file.Content), rules)
		if len(errs) != 0 {
			if a == b {
				state.Log.WarnOnlyln("    Consistency warnings for: " + file.Name)
			}
			state.Log.WarnOnlyExtraln("      Rule match failures:")
			for _, err := range errs {
				state.Log.WarnOnlyExtraln("        " + err)
			}
		}
		return nil
	})
	if err != nil {
		return err
	}
	if pw != state.Log.WarnCount() {
		state.Log.Printf("  %v Consistency issues found, check the warnings section for details.\n", state.Log.WarnCount()-pw)
	} else {
		state.Log.Println("  No consistency issues found. Yay!")
	}

	state.Log.Println("Writing Files...")
	for _, writer := range state.Addons.Writers {
		state.Log.Println("  Writing " + writer.Desc + "...")
		err = state.writeFiles(state.Files, writer.Dir, writer.Filter, writer.Comment, writer.ExtHas, writer.ExtGive, writer.AddHeader)
		if err != nil {
			return err
		}
	}

	state.Log.Println("  Writing File Banks...")
	for id, reqs := range state.Banks {
		source, ok := state.Addons.Banks[id]
		if !ok {
			state.Log.Println("    Request(s) to write nonexistent bank: \"" + id + "\" Skipping.")
			continue
		}
		for _, req := range reqs {
			state.Log.Println("    \"" + id + "\" To: \"" + req.To + "\"")
			state.copyBank(source, req.To, "", req.Black, req.White)
		}
	}

	if !state.Tool {
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
	}

	state.Log.Println("    overrides.txt")
	state.Log.Println("      Assembling TWBT Overrides File...")
	overrides := []byte("\n# Automatically generated, do not edit!\n")
	twbt_count := 0
	state.Files.RunAction(map[string]bool{
		"Skip":         false,
		"NoWrite":      false,
		"TileSet":      true,
		"TWBTOverride": true,
	}, func(file *addon.File) error {
		state.Log.Println("        " + file.Name)
		twbt_count++

		overrides = append(overrides, ("\n# Source: " +
			file.Source + "/" + file.Name + "\n" + string(file.Content))...)
		return nil
	})
	if twbt_count > 0 {
		state.Log.Println("      Writing File.")
		if !state.Tool {
			err = state.FS.WriteAll("df/data/init/overrides.txt", overrides)
			if err != nil {
				return err
			}
		} else {
			err = state.FS.WriteAll("out/twbt-overrides.txt", overrides)
			if err != nil {
				return err
			}
		}
	} else {
		state.Log.Println("      No Overrides Found.")
	}

	return nil
}

// WriteReport adds a "generation report" to the output directory.
// This report includes information about the configuration variables,
// active addons, and tileset.
func (state *State) WriteReport() error {
	rblutil.LogSeparator(state.Log)
	state.Log.Println("Writing Generation Report...")

	state.Log.Println("  Writing Addon List...")
	state.Log.Println("    addonlist.ini")
	err := state.UpdateAddonList("out/addonlist.ini")
	if err != nil {
		return err
	}

	state.Log.Println("  Writing Config Variables...")
	state.Log.Println("    genconfig.ini")
	err = state.DumpConfig("out/genconfig.ini")
	if err != nil {
		return err
	}

	state.Log.Println("  Writing Tileset Config File...")
	state.Log.Println("    current.tset.rbl")
	err = state.DumpTSet("out/current.tset.rbl")
	if err != nil {
		return err
	}

	state.Log.Printf("  %v Warnings Encountered While Generating", state.Log.WarnCount())
	if state.Log.WarnCount() > 0 {
		state.Log.Println(":")
	} else {
		state.Log.Println(".")
	}
	_, err = state.Log.Write(state.Log.WarnBuffer())
	if err != nil {
		return err
	}

	return nil
}

// Recursively copy the directory source to the directory dest
func (state *State) copyBank(source, dest, path string, b, w map[string]bool) {
	for _, file := range state.FS.ListFiles(source) {
		if file == "addon.meta" || (b != nil && b[path+"/"+file]) || (w != nil && !w[path+"/"+file]) {
			continue
		}

		rdr, err := state.FS.Read(source + "/" + file)
		if err != nil {
			state.Log.Println("    Error reading bank file:", err.Error(), "Skipping.")
		}
		wrt, err := state.FS.Write(dest + "/" + file)
		if err != nil {
			rdr.Close()
			state.Log.Println("    Error opening destination:", err.Error(), "Skipping.")
		}

		_, err = io.Copy(wrt, rdr)
		rdr.Close()
		wrt.Close()
		if err != nil {
			rdr.Close()
			state.Log.Println("    Error copying file:", err.Error())
		}
	}

	if path != "" {
		path += "/"
	}
	for _, dir := range state.FS.ListDirs(source) {
		state.copyBank(source+"/"+dir, dest+"/"+dir, path+dir, b, w)
	}
}

func (state *State) writeFiles(list *addon.FileList, dir string, filter map[string]bool, comment, exthas, extgive string, addHeader bool) error {
	return list.RunAction(filter, func(file *addon.File) error {
		state.Log.Println("    " + file.Name)

		name := file.Name
		if exthas != "" {
			name = rblutil.ReplaceExtAdv(name, exthas, extgive)
		}

		content := file.Content
		if comment != "" {
			content = []byte("\n" + comment + " Automatically generated, do not edit!\n" + comment + " Source: " +
				file.Source + "/" + file.Name + "\n" + string(file.Content))
		}
		if addHeader {
			// exthas is only set if the file has a two-part extension.
			if exthas != "" {
				content = append([]byte(rblutil.StripExt(rblutil.StripExt(file.Name))+"\n"), content...)
			} else {
				content = append([]byte(rblutil.StripExt(file.Name)+"\n"), content...)
			}
		}

		return state.FS.WriteAll(dir+"/"+name, content)
	})
}

// Data Dumpers

// DumpConfig writes all configuration variables (in INI format) to the indicated file.
func (state *State) DumpConfig(path string) error {
	out := "\n# Rubble config variable dump.\n# Automatically generated, do not edit!\n\n[config]\n"

	for i := range state.VariableData {
		out += i + " = " + strconv.Quote(state.VariableData[i]) + "\n"
	}

	return state.FS.WriteAll(path, []byte(out))
}

// DumpTSet writes the current tileset values from the loaded raws to the indicated file.
func (state *State) DumpTSet(path string) error {
	rules := new(merge.RuleNode)
	err := state.Files.RunAction(map[string]bool{
		"Skip":       false,
		"TileSet":    true,
		"MergeRules": true,
	}, func(file *addon.File) error {
		return merge.ParseRules(file.Content, rules)
	})
	if err != nil {
		return err
	}

	out := []byte("\n# Rubble tileset dump.\n# Automatically generated, do not edit!\n")

	set := new(merge.TagNode)
	state.Files.RunAction(map[string]bool{
		"Skip":             false,
		"NoWrite":          false,
		"AUXText":          false,
		"CreatureGraphics": false,
		"TileSet":          false,
		"RawFile":          true,
	}, func(file *addon.File) error {
		merge.PopulateTree(rparse.ParseRaws(file.Content), set, rules)
		return nil
	})
	out = append(out, set.String()...)

	return state.FS.WriteAll(path, out)
}

// UpdateAddonList writes a list of all addons and their activation status (in INI format) to the indicated file.
func (state *State) UpdateAddonList(dest string) error {
	out := make([]byte, 0, 2048)
	out = append(out, "\n# Rubble addon list.\n# Version: "+Version+"\n# Automatically generated, do not edit!\n\n[addons]\n"...)
	for _, addon := range state.Addons.List {
		if !addon.Meta.Tags["Library"] && !addon.Meta.Tags["DocPack"] {
			out = append(out, addon.Meta.Name+"="...)
			if state.Active[addon.Meta.Name] {
				out = append(out, "true\n"...)
			} else {
				out = append(out, "false\n"...)
			}
		}
	}

	return state.FS.WriteAll(dest, out)
}
