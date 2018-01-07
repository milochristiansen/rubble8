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

// Rubble addon loader and content server client code.
package addon

import "sort"
import "strings"

// Database stores loaded addons
type Database struct {
	List     []*Addon
	Table    map[string]*Addon
	DocPacks []*Meta
	Meta     map[string]*Meta
	Packs    map[string]*PackMeta
	Banks    map[string]string

	Writers []*FileWriter

	// Maps of extension->tag for the file tagger. These mappings are global.
	tagsFirst map[string][]string
	tagsLast  map[string][]string

	updateBlacklist map[string]bool

	Servers []string

	Globals *FileList
}

// File represents any file in an addon.
type File struct {
	Name    string // File name.
	Source  string // Addon path (AXIS syntax, including loc ids).
	Content []byte
	Tags    map[string]bool
}

// NewFile creates a new addon file with the specified name.
func NewFile(name, source string, content []byte) *File {
	file := new(File)
	file.Name = name
	file.Source = source
	file.Content = content
	file.Tags = make(map[string]bool)

	return file
}

// Addon represents an addon.
type Addon struct {
	Source string // Addon path (AXIS syntax, including loc ids).
	Meta   *Meta
	Files  map[string]*File
}

// NewAddon creates a new addon with the specified name and source.
func NewAddon(name, source string) *Addon {
	this := new(Addon)
	this.Source = source
	this.Meta = NewMeta()
	this.Meta.Name = name
	this.Files = make(map[string]*File)
	return this
}

// FileList stores an ordered list of Files.
type FileList struct {
	Order []string
	Data  map[string]*File
}

// NewFileList returns an empty FileList.
func NewFileList() *FileList {
	return &FileList{
		Order: make([]string, 0),
		Data:  make(map[string]*File),
	}
}

// Copy produces a new FileList with copies of the contained files (so that editing a file in the new list does not effect the old list).
func (list *FileList) Copy() *FileList {
	nlist := &FileList{
		Order: make([]string, len(list.Order)),
		Data:  make(map[string]*File, len(list.Data)),
	}
	copy(nlist.Order, list.Order)
	for name, file := range list.Data {
		nlist.Data[name] = &File{
			Name:    file.Name,
			Source:  file.Source,
			Content: append(make([]byte, 0, len(file.Content)), file.Content...),
			Tags:    map[string]bool{},
		}
		for tag, state := range file.Tags {
			nlist.Data[name].Tags[tag] = state
		}
	}
	return nlist
}

// Clear removes all files from the list.
// The list is returned so this can be chained with Update.
func (list *FileList) Clear(data []*Addon) *FileList {
	list.Order = make([]string, 0)
	list.Data = make(map[string]*File)
	return list
}

// Update adds all of the files from any active addons in the passed in slice.
// Inactive addons are ignored.
// If the addon slice is nil nothing is done.
func (list *FileList) Update(data []*Addon, active map[string]bool) {
	if data == nil {
		return
	}

	for _, addon := range data {
		if active[addon.Meta.Name] {
			for name, file := range addon.Files {
				if _, ok := list.Data[name]; !ok {
					list.Order = append(list.Order, name)
				}
				list.Data[name] = file
			}
		}
	}

	sort.Sort(stringSorter(list.Order))
}

// UpdateFunc adds all of the files from any active addons in the passed in slice.
// Inactive addons are ignored. If filter returns false for a file it is not included.
// If the addon slice is nil nothing is done.
func (list *FileList) UpdateFunc(data []*Addon, active map[string]bool, filter func(*File) bool) {
	if data == nil {
		return
	}

	for _, addon := range data {
		if active[addon.Meta.Name] {
			for name, file := range addon.Files {
				if filter(file) {
					if _, ok := list.Data[name]; !ok {
						list.Order = append(list.Order, name)
					}
					list.Data[name] = file
				}
			}
		}
	}

	sort.Sort(stringSorter(list.Order))
}

// UpdateFilter adds all of the files from any active addons in the passed in slice.
// Inactive addons are ignored. Files are only included if their file tags match the filter.
func (list *FileList) UpdateFilter(data []*Addon, active map[string]bool, filter map[string]bool) {
	if data == nil {
		return
	}

	for _, addon := range data {
		if active[addon.Meta.Name] {
		main:
			for name, file := range addon.Files {
				for tag, val := range filter {
					if file.Tags[tag] != val {
						continue main
					}
				}
				if _, ok := list.Data[name]; !ok {
					list.Order = append(list.Order, name)
				}
				list.Data[name] = file
			}
		}
	}

	sort.Sort(stringSorter(list.Order))
}

// UpdateGlobals adds all of the files from *any* addons in the passed in slice.
// Files are only included if they have the "GlobalFile" tag.
func (list *FileList) UpdateGlobals(data []*Addon) {
	if data == nil {
		return
	}

	for _, addon := range data {
		for name, file := range addon.Files {
			if !file.Tags["GlobalFile"] {
				continue
			}
			if _, ok := list.Data[name]; !ok {
				list.Order = append(list.Order, name)
			}
			list.Data[name] = file
		}
	}

	sort.Sort(stringSorter(list.Order))
}

func (list *FileList) AddFiles(files ...*File) {
	for _, file := range files {
		if _, ok := list.Data[file.Name]; !ok {
			list.Order = append(list.Order, file.Name)
		}
		list.Data[file.Name] = file
	}
	sort.Sort(stringSorter(list.Order))
}

func (list *FileList) Sort() {
	sort.Sort(stringSorter(list.Order))
}

// RunAction runs it's action for each file in the list who's tags match the filter.
// RunAction will always return nil unless the action does not return nil.
func (list *FileList) RunAction(filter map[string]bool, action func(*File) error) error {
main:
	for _, i := range list.Order {
		for tag, val := range filter {
			if list.Data[i].Tags[tag] != val {
				continue main
			}
		}

		err := action(list.Data[i])
		if err != nil {
			return err
		}
	}
	return nil
}

type stringSorter []string

func (p stringSorter) Len() int           { return len(p) }
func (p stringSorter) Less(i, j int) bool { return strings.ToLower(p[i]) < strings.ToLower(p[j]) }
func (p stringSorter) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }
