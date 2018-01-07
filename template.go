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

import "github.com/milochristiansen/rubble8/rblutil"
import "github.com/milochristiansen/rubble8/rblutil/errors"
import "github.com/milochristiansen/rubble8/rblutil/parse"

type Template struct {
	Code string

	Tag string

	ArgNames    []string
	ArgDefaults []string

	File   *rblutil.LineInfo
	Offset int
}

// This dispatcher will accept nil for the last two arguments.
func (state *State) Dispatcher(args []string, stage parse.Stage, file *rblutil.LineInfo, offsets []int) string {
	template, ok := state.Templates[args[0]]
	if !ok {
		errors.RaiseError("Nonexistent template: \"" + args[0] + "\"")
	}

	name, line := "unknown", 1
	if template.File != nil {
		name, line, _ = template.File.Position(template.Offset)
	}

	if template.Tag == "LangTemplate" {
		paramMap := make(map[string]string)
		for i := range template.ArgNames {
			if i < len(args)-1 {
				paramMap[template.ArgNames[i]] = args[i+1]
				continue
			}

			paramMap[template.ArgNames[i]] = template.ArgDefaults[i]
		}

		// User template
		out := template.Code
		out = rblutil.Expand(out, '%', true, paramMap)
		out = rblutil.Expand(out, '$', false, state.VariableData)
		out = rblutil.Expand(out, '&', true, state.VariableData)
		return string(parse.Parse([]byte(out), name, line, stage, state.Dispatcher, nil))
	}

	rtn, err := state.Script.RunScript([]byte(template.Code), name, line, args[1:], template.Tag)
	if err != nil {
		if file != nil {
			errors.RaiseWrappedError("In call to: "+args[0]+" at "+file.PosString(offsets[0]), err)
		}
		errors.RaiseWrappedError("In call to: "+args[0], err)
	}
	return rtn
}
