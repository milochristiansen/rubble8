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

package lua

import "github.com/milochristiansen/lua"
import "github.com/milochristiansen/rubble8"

var listAppend = func(l *lua.State) int {
	regdata := l.ToUser(1).(rubble8.ScrRegData)

	*regdata.List = append(*regdata.List, l.ToString(2))
	return 0
}

func rubbleRegistryTbl(l *lua.State) {
	l.NewTable(0, 1)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		state := getState(l)

		key := l.ToString(2)
		if key == "exists" {
			l.Push(&struct{}{})
			rubbleRegistryExistsTbl(l)
			l.SetMetaTable(-2)
			return 1
		}

		child, ok := state.ScrRegistry[key]
		if !ok {
			child = rubble8.ScrRegData{
				List:  &[]string{},
				Table: map[string]string{},
			}
			state.ScrRegistry[key] = child
		}

		l.Push(child)
		rubbleRegistryChildTbl(l)
		l.SetMetaTable(-2)
		return 1
	})
	l.SetTableRaw(tidx)
}

func rubbleRegistryExistsTbl(l *lua.State) {
	l.NewTable(0, 1)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		state := getState(l)

		_, ok := state.ScrRegistry[l.ToString(2)]
		l.Push(ok)
		return 1
	})
	l.SetTableRaw(tidx)
}

func rubbleRegistryChildTbl(l *lua.State) {
	l.NewTable(0, 1)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		regdata := l.ToUser(1).(rubble8.ScrRegData)

		switch l.ToString(2) {
		case "listappend":
			l.Push(listAppend)
			return 1
		case "list":
			l.Push(regdata.List)
			strsliceTbl(l, true)
			l.SetMetaTable(-2)
			return 1
		case "table":
			l.Push(regdata.Table)
			strmapTbl(l)
			l.SetMetaTable(-2)
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)
}
