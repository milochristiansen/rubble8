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

// The web UI interface action.
package webui

import "net/http"
import "mime"

import "os"
import "fmt"
import "time"
import "strings"
import "strconv"

import "image"
import "image/png"

import "html"
import "html/template"

import "rubble8"
import "rubble8/rblutil"
import "rubble8/rblutil/actions"
import "rubble8/rblutil/rparse"
import "rubble8/rblutil/brender"
import "rubble8/rblutil/addon"

type preset struct {
	Name string
	Addons []string
}

func init() {
actions.RegisterFunc("web", func(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool {
	addr := *options[0].(*string)
	
	fs := rubble8.InitAXIS(rblDir, dfDir, outDir, addonDirs)
	data, err := addon.Load(fs, log)
	if err != nil {
		log.Println(err)
		return false
	}
	err, state := rubble8.NewState(data, fs, log)
	if err != nil {
		log.Println(err)
		return false
	}

	tmpl, err := LoadHTMLTemplates(state.FS)
	if err != nil {
		log.Println(err)
		return false
	}

	// Note: http.Redirect acts "funny" when you use http.StatusInternalServerError,
	// so I use http.StatusFound even for error-triggered redirects to the log page.
	// (this may just be my browser, but better safe than sorry)

	// Main menu
	http.HandleFunc("/menu", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/menu\"")

		var err error
		err, state = rubble8.NewState(data, fs, log)
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}

		err = tmpl.ExecuteTemplate(w, "menu", state)
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
	})

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Println("Redirecting:", r.URL, "to main menu.")

		http.Redirect(w, r, "./menu", http.StatusFound)
	})

	// Addon List

	http.HandleFunc("/addons", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/addons\"")

		err = tmpl.ExecuteTemplate(w, "addons", state)
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
	})

	// Content server

	http.HandleFunc("/srvrpacks", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/srvrpacks\"")

		if len(data.Servers) == 0 {
			log.Println("Error: No content servers known.")
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
		
		have := map[string]bool{}
		packs := map[string]*addon.PackMeta{}
		
		for _, addr := range data.Servers {
			rcode, rtn, err := addon.ContactContentServer(addr, "List", "", "", "", "", nil)
			if rcode != "OK" || err != nil {
				continue
			}
			list := rtn.(map[string]*addon.PackMeta)
			
			// Prefer first found (since that is the one the loader will find).
			for k, v := range list {
				if _, ok := packs[k]; !ok {
					packs[k] = v
					have[k] = state.FS.Exists("addonpacks/"+k)
				}
			}
		}
		
		err = tmpl.ExecuteTemplate(w, "srvrpacks", struct {
			Packs map[string]*addon.PackMeta
			Have  map[string]bool
		}{packs, have})
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
	})

	http.HandleFunc("/srvrpacks_down", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/srvrpacks_down\"")

		log.Println("  Downloading Requested Addon Packs...")
		
		r.ParseForm() // Yes, I am ignoring the error. Because I feel like it, that's why.
		
		for name := range r.Form {
			if !state.FS.Exists("addonpacks/"+name) {
				addon.LoadPackLate(fs, log, data, name)
			}
		}
		
		http.Redirect(w, r, "/log?header=true", http.StatusFound)
	})

	// Normal Generation
	
	http.HandleFunc("/genaddons", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/genaddons\"")

		log.Println("  Loading Presets...")
		presets := []preset{
			{
				Name: "Default",
			},
		}
		
		file, err := state.FS.ReadAll("addons/addonlist.ini")
		if err == nil {
			rblutil.ParseINI(string(file), "\n", func(key, value string) {
				value = strings.ToLower(value)
				if ok, _ := strconv.ParseBool(value); ok {
					state.Active[key] = true
				}
			})
		}
		for _, addon := range state.Addons.List {
			if state.Active[addon.Meta.Name] && !addon.Meta.Tags["Library"] && !addon.Meta.Tags["DocPack"] && !addon.Meta.Tags["NotNormal"] {
				presets[0].Addons = append(presets[0].Addons, addon.Meta.Name)
			}
		}
		
		for _, filename := range state.FS.ListFiles("rubble/presets") {
			if strings.HasSuffix(filename, ".ini") {
				preset := &preset{
					Name: strings.TrimSuffix(filename, ".ini"),
				}
				if preset.Name == "Default" {
					log.Println("    Found preset file with reserved name: \"Default\" Skipping.")
					continue
				}
				file, err := state.FS.ReadAll("rubble/presets/"+filename)
				if err != nil {
					log.Println("    Found preset file: \""+filename+"\" but read failed:", err)
					continue
				}
				rblutil.ParseINI(string(file), "\n", func(key, value string) {
					value = strings.ToLower(value)
					if ok, _ := strconv.ParseBool(value); ok {
						preset.Addons = append(preset.Addons, key)
					}
				})
				presets = append(presets, *preset)
			}
		}
		
		vals := state.VarDefaults(nil)
		
		err = tmpl.ExecuteTemplate(w, "genaddons", struct {
			State       *rubble8.State
			Presets     []preset
			VarDefaults map[string]string
		}{state, presets, vals})
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
	})

	//http.HandleFunc("/genvars", func(w http.ResponseWriter, r *http.Request) {
	//	log.Println("UI Transition: \"/genvars\"")
    //
	//	addons := []string{}
	//	for name, ok := range state.Active {
	//		if ok {
	//			addons = append(addons, name)
	//		}
	//	}
    //
	//	// This makes sure all addons are in the correct state, even though the non-library addons are more or
	//	// less correct there is a lot more to activation than just that.
	//	err = state.Activate(addons, nil)
	//	if err != nil {
	//		log.Println(err)
	//		http.Redirect(w, r, "/log?state=error", http.StatusFound)
	//		return
	//	}
    //
	//	// If the user elected to skip selecting config vars, go straight to generation after activation.
	//	if r.FormValue("hidden") != "" {
	//		http.Redirect(w, r, "/pleasewait?to=/genrun", http.StatusFound)
	//		return
	//	}
    //
	//	vars := make(map[string]*addon.MetaVar)
	//	vals := make(map[string]string)
	//	for _, addon := range state.Addons.List {
	//		if !state.Active[addon.Meta.Name] {
	//			continue
	//		}
    //
	//		for i := range addon.Meta.Vars {
	//			vars[i] = addon.Meta.Vars[i]
	//			vdata, ok := state.VariableData[i]
	//			if ok {
	//				vals[i] = vdata
	//			} else if len(vars[i].Values[0]) > 0 {
	//				vals[i] = vars[i].Values[0]
	//			}
	//		}
	//	}
    //
	//	err = tmpl.ExecuteTemplate(w, "genvars", struct {
	//		Vars map[string]*addon.MetaVar
	//		Vals map[string]string
	//	}{vars, vals})
	//	if err != nil {
	//		log.Println(err)
	//		http.Redirect(w, r, "/log?state=error", http.StatusFound)
	//		return
	//	}
	//})
	
	http.HandleFunc("/genrun", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/genrun\"")

		addons := []string{}
		for name, ok := range state.Active {
			if ok {
				addons = append(addons, name)
			}
		}
		
		timeStart := time.Now()
		err := state.Run(addons, nil)
		log.Println("Run time: ", time.Since(timeStart))
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
		log.Println("Done.")
		
		if log.WarnCount() > 0 {
			http.Redirect(w, r, "/log?state=warn", http.StatusFound)
			return
		}
		
		http.Redirect(w, r, "/log?header=true", http.StatusFound)
	})

	// Tileset

	http.HandleFunc("/tsetaddons", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/tsetaddons\"")

		regions := state.FS.ListDirs("df/data/save")
		for i := range regions {
			if regions[i] == "current" {
				regions = append(regions[:i], regions[i+1:]...)
				break
			}
		}

		for _, addon := range state.Addons.List {
			if !addon.Meta.Tags["TileSet"] {
				delete(state.Active, addon.Meta.Name)
			}
		}
		
		vals := state.VarDefaults(nil)
		
		state.VariableData["_RUBBLE_IA_REGION_"] = ""

		err = tmpl.ExecuteTemplate(w, "iaaddons", struct {
			Regions     []string
			State       *rubble8.State
			Tag         string
			URL         string
			Back_URL    string
			Name        string
			VarDefaults map[string]string
		}{regions, state, "TileSet", "/tsetrun", "/tsetaddons", "Tileset Application", vals})
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
	})

	http.HandleFunc("/tsetrun", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/tsetrun\"")

		region := state.VariableData["_RUBBLE_IA_REGION_"]
		if region == "" {
			region = "raw"
		}

		addons := []string{}
		for name, ok := range state.Active {
			if ok {
				addons = append(addons, name)
			}
		}

		timeStart := time.Now()
		err = rubble8.TSetModeRun(region, dfDir, addons, data, fs, log)
		log.Println("Run time: ", time.Since(timeStart))
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
		log.Println("Done.")
		
		if log.WarnCount() > 0 {
			http.Redirect(w, r, "/log?state=warn", http.StatusFound)
			return
		}
		
		http.Redirect(w, r, "/log?header=true", http.StatusFound)
	})

	// Independent Apply

	http.HandleFunc("/iaaddons", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/iaaddons\"")

		regions := state.FS.ListDirs("df/data/save")
		for i := range regions {
			if regions[i] == "current" {
				regions = append(regions[:i], regions[i+1:]...)
				break
			}
		}

		for _, addon := range state.Addons.List {
			if !addon.Meta.Tags["SaveSafe"] {
				delete(state.Active, addon.Meta.Name)
			}
		}
		
		vals := state.VarDefaults(nil)

		state.VariableData["_RUBBLE_IA_REGION_"] = ""

		err = tmpl.ExecuteTemplate(w, "iaaddons", struct {
			Regions     []string
			State       *rubble8.State
			Tag         string
			URL         string
			Back_URL    string
			Name        string
			VarDefaults map[string]string
		}{regions, state, "SaveSafe", "/iarun", "/iaaddons", "Independent Application", vals})
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
	})

	http.HandleFunc("/iarun", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/iarun\"")

		region := state.VariableData["_RUBBLE_IA_REGION_"]
		if region == "" {
			region = "raw"
		}

		addons := []string{}
		for name, ok := range state.Active {
			if ok {
				addons = append(addons, name)
			}
		}

		timeStart := time.Now()
		err = rubble8.IAModeRun(region, dfDir, addons, data, fs, log)
		log.Println("Run time: ", time.Since(timeStart))
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
		log.Println("Done.")
		
		if log.WarnCount() > 0 {
			http.Redirect(w, r, "/log?state=warn", http.StatusFound)
			return
		}
		
		http.Redirect(w, r, "/log?header=true", http.StatusFound)
	})

	// Common

	// Toggle an addon's activation state.
	http.HandleFunc("/toggle", func(w http.ResponseWriter, r *http.Request) {
		addon := r.FormValue("addon")
		log.Println("Toggling addon: \""+addon+"\" to", r.FormValue("state"))

		if _, ok := state.Addons.Table[addon]; !ok {
			w.WriteHeader(http.StatusInternalServerError)
			log.Println("Attempt to toggle non-existent addon: " + addon)
			return
		}
		state.Active[addon] = r.FormValue("state") == "true"

		w.WriteHeader(http.StatusOK)
	})

	// Set a configuration variable.
	http.HandleFunc("/setvar", func(w http.ResponseWriter, r *http.Request) {
		vname := r.FormValue("key")
		log.Println("Setting variable: \""+vname+"\" to", r.FormValue("val"))

		state.VariableData[vname] = r.FormValue("val")

		w.WriteHeader(http.StatusOK)
	})

	http.HandleFunc("/pleasewait", func(w http.ResponseWriter, r *http.Request) {
		err = tmpl.ExecuteTemplate(w, "pleasewait", r.FormValue("to"))
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
	})

	http.HandleFunc("/log", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/log\"")
		es := r.FormValue("state")
		header := r.FormValue("header") != "" || es != ""
		err = tmpl.ExecuteTemplate(w, "log", struct {
			State  string
			Header bool
			Log    string
		}{es, header, string(log.LogBuffer())})
		if err != nil {
			http.Error(w, err.Error(), http.StatusFound)
		}
	})

	http.HandleFunc("/addondata", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/addondata\"")

		addref, ok := state.Addons.Table[r.FormValue("addon")]
		if !ok {
			log.Println("Error: Invalid addon name in query.")
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}

		url := r.FormValue("from")
		if url == "" {
			url = "/addons"
		}
		name := r.FormValue("fromname")
		if name == "" {
			name = "Addon List"
		}

		err = tmpl.ExecuteTemplate(w, "addondata", struct {
			Addon    *addon.Addon
			FromUrl  string
			FromName string
		}{addref, url, name})
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
	})

	http.HandleFunc("/favicon.ico", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "image/ico")
		fmt.Fprint(w, ico)
	})

	http.HandleFunc("/axis", func(w http.ResponseWriter, r *http.Request) {
		path := r.FormValue("path")
		log.Println("AXIS file request:", path)

		typ := mime.TypeByExtension(rblutil.GetExt(path))
		
		content, err := state.FS.ReadAll(path)
		if err != nil {
			log.Println("AXIS error (non-fatal):", err)
			http.Error(w, "AXIS error: "+err.Error(), http.StatusNotFound)
			return
		}
		
		if typ != "" {
			w.Header().Set("Content-Type", typ)
		}
		fmt.Fprintf(w, "%s", content)
	})

	http.HandleFunc("/axis/", func(w http.ResponseWriter, r *http.Request) {
		path := strings.TrimPrefix(r.URL.Path, "/axis/")
		log.Println("AXIS file request:", path)

		typ := mime.TypeByExtension(rblutil.GetExt(path))
		
		content, err := state.FS.ReadAll(path)
		if err != nil {
			log.Println("AXIS error (non-fatal):", err)
			http.Error(w, "AXIS error: "+err.Error(), http.StatusNotFound)
			return
		}
		
		if typ != "" {
			w.Header().Set("Content-Type", typ)
		}
		fmt.Fprintf(w, "%s", content)
	})

	addonFile := func(fn, an string, w http.ResponseWriter, r *http.Request) {
		log.Println("Addon file request: Addon:", an, "File:", fn)

		addon, ok := state.Addons.Table[an]
		if !ok {
			log.Println("Nonexistent addon: \"" + an + "\".")
			http.Error(w, "Nonexistent addon: \""+an+"\".", http.StatusNotFound)
			return
		}

		file, ok := addon.Files[fn]
		if !ok {
			log.Println("Nonexistent file: \"" + fn + "\" in addon: \"" + an + "\".")
			http.Error(w, "Nonexistent file: \""+fn+"\" in addon: \""+an+"\".", http.StatusNotFound)
			return
		}

		fmt.Fprintf(w, "%s", file.Content)
	}
	
	http.HandleFunc("/addonfile", func(w http.ResponseWriter, r *http.Request) {
		addonFile(r.FormValue("file"), r.FormValue("addon"), w, r)
	})
	
	http.HandleFunc("/addonfile/", func(w http.ResponseWriter, r *http.Request) {
		addonFile(strings.TrimPrefix(r.URL.Path, "/addonfile/"), r.FormValue("addon"), w, r)
	})
	
	wshopImage := func(fn, an string, w http.ResponseWriter, r *http.Request) {
		log.Println("Rendering workshop:", r.FormValue("id"))

		addon, ok := state.Addons.Table[an]
		if !ok {
			log.Println("  Nonexistent addon: \"" + an + "\".")
			http.Error(w, "Nonexistent addon: \""+an+"\".", http.StatusNotFound)
			return
		}

		file, ok := addon.Files[fn]
		if !ok {
			log.Println("  Nonexistent file: \"" + fn + "\" in addon: \"" + an + "\".")
			http.Error(w, "Nonexistent file: \""+fn+"\" in addon: \""+an+"\".", http.StatusNotFound)
			return
		}

		raws := rparse.ParseRaws([]byte(brender.Fix(string(file.Content))))
		raws = brender.Isolate(r.FormValue("id"), raws)
		if len(raws) == 0 {
			log.Println("  Could not find building to render.")
			http.Error(w, "Could not find building to render.", http.StatusNotFound)
			return
		}

		wshop, err := brender.Parse(raws, 7, 0)
		if err != nil {
			log.Println("  Building parse error:", err)
			http.Error(w, "Building parse error: "+err.Error(), http.StatusNotFound)
			return
		}

		stg, err := strconv.ParseInt(r.FormValue("stage"), 10, 8)
		if err != nil {
			stg = 3
		}

		tsetName := ""
		init := rparse.ParseRaws(state.Init)
		for _, tag := range init {
			if tag.ID == "GRAPHICS_FULLFONT" {
				tsetName = tag.Params[0]
				break
			}
		}
		if tsetName == "" {
			log.Println("  Could not find current tileset name.")
			http.Error(w, "Could not find current tileset name.", http.StatusNotFound)
			return
		}

		tset, err := state.FS.Read("df/data/art/"+tsetName)
		if err != nil {
			log.Println("  AXIS error (non-fatal):", err)
			http.Error(w, "AXIS error: "+err.Error(), http.StatusNotFound)
			return
		}
		defer tset.Close()

		tileset, _, err := image.Decode(tset)
		if err != nil {
			log.Println("  Image decode error:", err)
			http.Error(w, "Image decode error: "+err.Error(), http.StatusNotFound)
			return
		}

		img := brender.Render(wshop, int(stg), tileset)

		err = png.Encode(w, img)
		if err != nil {
			log.Println("  Image encode error:", err)
			//http.Error(w, "Image encode error: " + err.Error(), http.StatusNotFound)
			return
		}
	}
	
	http.HandleFunc("/wshop", func(w http.ResponseWriter, r *http.Request) {
		wshopImage(r.FormValue("file"), r.FormValue("addon"), w, r)
	})

	http.HandleFunc("/wshop/", func(w http.ResponseWriter, r *http.Request) {
		wshopImage(r.FormValue("file"), r.FormValue("addon"), w, r)
	})

	http.HandleFunc("/doclist", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/doclist\"")

		err := tmpl.ExecuteTemplate(w, "doclist", state.Addons.DocPacks)
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
	})

	http.HandleFunc("/doc/", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"" + r.URL.Path + "\"")

		from := r.FormValue("from")
		
		aname := r.FormValue("addon")
		fname := strings.TrimPrefix(r.URL.Path, "/doc/")

		var content []byte
		if aname != "" {
			addon, ok := state.Addons.Table[aname]
			if !ok {
				log.Println("Nonexistent addon: \"" + aname + "\".")
				http.Error(w, "Nonexistent addon: \""+aname+"\".", http.StatusNotFound)
				return
			}
			
			file, ok := addon.Files[fname]
			if !ok {
				log.Println("Nonexistent file: \"" + fname + "\" in addon: \"" + aname + "\".")
				http.Error(w, "Nonexistent file: \""+fname+"\" in addon: \""+aname+"\".", http.StatusNotFound)
				return
			}

			content = file.Content
		} else {
			var err error
			content, err = state.FS.ReadAll("rubble/other/"+fname)
			if err != nil {
				content, err = state.FS.ReadAll("addons/"+fname)
				if err != nil {
					content, err = state.FS.ReadAll("addonpacks/"+fname)
					if err != nil {
						log.Println("Doc file: " + fname + " not found.")
						http.Redirect(w, r, "/log?state=error", http.StatusFound)
						return
					}
				}
			}
		}

		ext := rblutil.GetExt(fname)
		var page template.HTML
		switch ext {
		case ".md", ".text":
			page = rblutil.MarkdownToHTML(string(content))
		case ".htm", ".html":
			page = template.HTML(content)
		default:
			page = template.HTML(`<pre>` + html.EscapeString(string(content)) + `</pre>`)
		}
		
		err := tmpl.ExecuteTemplate(w, "docpage", struct {
			From string
			Body template.HTML
		}{from, page})
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}
	})

	http.HandleFunc("/kill", func(w http.ResponseWriter, r *http.Request) {
		log.Println("UI Transition: \"/kill\"")

		err := tmpl.ExecuteTemplate(w, "kill", nil)
		if err != nil {
			log.Println(err)
			http.Redirect(w, r, "/log?state=error", http.StatusFound)
			return
		}

		d, _ := time.ParseDuration("1s")
		time.AfterFunc(d, func() { os.Exit(0) }) // HACK!
	})

	rblutil.LogSeparator(log)
	LaunchBrowser(log, rblDir, addr)

	log.Println("Starting Server...")
	err = http.ListenAndServe(addr, nil)
	if err != nil {
		log.Println("  Server Startup Failed:\n    Error:", err)
		return false
	}
	return true // Impossible?
}, "Run the web UI server.", []actions.Option{
	{
		Name: "addr",
		Help: "The `address` to serve the web UI at.",
		Flag: false,
		Multiple: false,
		
		DS: "127.0.0.1:2120",
	},
})
}

// isAbs returns true if the path is not a relative path (includes no "." or ".." parts).
func isAbs(path string) bool {
	dirs := strings.Split(path, "/")

	for i := range dirs {
		if dirs[i] == ".." || dirs[i] == "." {
			return false
		}
	}
	return true
}
