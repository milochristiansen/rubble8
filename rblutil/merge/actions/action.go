/*
Copyright 2014-2018 by Milo Christiansen

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

// Import this package to install a raw merger operation mode.
package actions

import "github.com/milochristiansen/rubble8"
import "github.com/milochristiansen/rubble8/rblutil"
import "github.com/milochristiansen/rubble8/rblutil/merge"
import "github.com/milochristiansen/rubble8/rblutil/rparse"
import "github.com/milochristiansen/rubble8/rblutil/actions"

func init() {
	actions.RegisterFunc("merge", func(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool {
		inFile, outFile, ruleFile, sourceFile := *options[0].(*string), *options[1].(*string), *options[2].(*string), *options[3].(*string)

		log.Println("Running Merge:")
		log.Println("  Initializing AXIS VFS...")
		fs := rubble8.InitAXIS(rblDir, dfDir, outDir, addonDirs)

		log.Println("  Loading Rules File...")
		rsource, err := fs.ReadAll(ruleFile)
		if err != nil {
			log.Println(err)
			return false
		}
		rules := new(merge.RuleNode)
		err = merge.ParseRules(rsource, rules)
		if err != nil {
			log.Println(err)
			return false
		}

		log.Println("  Loading Source Raws...")
		srcraws, err := fs.ReadAll(sourceFile)
		if err != nil {
			log.Println(err)
			return false
		}
		set := new(merge.TagNode)
		merge.PopulateTree(rparse.ParseRaws(srcraws), set, rules)

		log.Println("  Loading Input...")
		in, err := fs.ReadAll(inFile)
		if err != nil {
			log.Println(err)
			return false
		}

		log.Println("  Applying...")
		tags := rparse.ParseRaws(in)
		merge.Apply(tags, set)
		in = rparse.FormatFile(tags)

		log.Println("  Writing Result...")
		err = fs.WriteAll(outFile, in)
		if err != nil {
			log.Println(err)
			return false
		}

		log.Println("Done.")
		return true
	}, "Merge the raws in the input file with the raws in the merge source using the specified rules.\nThe result is written to the output file.", []actions.Option{
		{
			Name:     "raws",
			Help:     "The `file` containing the raws to merge the source into.",
			Flag:     false,
			Multiple: false,
		},
		{
			Name:     "out",
			Help:     "The output `file`.",
			Flag:     false,
			Multiple: false,
		},
		{
			Name:     "rules",
			Help:     "The rule `file`.",
			Flag:     false,
			Multiple: false,
		},
		{
			Name:     "source",
			Help:     "The `file` containing the raws to use as the merge source.",
			Flag:     false,
			Multiple: false,
		},
	})
}
