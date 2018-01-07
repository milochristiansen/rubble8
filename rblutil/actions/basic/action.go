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

// Import this package to install all the default operation modes.
package basic

import "rubble8"
import "rubble8/rblutil"
import "rubble8/rblutil/actions"
import "rubble8/rblutil/addon"

func init() {
actions.RegisterFunc("generate", func(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool {
	addons, config := *options[0].(*rblutil.ArgList), *options[1].(*rblutil.ArgList)
	
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

	err = state.Run(addons, config)
	if err != nil {
		log.Println(err)
		return false
	}
	log.Println("Done.")
	return true
}, "Runs a standard generation cycle.", []actions.Option{
	{
		Name: "addons",
		Help: "List of addons to load. This is optional. If the value is a file path\n\tthen the file is read as an ini file containing addon activation\n\tinformation. May be specified more than once. If this is not specified\n\tit defaults to \"addons/addonlist.ini\".",
		Flag: false,
		Multiple: true,
	},
	{
		Name: "config",
		Help: "List of config variables. This is optional. If the value is a file path\n\tthen the file is read as an ini file containing config variables. May\n\tbe specified more than once.",
		Flag: false,
		Multiple: true,
	},
})

actions.RegisterFunc("refresh", func(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool {
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

	err = state.Activate(nil, nil)
	if err != nil {
		log.Println(err)
		return false
	}

	log.Println("  Updating the Default Addon List File...")
	err = state.UpdateAddonList("addons/addonlist.ini")
	if err != nil {
		log.Println(err)
		return false
	}
	log.Println("Done.")
	return true
}, "Update the standard addon list file and exit.", []actions.Option{})

actions.RegisterFunc("iapply", func(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool {
	addons, region := *options[0].(*rblutil.ArgList), *options[1].(*string)
	
	fs := rubble8.InitAXIS(rblDir, dfDir, outDir, addonDirs)
	data, err := addon.Load(fs, log)
	if err != nil {
		log.Println(err)
		return false
	}
	
	err = rubble8.IAModeRun(region, dfDir, addons, data, fs, log)
		if err != nil {
			log.Println(err)
			return false
		}
		log.Println("Done.")
		return true
}, "Run independent apply mode.", []actions.Option{
	{
		Name: "addons",
		Help: "List of addons to load. This is optional. If the value is a file path\n\tthen the file is read as an ini file containing addon activation\n\tinformation. May be specified more than once. If this is not specified\n\tit defaults to \"addons/addonlist.ini\".",
		Flag: false,
		Multiple: true,
	},
	{
		Name: "region",
		Help: "The region to apply the addon(s) to.\n\tUse 'raw' to specify the main raw directory.",
		DS: "raw",
		Flag: false,
		Multiple: false,
	},
})

actions.RegisterFunc("tset", func(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool {
	addons, region := *options[0].(*rblutil.ArgList), *options[1].(*string)
	
	fs := rubble8.InitAXIS(rblDir, dfDir, outDir, addonDirs)
	data, err := addon.Load(fs, log)
	if err != nil {
		log.Println(err)
		return false
	}
	
	err = rubble8.TSetModeRun(region, dfDir, addons, data, fs, log)
		if err != nil {
			log.Println(err)
			return false
		}
		log.Println("Done.")
		return true
}, "Run tileset apply mode.", []actions.Option{
	{
		Name: "addons",
		Help: "List of addons to load. This is optional. If the value is a file path\n\tthen the file is read as an ini file containing addon activation\n\tinformation. May be specified more than once. If this is not specified\n\tit defaults to \"addons/addonlist.ini\".",
		Flag: false,
		Multiple: true,
	},
	{
		Name: "region",
		Help: "The region to apply the tileset to. Use 'raw' to specify the main raw\n\tdirectory.",
		DS: "raw",
		Flag: false,
		Multiple: false,
	},
})
}
