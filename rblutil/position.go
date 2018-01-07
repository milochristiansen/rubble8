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

package rblutil

import "fmt"
import "sort"

// LineInfo stores offset -> line mapping information for a file in a compact format.
type LineInfo struct {
	name string
	size int // length of the file
	offset int // Offset the first line in file by this much.
	lines []int // line -> offset of first char
}

// NewLineInfo creates a new LineInfo object with the given information.
// "name" can be left blank, PosString will automatically compensate.
func NewLineInfo(name string, line, size int) *LineInfo {
	return &LineInfo{
		name: name,
		offset: line,
		size: size,
	}
}

// AddLine adds the line offset for a new line.
// The line offset must be larger than the offset for the previous line
// and smaller than the file size; otherwise the line offset is ignored.
func (f *LineInfo) AddLine(offset int) {
	if i := len(f.lines); (i == 0 || f.lines[i - 1] < offset) && offset < f.size {
		f.lines = append(f.lines, offset)
	}
}

// Position returns file name, line, and column information based on an offset.
// If the offset is invalid (too large or small) "line" and "column" will be -1.
func (f *LineInfo) Position(offset int) (name string, line, column int) {
	if offset > f.size || offset < 0 {
		return f.name, -1, -1
	}
	
	if len(f.lines) == 0 {
		return f.name, f.offset, offset + 1
	}
	
	i := sort.SearchInts(f.lines, offset) - 1
	if i >= 0 {
		return f.name, i + f.offset + 1, offset - f.lines[i] + 1
	}
	return f.name, -1, -1
}

// PosString is like Position, except the information is encoded in a string for display to the user
func (f *LineInfo) PosString(offset int) string {
	a, b, c := f.Position(offset)
	if b == -1 {
		// Error: xyz At: somefile|invalid offset
		if a == "" {
			return "invalid offset"
		}
		return a + "|invalid offset"
	}
	
	if a == "" {
		return fmt.Sprintf("L:%v|C:%v", b, c)
	}
	return fmt.Sprintf("%v|L:%v|C:%v", a, b, c)
}
