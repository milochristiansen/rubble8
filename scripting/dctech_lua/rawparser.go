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

package lua

import "github.com/milochristiansen/lua"
import "rubble8/rblutil/rparse"
import "rubble8/rblutil/merge"

import "bytes"

func rparseLuaAPI(l *lua.State) int {
	l.NewTable(0, 8) // 3 functions (the Rubble standard library then adds a few)
	l.SetTableFunctions(-1, rparseLibrary)
	return 1
}

var rparseLibrary = map[string]lua.NativeFunction{
	"parse": func(l *lua.State) int {
		tags := rparse.ParseRaws([]byte(l.ToString(1)))

		l.NewTable(len(tags), 0)
		for i := range tags {
			l.Push(int64(i + 1))
			l.Push(tags[i])
			rparseTagTbl(l)
			l.SetMetaTable(-2)
			l.SetTableRaw(-3)
		}
		return 1
	},
	"format": func(l *lua.State) int {
		out := new(bytes.Buffer)
		
		l.ForEachInTable(1, func() {
			l.ToUser(-1).(*rparse.Tag).Format(out)
		})
		
		l.Push(out.String())
		return 1
	},
	"newtag": func(l *lua.State) int {
		l.Push(new(rparse.Tag))
		rparseTagTbl(l)
		l.SetMetaTable(-2)
		return 1
	},
	"maketree": func(l *lua.State) int {
		rtree := new(merge.RuleNode)
		merge.ParseRules([]byte(l.ToString(2)), rtree)
	
		tree := merge.TreeifyRaws(rparse.ParseRaws([]byte(l.ToString(1))), rtree)
		
		// Now for the tricky part, turning the tree into a set of nested tables.
		// OK, so it's not actually tricky after all...
		l.Push(nil)
		makeTagTreeTable(l, tree)
		return 1
	},
}

func makeTagTreeTable(l *lua.State, tree *merge.TagTree) {
	l.NewTable(2, len(tree.Children))
	l.Push("parent")
	l.PushIndex(-3)
	l.SetTableRaw(-3)
	if tree.Me != nil {
		l.Push("me")
		l.Push(tree.Me)
		rparseTagTbl(l)
		l.SetMetaTable(-2)
		l.SetTableRaw(-3)
	}
	for i, child := range tree.Children {
		makeTagTreeTable(l, child)
		l.Push(i+1)
		l.Insert(-1)
		l.SetTableRaw(-3)
	}
}

func rparseTagTbl(l *lua.State) {
	l.NewTable(0, 3)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		tag := l.ToUser(1).(*rparse.Tag)
		key := l.OptString(2, "")

		switch key {
		case "ID":
			l.Push(tag.ID)
			return 1
		case "Params":
			l.Push(&tag.Params)
			strsliceTbl(l, true)
			l.SetMetaTable(-2)
			return 1
		case "Comments":
			l.Push(tag.Comments)
			return 1
		case "CommentsOnly":
			l.Push(tag.CommentsOnly)
			return 1
		case "Line":
			l.Push(int64(tag.Line))
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)

	l.Push("__newindex")
	l.Push(func(l *lua.State) int {
		tag := l.ToUser(1).(*rparse.Tag)

		switch l.ToString(2) {
		case "ID":
			tag.ID = l.ToString(3)
			return 0
		case "Params":
			tag.Params = make([]string, 0, l.Length(3))
			
			l.ForEachInTable(3, func() {
				tag.Params = append(tag.Params, l.ToString(-1))
			})
			return 0
		case "Comments":
			tag.Comments = l.ToString(3)
			return 0
		case "CommentsOnly":
			tag.CommentsOnly = l.ToBool(3)
			return 0
		case "Line":
			tag.Line = int(l.ToInt(3))
			return 0
		}
		return 0
	})
	l.SetTableRaw(tidx)
	
	l.Push("__tostring")
	l.Push(func(l *lua.State) int {
		tag := l.ToUser(1).(*rparse.Tag)

		l.Push(tag.String())
		return 1
	})
	l.SetTableRaw(tidx)
}
