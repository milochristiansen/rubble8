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

package rblutil

// The Dwarf Fortress version this version of Rubble is intended to work with.
// These values are mirrored from the main Rubble package. This package's copy of the DF version is to be preferred
// over the one from the main Rubble package, as it may have been updated (the version in the main Rubble package
// never changes from the hardcoded default).
var DFVMajor, DFVMinor int

// This is the current Rubble version.
// These values are mirrored from the main Rubble package.
var VMajor, VMinor, VPatch int

// Experimental, beta, and other special versions may specify an extra ID to add to the standard version string.
// This will automatically be set to one of several values based on satisfied (or unsatisfied) build constraints.
// This value is mirrored from the main Rubble package.
var VExtra string

// The Rubble version string, automatically constructed from the contents of VMajor, VMinor, VPatch, and VExtra.
// This value is mirrored from the main Rubble package.
var Version string
