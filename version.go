/*
Copyright 2016-2018 by Milo Christiansen

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

import "strconv"

import "github.com/milochristiansen/rubble8/rblutil"

// To set the VExtra field while compiling do the following:
//	set "VERSION_TAG=<your tag string>"
//  go generate rubble8
//	go build -tags="vertag" rubble8
// You must have lua installed for this to work!

//go:generate lua ./#vertag.lua "$VERSION_TAG"

// The Dwarf Fortress version this version of Rubble is intended to work with.
// After Rubble has started the copies of these values found in the "rblutil" package may
// have been updated with more accurate values, use them if possible.
var DFVMajor, DFVMinor = 44, 4

// This is the current Rubble version.
var VMajor, VMinor, VPatch = 8, 5, 5

// Experimental, beta, and other special versions may specify an extra ID to add to the standard version string.
// This will automatically be set to one of several values based on satisfied (or unsatisfied) build constraints.
var VExtra = ""

// The Rubble version string, automatically constructed from the contents of VMajor, VMinor, VPatch, and VExtra.
var Version string

func init() {
	extra := VExtra
	if extra != "" {
		extra = " " + extra
	}
	Version = strconv.Itoa(VMajor) + "." + strconv.Itoa(VMinor) + "." + strconv.Itoa(VPatch) + extra

	// Some packages that cannot import the main Rubble package need to be able to read the version info, so mirror it in rblutil.
	rblutil.DFVMajor = DFVMajor
	rblutil.DFVMinor = DFVMinor

	rblutil.VMajor = VMajor
	rblutil.VMinor = VMinor
	rblutil.VPatch = VPatch
	rblutil.VExtra = VExtra
	rblutil.Version = Version
}
