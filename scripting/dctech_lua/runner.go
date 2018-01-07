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

// Lua scripting for Rubble.
//
// This uses "github.com/milochristiansen/lua" as the runtime.
//
// To use Lua with Rubble simply use `import _ "rubble8/scripting/dctech_lua"`.
// Lua scripting will then be available to all Rubble States by default.
package lua

import "github.com/milochristiansen/lua"
import "github.com/milochristiansen/lua/lmodbase"
import "github.com/milochristiansen/lua/lmodpackage"
import "github.com/milochristiansen/lua/lmodstring"
import "github.com/milochristiansen/lua/lmodtable"
import "github.com/milochristiansen/lua/lmodmath"

import "github.com/milochristiansen/rubble8"
import "github.com/milochristiansen/rubble8/rblutil/addon"

import "bytes"
import "strconv"

// LuaRunner is a Runner for Lua scripts.
type LuaRunner struct {
	l *lua.State
}

// New creates a new LuaRunner.
// You do not normally need to call this, as rubble8.NewScriptCore will automatically do so.
func New(state *rubble8.State) rubble8.Runner {
	runner := &LuaRunner{
		l: lua.NewState(),
	}
	l := runner.l
	l.Output = state.Log

	l.NativeTrace = true

	// Load standard modules
	l.Push(lmodbase.Open)
	l.Call(0, 0)
	l.Push(lmodpackage.Open)
	l.Call(0, 0)
	l.Push(lmodstring.Open)
	l.Call(0, 0)
	l.Push(lmodtable.Open)
	l.Call(0, 0)
	l.Push(lmodmath.Open)
	l.Call(0, 0)

	// Save a state reference to the registry
	l.Push("RUBBLE_STATE")
	l.Push(state)
	l.SetTableRaw(lua.RegistryIndex)

	// And finally preload the Rubble API
	l.Preload("rubble", rubbleLuaAPI)
	l.Preload("axis", axisLuaAPI)
	l.Preload("rubble.rparse", rparseLuaAPI)

	// Isn't it nice to not have to work around third party bugs?
	return runner
}

// Get the Rubble state from the registry.
func getState(l *lua.State) *rubble8.State {
	l.Push("RUBBLE_STATE")
	l.GetTableRaw(lua.RegistryIndex)
	state := l.ToUser(-1).(*rubble8.State)
	l.Pop(1)
	return state
}

func init() {
	// We don't need to add a new language tag as Lua already has a tag (it is used by DFHack).
	// If we did need a new tag we would have to do the following:
	//	addon.DefaultLast[".lua"] = []string{"LangLua"}
	addon.DefaultLast[".luab"] = []string{"LangLuaBin"}
	rubble8.AddDefaultRunner([]string{"LangLua", "LangLuaBin"}, New)
}

func (runner *LuaRunner) Run(script []byte, tag string, name string, line int, args []string) (string, error) {
	l := runner.l
	if line > 1 {
		name += "@" + strconv.Itoa(line)
	}

	switch tag {
	case "LangLuaBin":
		err := l.LoadBinary(bytes.NewBuffer(script), name, 0)
		if err != nil {
			return "", err
		}
	default:
		err := l.LoadText(bytes.NewBuffer(script), name, 0)
		if err != nil {
			return "", err
		}
	}

	for _, v := range args {
		l.Push(v)
	}

	err := l.PCall(len(args), 1)
	if err != nil {
		return "", err
	}

	if l.IsNil(-1) {
		l.Pop(1)
		return "", nil
	}
	rtn := l.ToString(-1)
	l.Pop(1)
	return rtn, nil
}
