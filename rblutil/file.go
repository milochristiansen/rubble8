/*
Copyright 2013-2016 by Milo Christiansen

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

import "github.com/milochristiansen/axis2"
import "html/template"
import "strings"

// ReplacePrefix checks to see if the string begins with the prefix, and replaces it if it does.
// This is generally used to "fix" AXIS paths before AXIS is available.
func ReplacePrefix(s, prefix, replace string) string {
	if strings.HasPrefix(s, prefix) {
		s = s[len(prefix):]
		return replace + s
	}
	return s
}

// Strip the extension from a file name.
// If a file has multiple extensions strip only the last.
func StripExt(name string) string {
	i := len(name) - 1
	for i >= 0 {
		if name[i] == '.' {
			return name[:i]
		}
		i--
	}
	return name
}

// ReplaceExt replaces the file extension with n, but only if it matches o.
func ReplaceExt(name, o, n string) string {
	if strings.HasSuffix(name, o) {
		return strings.TrimSuffix(name, o) + n
	}
	return name
}

// ReplaceExtAdv replaces a Rubble two part extension.
// If you set one of the parts of the old extension to ".%" this will assume any extension may go in that place.
// If n is set to "" then it will use the old last part extension.
func ReplaceExtAdv(name, o, n string) string {
	of, ol := GetExtParts(o)
	f, l := GetExtParts(name)
	if of == ".%" {
		of = f
	} else if of != f {
		return name
	}
	if ol == ".%" {
		ol = l
	} else if ol != l {
		return name
	}
	if n == "" {
		n = ol
	}
	return strings.TrimSuffix(name, of+ol) + n
}

// GetExt returns the extension from a file name.
func GetExt(name string) string {
	// Find the last part of the extension
	i := len(name) - 1
	for i >= 0 {
		if name[i] == '.' {
			return name[i:]
		}
		i--
	}
	return ""
}

// GetExtParts returns the extension from a file name.
// Unlike GetExt, GetExtParts returns the first and last part of a two part extension separately. `"abc.x.y"` would
// return `".x", ".y"` and `"abc.d"` would return `"", ".d"`.
func GetExtParts(name string) (first string, last string) {
	// Find the last part of the extension
	i := len(name) - 1
	j := 0
	for i >= 0 {
		if name[i] == '.' {
			last = name[i:]
			j = i
			i--
			break
		}
		i--
	}
	// Then look for the first part.
	for i >= 0 {
		if name[i] == '.' {
			return name[i : i+(j-i)], last
		}
		i--
	}
	return "", last
}

// Depreciated.
func LoadOr(fs *axis2.FileSystem, parent *template.Template, name, ext, file string) (*template.Template, error) {
	content, err := fs.ReadAll("rubble/other/webUI/" + name + ext)
	if err != nil {
		fs.WriteAll("rubble/other/webUI/"+name+ext, []byte(file))
		content = []byte(file)
	}
	if parent == nil {
		return template.New(name).Parse(string(content))
	}
	return parent.New(name).Parse(string(content))
}

// LoadTemplate is used for loading HTML templates for the web UI or the documentation generator.
// It attempts to load the file from "rubble/other/webUI/". parent may be nil.
func LoadTemplate(fs *axis2.FileSystem, parent *template.Template, name, ext string) (*template.Template, error) {
	content, err := fs.ReadAll("rubble/other/webUI/" + name + ext)
	if err != nil {
		return nil, err
	}
	if parent == nil {
		return template.New(name).Parse(string(content))
	}
	return parent.New(name).Parse(string(content))
}

// LoadOrString is used for loading special customizable files that have a hardcoded default.
// path must be the full AXIS path to the file and must be in a writable location!
func LoadOrString(fs *axis2.FileSystem, path, file string) string {
	content, err := fs.ReadAll(path)
	if err != nil {
		fs.WriteAll(path, []byte(file))
		return file
	}
	return string(content)
}
