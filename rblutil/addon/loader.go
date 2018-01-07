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

import "github.com/milochristiansen/axis2"
import "github.com/milochristiansen/axis2/sources/zip"

import "rubble8/rblutil"
import "rubble8/rblutil/errors"
import "rubble8/rblutil/dffd"

import "sort"
import "encoding/json"
import "html"
import "html/template"
import "strings"
import "io/ioutil"
import "net/http"

import "regexp"

// Load loads addons and addon packs from the the "addons" location in the given file system.
// The result is returned in a Database object. This object should not be modified.
func Load(fs *axis2.FileSystem, log rblutil.Logger) (data *Database, err error) {
	defer errors.TrapError(&err, log)

	rblutil.LogSeparator(log)
	log.Println("Loading Addons...")

	data = &Database{
		Table: map[string]*Addon{},
		Meta:  map[string]*Meta{},
		Packs: map[string]*PackMeta{},
		Banks: map[string]string{},

		tagsFirst: map[string][]string{},
		tagsLast:  map[string][]string{},

		updateBlacklist: map[string]bool{},

		Globals: NewFileList(),
	}

	log.Println("  Loading Global Settings...")
	global := NewPackMeta()
	content, err := fs.ReadAll("addons/global.meta")
	if err == nil {
		err := json.Unmarshal(killMetaComments.ReplaceAllLiteral(content, []byte("\n")), global)
		if err != nil {
			errors.RaiseWrappedError("While loading global.meta", err)
		}
	}
	data.Writers = append(data.Writers, global.Writers...)
	for k, v := range global.TagsFirst {
		data.tagsFirst[k] = v
	}
	for k, v := range global.TagsLast {
		data.tagsLast[k] = v
	}

	// Import any tags defined by native APIs (generally script runners).
	for k, v := range DefaultFirst {
		data.tagsFirst[k] = v
	}
	for k, v := range DefaultLast {
		data.tagsLast[k] = v
	}

	log.Println("  Attempting to Read Auto-Update Blacklist...")
	content, err = fs.ReadAll("addons/update_blacklist.txt")
	if err == nil {
		log.Println("    Read OK, loading...")
		for _, line := range strings.Split(string(content), "\n") {
			line = strings.TrimSpace(line)
			if line == "" || line[0] == '#' {
				continue
			}

			data.updateBlacklist[line] = true
		}
	} else {
		log.Println("    Read failed (this is most likely ok)\n    Error:", err)
	}

	log.Println("  Attempting to Read Content Server List...")
	content, err = fs.ReadAll("addons/content_servers.txt")
	if err == nil {
		log.Println("    Read OK, loading...")
		for _, line := range strings.Split(string(content), "\n") {
			line = strings.TrimSpace(line)
			if line == "" || line[0] == '#' {
				continue
			}

			data.Servers = append(data.Servers, line)
		}
	} else {
		log.Println("    Read failed (this is most likely ok)\n    Error:", err)
	}

	log.Println("  Loading Addons From Local Directories...")

	loadGlobals(fs, data, nil, nil, "addons")
	pmeta := loadMeta(fs, "", "addons", nil)

	for _, dir := range fs.ListDirs("addons") {
		loadDir(fs, data, dir, "addons/"+dir, nil, nil, pmeta)
	}

	log.Println("  Loading Addons From Globally Requested Addon Packs...")

	for _, pack := range global.Dependencies {
		loadPack(fs, log, data, pack, fs.Exists("addons/"+pack+".zip"))
	}

	log.Println("  Loading Addons From Addon Packs...")

	for _, filename := range fs.ListFiles("addons") {
		if strings.HasSuffix(filename, ".zip") {
			name := rblutil.StripExt(filename)
			loadPack(fs, log, data, name, true)
		}
	}

	log.Println("  Checking Loaded Data...")

	// Sort the addon list
	sort.Sort(addonSorter(data.List))

	// Add global files from addons
	data.Globals.UpdateGlobals(data.List)

	// Fill in extra fields.
	for _, addon := range data.List {
		data.Table[addon.Meta.Name] = addon
		data.Meta[addon.Meta.Name] = addon.Meta
		if addon.Meta.Tags["DocPack"] {
			data.DocPacks = append(data.DocPacks, addon.Meta)
		}
	}

	// Find any duplicates.
	dups := map[string]bool{}
	for i := range data.List {
		if dups[data.List[i].Meta.Name] {
			errors.RaiseError("    Duplicate addon found: \"" + data.List[i].Meta.Name + "\"")
		}
		dups[data.List[i].Meta.Name] = true
	}
	return data, nil
}

func downloadPack(fs *axis2.FileSystem, data *Database, name string, meta *PackMeta, ds axis2.DataSource, log rblutil.Logger) (*PackMeta, axis2.DataSource) {
	if data.updateBlacklist[name] {
		log.Print("        This pack is on the update blacklist.")
		if meta != nil {
			log.Println(" Using local copy.")
		} else {
			log.Println(" Ignoring.")
		}
		return meta, ds
	}

	log.Println("        Querying content servers...")

	url := ""
	for _, server := range data.Servers {
		info := LookupContentServerPack(server, name)
		if info == nil {
			continue
		}

		if meta != nil {
			log.Println("          Found candidate, checking versions...")
			if info.VerMajor == meta.VerMajor {
				if info.VerMinor == meta.VerMinor {
					if info.VerPatch == meta.VerPatch {
						log.Println("            Local copy matches remote copy.")
						return meta, ds
					} else if info.VerPatch < meta.VerPatch {
						log.Println("            Local copy is newer than remote copy.")
						return meta, ds
					}
				} else if info.VerMinor < meta.VerMinor {
					log.Println("            Local copy is newer than remote copy.")
					return meta, ds
				}
			} else if info.VerMajor < meta.VerMajor {
				log.Println("            Local copy is newer than remote copy.")
				return meta, ds
			}
		} else {
			log.Println("          Found candidate.")
		}
		url = info.URL
		break
	}
	if url == "" {
		log.Println("        Could not find URL for this pack on any content server.")

		if meta != nil && meta.DFFDID != -1 {
			log.Println("          A DFFD file ID is available, trying to use that.")
			info, err := dffd.Query(meta.DFFDID)
			if err != nil {
				log.Print("            Error getting information from DFFD.")
				if meta != nil {
					log.Println(" Using local copy.")
				} else {
					log.Println(" Ignoring this pack.")
				}
				return meta, ds
			}

			log.Println("            Got information, trying to match versions...")
			if info.VerMajor == meta.VerMajor {
				if info.VerMinor == meta.VerMinor {
					if info.VerPatch == meta.VerPatch {
						log.Println("              Local copy matches remote copy.")
						return meta, ds
					} else if info.VerPatch < meta.VerPatch {
						log.Println("              Local copy is newer than remote copy.")
						return meta, ds
					}
				} else if info.VerMinor < meta.VerMinor {
					log.Println("              Local copy is newer than remote copy.")
					return meta, ds
				}
			} else if info.VerMajor < meta.VerMajor {
				log.Println("              Local copy is newer than remote copy.")
				return meta, ds
			}

			url = info.URL()
		} else {
			log.Print("          No DFFD file ID is available.")
			if meta != nil {
				log.Println(" Using local copy.")
			} else {
				log.Println(" Ignoring this pack.")
			}
			return meta, ds
		}
	}

	log.Println("          Downloading remote copy...")

	client := new(http.Client)
	r, err := client.Get(url)
	if err != nil {
		log.Print("            Error: ", err)
		if meta != nil {
			log.Println(" Using local copy.")
		} else {
			log.Println(" Ignoring this pack.")
		}
		return meta, ds
	}

	content, err := ioutil.ReadAll(r.Body)
	r.Body.Close()
	if err != nil {
		log.Print("            Error:", err)
		if meta != nil {
			log.Println(" Using local copy.")
		} else {
			log.Println(" Ignoring this pack.")
		}
		return meta, ds
	}

	nds, err := zip.NewRawDir(content)
	if err != nil {
		log.Print("            Error:", err)
		if meta != nil {
			log.Println(" Using local copy.")
		} else {
			log.Println(" Ignoring this pack.")
		}
		return meta, ds
	}

	fs.Mount("loader/pack", nds, false)
	nmeta := loadPackMeta(fs, "loader/pack")
	fs.Unmount("loader/pack", true)

	if nmeta.Name == "" {
		nmeta.Name = name
	}

	if nmeta.Name != name {
		if meta == nil {
			errors.RaiseError("Pack name mismatch error, the name in the requesting pack's pack.meta key does not match the canonical pack name")
		} else {
			errors.RaiseError("Pack name mismatch error, the local addon pack file does not match the canonical pack name")
		}
	}

	// Make sure the old version is gone (it may not be in the write directory).
	fs.Delete("addons/" + nmeta.Name + ".zip")

	err = fs.WriteAll("addons/"+nmeta.Name+".zip", content)
	if err != nil {
		log.Print("            Error saving downloaded file: ", err)
		if meta != nil {
			log.Println(" Using local copy.")
		} else {
			log.Println(" Ignoring this pack.")
		}
		return meta, ds
	}
	return nmeta, nds
}

// LoadPackLate injects an addon pack into the existing data base.
func LoadPackLate(fs *axis2.FileSystem, log rblutil.Logger, data *Database, name string) {
	log.Println("    Loading Pack:", name)
	log.Println("      No local file, trying to download...")
	meta, ds := downloadPack(fs, data, name, nil, nil, log)
	if meta == nil {
		return
	}

	if meta.Name != "" && meta.Name != name {
		errors.RaiseError("Pack name mismatch error, the requested pack name does not match the canonical pack name")
	}

	log.Println("      Checking versions...")
	if meta.MatchVersions(&HostVersions{
		DFMajor: rblutil.DFVMajor,
		DFPatch: rblutil.DFVMinor,

		RblRewrite: rblutil.VMajor,
		RblMajor:   rblutil.VMinor,
		RblPatch:   rblutil.VPatch,
	}) {
		log.Println("        OK!")
		log.Println("        Loading...")
	} else {
		log.Println("        This pack is not compatible with the local DF and/or Rubble version!")
		log.Println("        Skipping.")
		return
	}

	fs.Mount("addonpacks/"+name, ds, false)
	data.Writers = append(data.Writers, meta.Writers...)
	loadDir(fs, data, name, "addonpacks/"+name, meta.TagsFirst, meta.TagsLast, nil)

	meta.Name = name
	data.Packs[name] = meta

	for _, pack := range meta.Dependencies {
		loadPack(fs, log, data, pack, fs.Exists("addons/"+name+".zip"))
	}
}

func loadPack(fs *axis2.FileSystem, log rblutil.Logger, data *Database, name string, hasZip bool) {
	var ds axis2.DataSource
	var meta *PackMeta

	if fs.Exists("addonpacks/" + name) {
		// Already loaded.
		return
	}

	log.Println("    Loading Pack:", name)

	if hasZip {
		content, err := fs.ReadAll("addons/" + name + ".zip")
		if err != nil {
			errors.RaiseWrappedError("While reading zip file:", err)
		}

		ds, err = zip.NewRawDir(content)
		if err != nil {
			errors.RaiseWrappedError("While reading zip file:", err)
		}

		fs.Mount("loader/pack", ds, false)
		meta = loadPackMeta(fs, "loader/pack")
		fs.Unmount("loader/pack", true)

		log.Println("      Trying to find update...")
		meta, ds = downloadPack(fs, data, name, meta, ds, log)

	} else {
		log.Println("      No local file, trying to download...")
		meta, ds = downloadPack(fs, data, name, nil, nil, log)
		if meta == nil {
			return
		}
	}

	if meta.Name != "" && meta.Name != name {
		errors.RaiseError("Pack name mismatch error, the local addon pack file does not match the canonical pack name")
	}

	log.Println("      Checking versions...")
	if meta.MatchVersions(&HostVersions{
		DFMajor: rblutil.DFVMajor,
		DFPatch: rblutil.DFVMinor,

		RblRewrite: rblutil.VMajor,
		RblMajor:   rblutil.VMinor,
		RblPatch:   rblutil.VPatch,
	}) {
		log.Println("        OK!")
		log.Println("        Loading...")
	} else {
		log.Println("        This pack is not compatible with the local DF and/or Rubble version!")
		log.Println("        Skipping.")
		return
	}

	fs.Mount("addonpacks/"+name, ds, false)
	data.Writers = append(data.Writers, meta.Writers...)
	loadDir(fs, data, name, "addonpacks/"+name, meta.TagsFirst, meta.TagsLast, nil)

	meta.Name = name
	data.Packs[name] = meta

	for _, pack := range meta.Dependencies {
		loadPack(fs, log, data, pack, fs.Exists("addons/"+name+".zip"))
	}
}

func loadDir(fs *axis2.FileSystem, data *Database, addonname, path string, f, l map[string][]string, pmeta *Meta) {
	dirpath := path
	if path != "" {
		path += "/"
	}

	if containsParseable(fs, data, f, l, dirpath) {
		pmeta = loadAddon(fs, data, addonname, dirpath, f, l, pmeta)
		if pmeta.Tags["FileBank"] {
			data.Banks[pmeta.Name] = dirpath
			ds, err := fs.GetDSAt(dirpath, false, true)
			if err != nil {
				panic(err) // Should never happen
			}
			fs.Mount("banks/"+pmeta.Name, ds, false)
			return
		}
	} else {
		loadGlobals(fs, data, f, l, dirpath)
		pmeta = loadMeta(fs, addonname, dirpath, pmeta)
		if pmeta.Tags["FileBank"] {
			data.Banks[pmeta.Name] = dirpath
			ds, err := fs.GetDSAt(dirpath, false, true)
			if err != nil {
				panic(err) // Should never happen
			}
			fs.Mount("banks/"+pmeta.Name, ds, false)
			return
		}
	}

	for _, dir := range fs.ListDirs(dirpath) {
		name := ""
		if pmeta.Name == "-" {
			name = dir
		} else {
			name = pmeta.Name + "/" + dir
		}

		loadDir(fs, data, name, path+dir, f, l, pmeta)
	}
}

// Allow comments in JSON.
var killMetaComments = regexp.MustCompile("\n[\t ]*#[^\n]*")

func loadPackMeta(fs *axis2.FileSystem, path string) *PackMeta {
	meta := NewPackMeta()

	content, err := fs.ReadAll(path + "/pack.meta")
	if err == nil {
		err := json.Unmarshal(killMetaComments.ReplaceAllLiteral(content, []byte("\n")), meta)
		if err != nil {
			errors.RaiseWrappedError("While loading pack.meta", err)
		}
	}
	return meta
}

func loadMeta(fs *axis2.FileSystem, addonname, path string, pmeta *Meta) *Meta {
	if path != "" {
		path += "/"
	}

	meta := NewMeta()

	content, err := fs.ReadAll(path + "addon.meta")
	if err == nil {
		meta.Header = template.HTML("")

		err := json.Unmarshal(killMetaComments.ReplaceAllLiteral(content, []byte("\n")), meta)
		if err != nil {
			errors.RaiseWrappedError("While loading \""+path+"addon.meta\"", err)
		}

		// Make sure the header and description are ready to inject HTML.
		meta.Header = rblutil.MarkdownLineToHTML(string(meta.Header))
		if meta.DescFile != "" {
			content, err := fs.ReadAll(path + meta.DescFile)
			if err != nil {
				errors.RaiseWrappedError("While loading description file \""+path+meta.DescFile+"\"", err)
			}

			ext := rblutil.GetExt(meta.DescFile)
			switch ext {
			case ".md", ".text":
				meta.Description = rblutil.MarkdownToHTML(string(content))
			case ".htm", ".html":
				meta.Description = template.HTML(content)
			default:
				meta.Description = template.HTML(`<pre>` + html.EscapeString(string(content)) + `</pre>`)
			}
		} else {
			meta.Description = rblutil.MarkdownToHTML(string(meta.Description))
		}

		// Handle the addon name.
		if meta.Name == "" {
			meta.Name = addonname
		} else if meta.Name != "-" {
			if len(meta.Name) > 2 && meta.Name[0] == '$' {
				if pmeta == nil || pmeta.Name == "-" {
					meta.Name = meta.Name[2:]
				} else {
					meta.Name = pmeta.Name + meta.Name[1:]
				}
			}
		}

	} else {
		// NewMeta sets most needed defaults already.
		meta.Name = addonname
	}

	// Load priority inheritance
	if meta.LoadPriority < 0 {
		if pmeta == nil {
			meta.LoadPriority = -meta.LoadPriority
		} else {
			meta.LoadPriority = pmeta.LoadPriority
		}
	}

	// Author inheritance
	if meta.Author == " " {
		if pmeta == nil {
			meta.Author = ""
		} else {
			meta.Author = pmeta.Author
		}
	}

	// Version inheritance
	if meta.Version == " " {
		if pmeta == nil {
			meta.Version = ""
		} else {
			meta.Version = pmeta.Version
		}
	}

	return meta
}

func loadAddon(fs *axis2.FileSystem, data *Database, addonname, path string, f, l map[string][]string, pmeta *Meta) *Meta {
	addon := NewAddon(addonname, path)

	dirpath := path
	if path != "" {
		path += "/"
	}

	// Load Meta File
	addon.Meta = loadMeta(fs, addonname, dirpath, pmeta)
	if addon.Meta.Tags["FileBank"] {
		return addon.Meta
	}

	// Load Files
	for _, filepath := range fs.ListFiles(dirpath) {
		content, err := fs.ReadAll(path + filepath)
		if err != nil {
			panic(err)
		}

		file := NewFile(filepath, dirpath, content)
		tags := GetFileTags(f, l, data.tagsFirst, data.tagsLast, filepath)
		for _, tag := range tags {
			file.Tags[tag] = true
		}

		if file.Tags["TemplateTest"] {
			addon.Meta.Tags["HasTests"] = true
		}
		if file.Tags["TileSet"] {
			addon.Meta.Tags["TileSet"] = true
		}
		if file.Tags["DFHack"] {
			if _, ok := addon.Meta.Tags["DFHack"]; !ok {
				addon.Meta.Tags["DFHack"] = true
			}
		}
		addon.Files[filepath] = file
	}

	data.List = append(data.List, addon)
	return addon.Meta
}

func loadGlobals(fs *axis2.FileSystem, data *Database, f, l map[string][]string, path string) {
	dirpath := path
	if path != "" {
		path += "/"
	}

	for _, filepath := range fs.ListFiles(dirpath) {
		tags := GetFileTags(f, l, data.tagsFirst, data.tagsLast, filepath)
		for _, tag := range tags {
			if tag == "GlobalFile" {
				content, err := fs.ReadAll(path + filepath)
				if err != nil {
					panic(err)
				}

				data.Globals.Data[filepath] = NewFile(filepath, dirpath, content)
				data.Globals.Order = append(data.Globals.Order, filepath)
				for _, t := range tags {
					data.Globals.Data[filepath].Tags[t] = true
				}
				break
			}
		}
	}
	// Don't bother sorting the list here, it will be done later.
	return
}

func containsParseable(fs *axis2.FileSystem, data *Database, f, l map[string][]string, path string) bool {
	for _, filename := range fs.ListFiles(path) {
		tags := GetFileTags(f, l, data.tagsFirst, data.tagsLast, filename)
		if len(tags) > 0 {
			global := false
			for _, tag := range tags {
				if tag == "GlobalFile" {
					global = true
					break
				}
			}
			if !global {
				return true
			}
		}
	}
	return false
}

type addonSorter []*Addon

func (a addonSorter) Len() int {
	return len(a)
}

// This function is what determines the "load order".
func (a addonSorter) Less(i, j int) bool {
	if a[i].Meta.LoadPriority == a[j].Meta.LoadPriority {
		return strings.ToLower(a[i].Meta.Name) < strings.ToLower(a[j].Meta.Name)
	}
	return a[i].Meta.LoadPriority < a[j].Meta.LoadPriority
}

func (a addonSorter) Swap(i, j int) {
	a[i], a[j] = a[j], a[i]
}
