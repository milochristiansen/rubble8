/*
Copyright 2016 by Milo Christiansen

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

// Types and functions for dealing with DFFD.
package dffd

import "crypto/sha256"
import "fmt"
import "time"
import "net/url"
import "net/http"
import "encoding/json"
import "encoding/hex"
import "strings"
import "strconv"

// jsonRawQuery is used for lazy reading of DFFD JSON file descriptions.
type jsonRawQuery struct {
	// Example (First Landing 1.8):
	//{
	//	"version":"1.8",
	//	"updated_timestamp":"1461864623",
	//	"updated_date":"Apr 28, 2016, 12:30:23 pm",
	//	"filename":"First Landing.zip",
	//	"size":"334600",
	//	"author":"milo christiansen",
	//	"version_df":"0.42.06",
	//	"sha256":"401efaf8050566078f07dba4ef094796b93ee5ca46541c28de251aba61f5ec50",
	//	"rating":"0.0",
	//	"votes":"0"
	//}
	
	Version string `json:"version"`
	UpdatedStamp int64 `json:"updated_timestamp,string"`
	UpdatedDate string `json:"updated_date"`
	File string `json:"filename"`
	Size int64 `json:"size,string"`
	Author string `json:"author"`
	DFVersion string `json:"version_df"`
	SHA256 string `json:"sha256"`
	Rating string `json:"rating"`
	Votes int64 `json:"votes,string"`
}

// Info is semi-parsed information on a particular file ID from DFFD.
// Some of the fields in this structure are not used by Rubble.
type Info struct {
	// The DFFD file ID used to retrieve this information.
	ID int64
	
	// The name of the current file.
	File string
	
	// Version information for the file.
	// VersionStr is always set, but the others are only set if Rubble can parse the version number.
	// Rubble will attempt to read the version as a two part number ("1.0") or a three part number ("1.0.0").
	// Any non-numeric elements will cause parsing to fail, leading the numeric version info to be unset.
	// Rubble uses this information to determine if a version is newer or older than the local copy, so it is
	// fairly important to make sure the version string given to DFFD can be parsed by Rubble.
	VerMajor int
	VerMinor int
	VerPatch int
	VersionStr string
	
	// The time the file was last updated. I have no idea how accurate this is, probably
	// only good enough to display to the user.
	// Rubble does not use this information.
	Updated time.Time
	
	// The DFFD user who uploaded the file.
	// Rubble does not use this information.
	Author string
	
	// Dwarf fortress version information for the package.
	// If Rubble cannot parse the version for some reason these will be set to "-1, 0" (meaning "any version").
	// See addon.HostVersions.
	DFVerMajor int
	DFVerPatch int
	
	// File size and a checksum.
	// Rubble does not use this information.
	Size int64
	SHA256 [sha256.Size]byte
}

// URL generates a download URL for the file defined by the Info structure.
func (info *Info) URL() string {
	return fmt.Sprintf("http://dffd.bay12games.com/download.php?id=%v&f=%v", info.ID, url.QueryEscape(info.File))
}

// Query looks up a file on DFFD and returns information about it.
func Query(id int64) (*Info, error) {
	// First get the JSON from DFFD.
	client := new(http.Client)
	r, err := client.Get(fmt.Sprintf("http://dffd.bay12games.com/file_data/%v.json", id))
	if err != nil {
		return nil, err
	}
	
	body := &jsonRawQuery{}
	err = json.NewDecoder(r.Body).Decode(body)
	r.Body.Close()
	if err != nil {
		return nil, err
	}
	
	// Now turn the JSON into something a little easier for Rubble to deal with.
	
	info := &Info{
		ID: id,
		File: body.File,
		VersionStr: body.Version,
		Author: body.Author,
		Size: body.Size,
	}
	
	// First the file version:
	verparts := strings.Split(body.Version, ".")
	if len(verparts) == 2 {
		M, erra := strconv.Atoi(verparts[0])
		m, errb := strconv.Atoi(verparts[1])
		if erra == nil && errb == nil {
			info.VerMajor = M
			info.VerMinor = m
			info.VerPatch = 0
		}
	} else if len(verparts) == 3 {
		M, erra := strconv.Atoi(verparts[0])
		m, errb := strconv.Atoi(verparts[1])
		p, errc := strconv.Atoi(verparts[2])
		if erra == nil && errb == nil && errc == nil {
			info.VerMajor = M
			info.VerMinor = m
			info.VerPatch = p
		}
	}
	
	// Then the update time/date:
	info.Updated, err = time.Parse("Jan 2, 2006, 3:04:05 pm", body.UpdatedDate)
	if err != nil {
		return nil, err
	}
	
	// And the DF version:
	verparts = strings.Split(body.DFVersion, ".")
	if len(verparts) == 3 && verparts[0] == "0" {
		M, erra := strconv.Atoi(verparts[1])
		m, errb := strconv.Atoi(verparts[2])
		if erra == nil && errb == nil {
			info.DFVerMajor = M
			info.DFVerPatch = m
		}
	}
	
	// And finally the checksum:
	sumbytes, err := hex.DecodeString(body.SHA256)
	if err != nil {
		return nil, err
	}
	
	if len(sumbytes) == sha256.Size {
		for i, byt := range sumbytes {
			info.SHA256[i] = byt
		}
	}
	
	return info, nil
}
