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

package addon

import "html/template"
import "crypto/md5"

// PackMeta is used to store special meta data for an addon pack.
// This information is used by the loader and content servers, and does not belong to any particular addon.
type PackMeta struct {
	// The name of this addon pack. May be the same as an existing addon name.
	// This is not required. If you will be listing this pack on a content server it is a good idea to set this.
	Name string
	
	// A single line description, unused right now, but will be important for the content server browser later.
	Desc template.HTML
	
	// Version information for updating via a content server.
	VersionStr string
	VerMajor int
	VerMinor int
	VerPatch int
	
	// If this addon pack is hosted on DFFD this should be set to it's file ID.
	// If the file cannot be found on a content server the addon loader will use
	// this ID to look up the file information from DFFD.
	// Generally content servers are preferred, as they have more, better, information.
	DFFDID int64
	
	HostVer *HostVersions
	
	// A list of addon packs to download in addition to this one. The URLs for the packs are found by querying content
	// servers, so make sure the packs are listed on one.
	Dependencies []string
	
	// Maps of extension->tag for the file tagger. These mappings only effect the addons in the pack that "owns" this meta file.
	TagsFirst map[string][]string
	TagsLast map[string][]string
	
	// A list of custom file writers supplied for this pack.
	Writers []*FileWriter
	
	URL   string // Set automatically by content servers. Don't touch.
	MD5   *[md5.Size]byte // Set automatically by content servers. Don't touch.
	Owner string // Set automatically by content servers. Don't touch.
}

type HostVersions struct {
	// Dwarf fortress version this pack is compatible with.
	DFMajor int // If -1 then this does not require any particular DF version, else must be equal.
	DFPatch int // Must be equal or greater.
	
	// Rubble version this pack is compatible with.
	RblRewrite int // If -1 then any Rubble version will do, else must be equal.
	RblMajor   int // Must be equal or greater.
	RblPatch   int // Must be equal or greater (unless major is greater).
}

type FileWriter struct {
	Desc    string // A short file type description.
	Dir     string // The AXIS path to write the files to.
	Filter  map[string]bool // All files matching this filter will be written.
	Comment string // The comment prefix for this file type, if unset the file will not have a header added.
	
	// These two values control the optional file extension compaction.
	// 
	// ExtHas must be an extension to compact. If either part of the extension is ".%" then that part will match
	// anything. To disable compaction simply set ExtHas to "". Generally ExtHas will be a two-part extension, but
	// it is perfectly legal to use a single-part extension as well.
	// 
	// If ExtGive is "" then it will be set to the last part extension from ExtHas (respecting the ".%" special
	// value).
	// 
	// For example specifying ".%.%" for ExtHas and "" for ExtGive will simply strip the first part extension from
	// all written files.
	// 
	// File extension compaction can get complicated in a hurry...
	ExtHas  string
	ExtGive string 
	
	AddHeader bool // If true then the file will receive a raw file header consisting of the file name without extension.
	AllowIA   bool // Does this writer work in independent apply mode?
}

// NewPackMeta creates a new pack meta data object, setting some critical defaults.
func NewPackMeta() *PackMeta {
	return &PackMeta{
		Desc: template.HTML("The author of this addon pack did not provide a description."),
		
		DFFDID: -1,
		
		HostVer: &HostVersions{
			DFMajor: -1,
			RblRewrite: -1,
		},
		
		TagsFirst: map[string][]string{},
		TagsLast: map[string][]string{},
	}
}

// MatchVersions checks that the addon pack is compatible with the given client versions.
func (pack *PackMeta) MatchVersions(host *HostVersions) bool {
	// Try to match the DF version.
	if pack.HostVer.DFMajor != -1 && pack.HostVer.DFMajor == host.DFMajor {
		if pack.HostVer.DFPatch != -1 && pack.HostVer.DFPatch > host.DFPatch {
			return false
		}
	} else if pack.HostVer.DFMajor != -1 && pack.HostVer.DFMajor > host.DFMajor {
		return false
	}
	
	// DF version matched, try to match the Rubble version.
	if pack.HostVer.RblRewrite != -1 && pack.HostVer.RblRewrite == host.RblRewrite {
		if pack.HostVer.RblMajor == host.RblMajor {
			if pack.HostVer.RblPatch > host.RblPatch {
				return false
			}
		} else if pack.HostVer.RblMajor > host.RblMajor {
			return false
		}
	} else if pack.HostVer.RblRewrite != -1 && pack.HostVer.RblRewrite > host.RblRewrite {
		return false
	}
	return true
}

// Meta is used to store meta-data for an Addon.
type Meta struct {
	// Addon tags. Some have hardcoded handling, but you can have user defined tags as well.
	Tags map[string]bool

	// The addon name.
	Name string

	// A one line addon description.
	// For use by user interfaces (not used directly by Rubble).
	Header template.HTML

	// A longer addon description, may be as long as you like.
	// If Header is an adequate description leave this empty.
	// For use by user interfaces (not used directly by Rubble).
	Description template.HTML
	DescFile    string

	// Addon names for addons that are automatically activated when this addon is active.
	Activates []string

	// Addon names for addons that are incompatible with this addon.
	Incompatible []string

	// Configuration variables used by this addon and their default values.
	Vars map[string]*MetaVar

	// A load priority number, addons are sorted from lowest to highest.
	// Negative numbers mean "use parent", if there is no parent then the
	// absolute value is used.
	// Default is -100.
	LoadPriority int

	// Author and Version are inheritable from the parent if they are set to " " (the default).
	Author  string
	Version string
}

// MetaVar is used to store meta data about a config var.
type MetaVar struct {
	Name string // A user friendly name/description, may be empty.

	// A list of possible values for this variable. Index 0 is the default value.
	Values []string
}

// NewMeta creates a new addon meta data value, setting some critical defaults.
func NewMeta() *Meta {
	return &Meta{
		Tags:         make(map[string]bool),
		Header:       template.HTML("The author of this addon did not provide a short description."),
		Activates:    []string{},
		Incompatible: []string{},
		Vars:         make(map[string]*MetaVar),

		LoadPriority: -100,
		Author:       " ",
		Version:      " ",
	}
}
