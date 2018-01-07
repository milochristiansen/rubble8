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

import "github.com/milochristiansen/rubble8/rblutil/addon"

import "math/rand"
import "time"
import "hash/crc64"

// *rand.Rand
func rubbleRandomTbl(l *lua.State) {
	l.NewTable(0, 2)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		rng := l.ToUser(1).(*rand.Rand)

		switch l.ToString(2) {
		case "int":
			l.Push(rng.Int63())
			return 1
		case "intn":
			l.Push(func(l *lua.State) int {
				rng := l.ToUser(1).(*rand.Rand)

				// You would think that "[0,n]" when describing a range would be inclusive, but apparently not...
				l.Push(rng.Int63n(l.OptInt(2, 1) + 1))
				return 1
			})
			return 1
		case "float":
			l.Push(rng.Float64())
			return 1
		case "seed":
			l.Push(time.Now().UnixNano())
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)

	l.Push("__newindex")
	l.Push(func(l *lua.State) int {
		rng := l.ToUser(1).(*rand.Rand)

		switch l.ToString(2) {
		case "seed":
			if l.TypeOf(3) == lua.TypString {
				rng.Seed(int64(crc64.Checksum([]byte(l.ToString(3)), crc64.MakeTable(crc64.ECMA))))
				return 0
			}

			rng.Seed(l.ToInt(3))
		}
		return 0
	})
	l.SetTableRaw(tidx)
}

type addonFileListIter struct {
	i    int
	list *addon.FileList
}

// rubble8.*State.Files
func rubbleStateFilesTbl(l *lua.State) {
	l.NewTable(0, 2)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		state := getState(l)

		file, ok := state.Files.Data[l.ToString(2)]
		if ok {
			l.Push(file)
			addonFileTbl(l, true)
			l.SetMetaTable(-2)
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)

	l.Push("__pairs")
	l.Push(func(l *lua.State) int {
		state := getState(l)

		l.Push(func(l *lua.State) int {
			iter := l.ToUser(1).(*addonFileListIter)

			iter.i++
			if iter.i < len(iter.list.Order) {
				l.Push(iter.list.Order[iter.i])
				l.Push(iter.list.Data[iter.list.Order[iter.i]])
				addonFileTbl(l, true)
				l.SetMetaTable(-2)
				return 2
			}
			l.Push(nil)
			return 1
		})
		l.Push(&addonFileListIter{
			i:    -1,
			list: state.Files,
		})
		l.Push(nil)
		return 3
	})
	l.SetTableRaw(tidx)
}

// rubble8.*State.GlobalFiles
func rubbleStateGlobalFilesTbl(l *lua.State) {
	l.NewTable(0, 2)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		state := getState(l)

		name := l.OptString(2, "")
		file, ok := state.GlobalFiles.Data[name]
		if ok {
			l.Push(file)
			addonFileTbl(l, true)
			l.SetMetaTable(-2)
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)

	l.Push("__pairs")
	l.Push(func(l *lua.State) int {
		state := getState(l)

		l.Push(func(l *lua.State) int {
			iter := l.ToUser(1).(*addonFileListIter)

			iter.i++
			if iter.i < len(iter.list.Order) {
				l.Push(iter.list.Order[iter.i])
				l.Push(iter.list.Data[iter.list.Order[iter.i]])
				addonFileTbl(l, true)
				l.SetMetaTable(-2)
				return 2
			}
			l.Push(nil)
			return 1
		})
		l.Push(&addonFileListIter{
			i:    -1,
			list: state.GlobalFiles,
		})
		l.Push(nil)
		return 3
	})
	l.SetTableRaw(tidx)
}

// rubble8.*State.Addons.List
func rubbleStateAddonsTbl(l *lua.State) {
	l.NewTable(0, 4)
	tidx := l.AbsIndex(-1)

	l.Push("__len")
	l.Push(func(l *lua.State) int {
		state := getState(l)

		l.Push(int64(len(state.Addons.List)))
		return 1
	})
	l.SetTableRaw(tidx)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		state := getState(l)

		// Use 1 based indexing here to fit in with the other parts of Lua.
		i := int(l.ToInt(2))
		if i < 1 || i > len(state.Addons.List) {
			return 0
		}

		l.Push(state.Addons.List[i-1])
		addonTbl(l)
		l.SetMetaTable(-2)
		return 1
	})
	l.SetTableRaw(tidx)

	l.Push("__pairs")
	l.Push(func(l *lua.State) int {
		l.Push(func(l *lua.State) int {
			state := getState(l)

			i := int(l.ToInt(2))
			i++
			if i < len(state.Addons.List) {
				l.Push(int64(i))
				l.Push(state.Addons.List[i])
				addonTbl(l)
				l.SetMetaTable(-2)
				return 2
			}
			l.Push(nil)
			return 1
		})
		l.PushIndex(1)
		l.Push(int64(-1))
		return 3
	})
	l.SetTableRaw(tidx)
}

// rubble8.*State.Addons.Table
func rubbleStateAddonsTblTbl(l *lua.State) {
	l.NewTable(0, 1)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		state := getState(l)

		addon, ok := state.Addons.Table[l.ToString(2)]
		if !ok {
			return 0
		}

		l.Push(addon)
		addonTbl(l)
		l.SetMetaTable(-2)
		return 1
	})
	l.SetTableRaw(tidx)
}

// *addon.Addon
func addonTbl(l *lua.State) {
	l.NewTable(0, 2)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		addon := l.ToUser(1).(*addon.Addon)

		switch l.ToString(2) {
		case "Source":
			l.Push(addon.Source)
			return 1
		case "Files":
			l.Push(addon.Files)
			addonFilemapTbl(l)
			l.SetMetaTable(-2)
			return 1
		case "Meta":
			l.Push(addon.Meta)
			addonMetaTbl(l)
			l.SetMetaTable(-2)
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)
}

type addonFilemapIter struct {
	i    int
	keys []string
	list map[string]*addon.File
}

// map[string]*addon.File
func addonFilemapTbl(l *lua.State) {
	l.NewTable(0, 2)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		files := l.ToUser(1).(map[string]*addon.File)
		file, ok := files[l.ToString(2)]
		if ok {
			l.Push(file)
			addonFileTbl(l, false)
			l.SetMetaTable(-2)
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)

	l.Push("__pairs")
	l.Push(func(l *lua.State) int {
		files := l.ToUser(1).(map[string]*addon.File)
		il := make([]string, 0, len(files))
		for i := range files {
			il = append(il, i)
		}

		l.Push(func(l *lua.State) int {
			iter := l.ToUser(1).(*addonFilemapIter)

			iter.i++
			if iter.i < len(iter.keys) {
				l.Push(iter.keys[iter.i])
				l.Push(iter.list[iter.keys[iter.i]])
				addonFileTbl(l, false)
				l.SetMetaTable(-2)
				return 2
			}
			l.Push(nil)
			return 1
		})
		l.Push(&addonFilemapIter{
			i:    -1,
			keys: il,
			list: files,
		})
		l.Push(nil)
		return 3
	})
	l.SetTableRaw(tidx)
}

// *addon.Meta
func addonMetaTbl(l *lua.State) {
	l.NewTable(0, 2)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		meta := l.ToUser(1).(*addon.Meta)

		switch l.ToString(2) {
		case "Tags":
			l.Push(meta.Tags)
			tagsTbl(l, false)
			l.SetMetaTable(-2)
			return 1
		case "Name":
			l.Push(meta.Name)
			return 1
		case "Header":
			l.Push(string(meta.Header))
			return 1
		case "Description":
			l.Push(string(meta.Description))
			return 1
		case "DescFile":
			l.Push(meta.DescFile)
			return 1
		case "Activates":
			l.Push(&meta.Activates)
			strsliceTbl(l, false)
			l.SetMetaTable(-2)
			return 1
		case "Incompatible":
			l.Push(&meta.Incompatible)
			strsliceTbl(l, false)
			l.SetMetaTable(-2)
			return 1
		case "Vars":
			l.Push(meta.Vars)
			addonMetaVarmapTbl(l)
			l.SetMetaTable(-2)
			return 1
		case "LoadPriority":
			l.Push(int64(meta.LoadPriority))
			return 1
		case "Author":
			l.Push(meta.Author)
			return 1
		case "Version":
			l.Push(meta.Version)
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)
}

type addonMetaVarmapIter struct {
	i    int
	keys []string
	list map[string]*addon.MetaVar
}

// map[string]*addon.MetaVar
func addonMetaVarmapTbl(l *lua.State) {
	l.NewTable(0, 2)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		vars := l.ToUser(1).(map[string]*addon.MetaVar)

		v, ok := vars[l.ToString(2)]
		if ok {
			l.Push(v)
			addonMetaVarTbl(l)
			l.SetMetaTable(-2)
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)

	l.Push("__pairs")
	l.Push(func(l *lua.State) int {
		vars := l.ToUser(1).(map[string]*addon.MetaVar)
		il := make([]string, 0, len(vars))
		for i := range vars {
			il = append(il, i)
		}

		l.Push(func(l *lua.State) int {
			iter := l.ToUser(1).(*addonMetaVarmapIter)

			iter.i++
			if iter.i < len(iter.keys) {
				l.Push(iter.keys[iter.i])
				l.Push(iter.list[iter.keys[iter.i]])
				addonMetaVarTbl(l)
				l.SetMetaTable(-2)
				return 2
			}
			l.Push(nil)
			return 1
		})
		l.Push(&addonMetaVarmapIter{
			i:    -1,
			keys: il,
			list: vars,
		})
		l.Push(nil)
		return 3
	})
	l.SetTableRaw(tidx)
}

func addonMetaVarTbl(l *lua.State) {
	l.NewTable(0, 2)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		val := l.ToUser(1).(*addon.MetaVar)

		switch l.ToString(2) {
		case "Name":
			l.Push(val.Name)
			return 1
		case "Values":
			l.Push(&val.Values)
			strsliceTbl(l, true)
			l.SetMetaTable(-2)
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)

	l.Push("__newindex")
	l.Push(func(l *lua.State) int {
		val := l.ToUser(1).(*addon.MetaVar)

		switch l.ToString(2) {
		case "Name":
			val.Name = l.ToString(3)
			return 0
		}
		return 0
	})
	l.SetTableRaw(tidx)
}

// []string
func strsliceTbl(l *lua.State, rw bool) {
	l.NewTable(0, 5)
	tidx := l.AbsIndex(-1)

	l.Push("__len")
	l.Push(func(l *lua.State) int {
		slice := l.ToUser(1).(*[]string)

		l.Push(int64(len(*slice)))
		return 1
	})
	l.SetTableRaw(tidx)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		slice := l.ToUser(1).(*[]string)

		// Use 1 based indexing to fit in with the other parts of Lua
		idx := int(l.OptInt(2, 1))
		if idx < 1 || idx > len(*slice) {
			return 0
		}

		l.Push((*slice)[idx-1])
		return 1
	})
	l.SetTableRaw(tidx)

	if rw {
		l.Push("__newindex")
		l.Push(func(l *lua.State) int {
			slice := l.ToUser(1).(*[]string)

			idx := int(l.OptInt(2, -1))
			if idx < 1 || idx > len(*slice)+1 {
				return 0
			}

			if idx == len(*slice)+1 {
				*slice = append(*slice, l.ToString(3))
				return 0
			}
			(*slice)[idx-1] = l.ToString(3)
			return 0
		})
		l.SetTableRaw(tidx)
	}

	l.Push("__pairs")
	l.Push(func(l *lua.State) int {
		l.Push(func(l *lua.State) int {
			slice := l.ToUser(1).(*[]string)

			i := int(l.ToInt(2))
			i++
			if i < len(*slice) {
				l.Push(int64(i))
				l.Push((*slice)[i])
				return 2
			}
			l.Push(nil)
			return 1
		})
		l.PushIndex(1)
		l.Push(int64(-1))
		return 3
	})
	l.SetTableRaw(tidx)
}

// *addon.File
func addonFileTbl(l *lua.State, rw bool) {
	l.NewTable(0, 2)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		file := l.ToUser(1).(*addon.File)
		key := l.OptString(2, "")

		switch key {
		case "Content":
			l.Push(string(file.Content))
			return 1
		case "Name":
			l.Push(file.Name)
			return 1
		case "Source":
			l.Push(file.Source)
			return 1
		case "Tags":
			l.Push(file.Tags)
			tagsTbl(l, rw)
			l.SetMetaTable(-2)
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)

	if rw {

		l.Push("__newindex")
		l.Push(func(l *lua.State) int {
			file := l.ToUser(1).(*addon.File)
			key := l.OptString(2, "")

			switch key {
			case "Content":
				file.Content = []byte(l.ToString(3))
			case "Name":
				file.Name = l.ToString(3)
			case "Source":
				file.Source = l.ToString(3)
				// Cant set Tags
			}
			return 0
		})
		l.SetTableRaw(tidx)
	}
}

type tagsIter struct {
	i    int
	keys []string
	list map[string]bool
}

// map[string]bool
func tagsTbl(l *lua.State, rw bool) {
	l.NewTable(0, 3)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		tags := l.ToUser(1).(map[string]bool)
		val, ok := tags[l.ToString(2)]
		if ok {
			l.Push(val)
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)

	if rw {
		l.Push("__newindex")
		l.Push(func(l *lua.State) int {
			tags := l.ToUser(1).(map[string]bool)
			tags[l.ToString(2)] = l.ToBool(3)
			return 0
		})
		l.SetTableRaw(tidx)
	}

	l.Push("__pairs")
	l.Push(func(l *lua.State) int {
		tags := l.ToUser(1).(map[string]bool)
		il := make([]string, 0, len(tags))
		for i := range tags {
			il = append(il, i)
		}

		l.Push(func(l *lua.State) int {
			iter := l.ToUser(1).(*tagsIter)

			iter.i++
			if iter.i < len(iter.keys) {
				l.Push(iter.keys[iter.i])
				l.Push(iter.list[iter.keys[iter.i]])
				return 2
			}
			l.Push(nil)
			return 1
		})
		l.Push(&tagsIter{
			i:    -1,
			keys: il,
			list: tags,
		})
		l.Push(nil)
		return 3
	})
	l.SetTableRaw(tidx)
}

// rubble8.(*State).Active
func rubbleStateActiveTbl(l *lua.State) {
	l.NewTable(0, 3)
	tidx := l.AbsIndex(-1)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		state := getState(l)

		val, ok := state.Active[l.ToString(2)]
		if ok {
			l.Push(val)
			return 1
		}
		return 0
	})
	l.SetTableRaw(tidx)

	l.Push("__pairs")
	l.Push(func(l *lua.State) int {
		state := getState(l)

		il := make([]string, 0, len(state.Active))
		for i := range state.Active {
			il = append(il, i)
		}

		l.Push(func(l *lua.State) int {
			iter := l.ToUser(1).(*tagsIter)

			iter.i++
			if iter.i < len(iter.keys) {
				l.Push(iter.keys[iter.i])
				l.Push(iter.list[iter.keys[iter.i]])
				return 2
			}
			l.Push(nil)
			return 1
		})
		l.Push(&tagsIter{
			i:    -1,
			keys: il,
			list: state.Active,
		})
		l.Push(nil)
		return 3
	})
	l.SetTableRaw(tidx)
}

type strmapIter struct {
	i    int
	keys []string
	list map[string]string
}

// map[string]string
func strmapTbl(l *lua.State) {
	l.NewTable(0, 4)
	tidx := l.AbsIndex(-1)

	l.Push("__len")
	l.Push(func(l *lua.State) int {
		strmap := l.ToUser(1).(map[string]string)

		l.Push(int64(len(strmap)))
		return 1
	})
	l.SetTableRaw(tidx)

	l.Push("__index")
	l.Push(func(l *lua.State) int {
		strmap := l.ToUser(1).(map[string]string)
		val, ok := strmap[l.ToString(2)]
		if ok {
			l.Push(val)
			return 1
		}
		l.Push(nil)
		return 1
	})
	l.SetTableRaw(tidx)

	l.Push("__newindex")
	l.Push(func(l *lua.State) int {
		strmap := l.ToUser(1).(map[string]string)
		strmap[l.ToString(2)] = l.ToString(3)
		return 0
	})
	l.SetTableRaw(tidx)

	l.Push("__pairs")
	l.Push(func(l *lua.State) int {
		strmap := l.ToUser(1).(map[string]string)
		il := make([]string, 0, len(strmap))
		for i := range strmap {
			il = append(il, i)
		}

		l.Push(func(l *lua.State) int {
			iter := l.ToUser(1).(*strmapIter)

			iter.i++
			if iter.i < len(iter.keys) {
				l.Push(iter.keys[iter.i])
				l.Push(iter.list[iter.keys[iter.i]])
				return 2
			}
			l.Push(nil)
			return 1
		})
		l.Push(&strmapIter{
			i:    -1,
			keys: il,
			list: strmap,
		})
		l.Push(nil)
		return 3
	})
	l.SetTableRaw(tidx)
}
