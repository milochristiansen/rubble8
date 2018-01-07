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

package rubble8

import "github.com/milochristiansen/rubble8/rblutil/addon"
import "github.com/milochristiansen/rubble8/rblutil/errors"

var InvalidScriptLangError = &errors.Error{Msg: "No script runner registered for the requested language."}

type Runner interface {
	// Run runs a single script and returns a string or error
	// "line" will be 1 unless the script is embedded in a larger file, then it will be the line where the first
	// line of the script appears. The name of the file containing the script is available as "name".
	// args may be nil, otherwise it is a list of arguments to the script.
	Run(script []byte, tag string, name string, line int, args []string) (string, error)
}

type sRM struct {
	f func(*State) Runner
	t []string
}

var scriptrunners []sRM

// AddDefaultRunner adds a Runner to the list of Runners that will be available to any new Core created with NewCore.
// You need to pass a function that returns a new Runner, since multiple Cores should not share Runners.
func AddDefaultRunner(tags []string, maker func(*State) Runner) {
	scriptrunners = append(scriptrunners, sRM{
		f: maker,
		t: tags,
	})
}

// Core is the central arbitrator of all script operations.
// A Core matches file tags to script Runners.
type ScriptCore map[string]Runner

// NewScriptCore creates a Core with all the currently registered Runners added.
func NewScriptCore(state *State) ScriptCore {
	core := make(ScriptCore)

	for _, v := range scriptrunners {
		r := v.f(state)
		for _, t := range v.t {
			core[t] = r
		}
	}
	return core
}

// RunScript runs a script with the given information. The provided tag is used to determine script language.
// If there is no Runner available that can run the script then InvalidScriptLangError will be returned.
func (core ScriptCore) RunScript(script []byte, name string, line int, args []string, tag string) (string, error) {
	runner := core[tag]
	if runner != nil {
		return runner.Run(script, tag, name, line, args)
	}
	return "", InvalidScriptLangError
}

// RunScriptFile runs a script file. All meta-data is gathered from the file structure.
// If there is no Runner available that can run the script then InvalidScriptLangError will be returned.
func (core ScriptCore) RunScriptFile(file *addon.File) (string, error) {
	for tag, runner := range core {
		if file.Tags[tag] {
			return runner.Run(file.Content, tag, file.Name, 1, nil)
		}
	}
	return "", InvalidScriptLangError
}

// IsScriptFile returns true if the given file is tagged with a valid script language.
func (core ScriptCore) IsScriptFile(file *addon.File) bool {
	for tag, _ := range core {
		if file.Tags[tag] {
			return true
		}
	}
	return false
}
