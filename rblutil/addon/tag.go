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

package addon

import "rubble8/rblutil"

// See addons/world.meta for global tags

// Tag lists for native APIs to edit.
var DefaultFirst = map[string][]string{}
var DefaultLast = map[string][]string{}

// GetFileTags uses the given tag maps to find the file tags for a file with the given name.
// The returned slice of tags is yours to keep.
func GetFileTags(fa, la, fb, lb map[string][]string, name string) []string {
	f, l := rblutil.GetExtParts(name)
	
	var fav, lav, fbv, lbv []string
	if fa != nil { fav = fa[f] }
	if la != nil { lav = la[l] }
	if fb != nil { fbv = fb[f] }
	if lb != nil { lbv = lb[l] }
	
	rtn := make([]string, 0, len(fav)+len(lav)+len(fbv)+len(lbv))
	rtn = append(rtn, fav...)
	rtn = append(rtn, lav...)
	rtn = append(rtn, fbv...)
	rtn = append(rtn, lbv...)
	
	return rtn
}
