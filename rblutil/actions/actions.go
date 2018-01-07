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

// The actions registry for the universal interface.
package actions

import "github.com/milochristiansen/rubble8/rblutil"

import "flag"
import "os"
import "strings"
import "strconv"
import "io/ioutil"
import "regexp"

// Option is a command line option descriptor.
type Option struct {
	Name string
	Help string

	DS string // Default for string flags
	DB bool   // Default for bool flags.
	// []string flags have no defaults.

	// If true the result is a *bool, otherwise the result is a *string (or a *rblutil.ArgList (*[]string) if Multiple is true).
	Flag     bool
	Multiple bool // Ignored if Flag is true.
}

type ActionFunc func(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool

// This API is very specific to the universal interface, so it's OK to use globals for this kind of stuff.
var actions = map[string]Action{}
var optDefs = map[string][]Option{}
var modeHelp = map[string]string{}
var modes string

func commonOpt(f *flag.FlagSet, rblini map[string][]string, name, value, help string) interface{} {
	iniv, ok := rblini[name]
	if !ok || len(iniv) == 0 {
		return f.String(name, value, help)
	}
	return f.String(name, iniv[len(iniv)-1], help)
}

func makeFlags(mode string, rblini map[string][]string, log rblutil.Logger, hidecommon bool) (*flag.FlagSet, []interface{}, []interface{}) {
	def, ok := optDefs[mode]
	if !ok {
		return nil, nil, nil
	}

	f := flag.NewFlagSet(mode, flag.ExitOnError)
	options := make([]interface{}, len(def))
	f.SetOutput(log)

	for i, opt := range def {
		iniv, ok := rblini[opt.Name]
		if ok && len(iniv) == 0 {
			ok = false
		}
		if opt.Flag {
			d := opt.DB
			if ok {
				d, _ = strconv.ParseBool(iniv[len(iniv)-1])
			}
			options[i] = f.Bool(opt.Name, d, opt.Help)
			continue
		}
		if opt.Multiple {
			v := new(rblutil.ArgList)
			f.Var(v, opt.Name, opt.Help)
			if ok {
				for i := range iniv {
					v.Set(iniv[i])
				}
			}
			options[i] = v
			continue
		}
		d := opt.DS
		if ok {
			d = iniv[len(iniv)-1]
		}
		options[i] = f.String(opt.Name, d, opt.Help)
	}

	common := make([]interface{}, 0, 4)
	if !hidecommon {
		// Add the common options
		common = append(common, commonOpt(f, rblini, "rbldir", ".", "If you are seeing this it's an error!"))
		common = append(common, commonOpt(f, rblini, "dfdir", "..", "If you are seeing this it's an error!"))
		common = append(common, commonOpt(f, rblini, "outputdir", "df/raw", "If you are seeing this it's an error!"))
		v := new(rblutil.ArgList)
		common = append(common, v)
		f.Var(v, "addonsdir", "If you are seeing this it's an error!")
		iniv, ok := rblini["addonsdir"]
		if ok {
			for i := range iniv {
				v.Set(iniv[i])
			}
		}
		common = append(common, commonOpt(f, rblini, "dfver", "", "If you are seeing this it's an error!"))
	}

	f.Usage = func() {
		log.Println("Run \"rubble help\" for usage.")
	}

	return f, options, common
}

// Register an action with this API.
func Register(mode string, action Action, help string, options []Option) {
	actions[mode] = action
	modeHelp[mode] = help
	optDefs[mode] = options
	if modes != "" {
		modes += ", " + mode
		return
	}
	modes = mode
}

// Register an action function with this API. The passed in value is automatically wrapped.
func RegisterFunc(mode string, action ActionFunc, help string, options []Option) {
	Register(mode, funcWrapper(action), help, options)
}

// This includes usage for the common arguments. I do some real backflips to keep these out of the usage
// statements for individual modes so as not to clutter them.
var usage = `Usage:

  rubble mode [arguments]

The available modes are:

  %v

Run "rubble help [mode]" for more information about a mode.

Some shared options are available in all modes. These options are as follows:

  -addonsdir value
        Rubble addons directory. May be an AXIS path (only the 'rubble', 'df',
        and 'out' locations work). May be specified multiple times. If no
        values are specified this defaults to "rubble/addons".
  -dfdir string
        The path to the DF directory. May be an AXIS path (only the 'rubble'
        location works). (defaults to "..")
  -outputdir string
        Where should Rubble write the generated raw files? May be an AXIS path
        (only the 'rubble' and 'df' locations work). (defaults to "df/raw")
  -rbldir string
        The path to Rubble's directory. (defaults to ".")
  -dfver string
        The current DF version. Must be two integers, separated by a dot. If
        not provided this defaults to the value hardcoded into the Rubble
        engine. The current hardcoded version number is "%v.%v".
`

// Exec runs the action associated with the given mode. If the mode has no action then an error message will be
// printed to the log (listing the valid modes).
// This function will never return!
func Exec(mode string, args []string, log rblutil.Logger, rblini map[string][]string) {
	if mode == "help" {
		rblutil.LogSeparator(log)
		if len(args) == 0 {
			log.Printf(usage, modes, rblutil.DFVMajor, rblutil.DFVMinor)
			os.Exit(0)
		}
		help, ok := modeHelp[args[0]]
		if !ok {
			log.Println("Unknown mode \"" + args[0] + "\" passed to help.\nValid modes are: " + modes)
			os.Exit(0)
		}
		log.Println("Help for mode:", args[0])
		log.Println()
		log.Println(help)
		f, _, _ := makeFlags(args[0], rblini, log, true)
		// Horrid hack
		fc := 0
		f.VisitAll(func(fl *flag.Flag) {
			fc++
		})
		if fc != 0 {
			log.Println("\nOptions:\n")
			f.PrintDefaults()
		}
		log.Println("\nFor options common to all modes run \"rubble help\"")
		os.Exit(0)
	}

	f, options, common := makeFlags(mode, rblini, log, false)
	if f == nil {
		log.Println("Unknown mode, valid modes are: help, " + modes)
		os.Exit(3)
	}

	f.Parse(args) // os.Exit(2) on error

	rblDir := *common[0].(*string)
	dfDir := *common[1].(*string)
	outDir := *common[2].(*string)
	addonDirs := common[3].(*rblutil.ArgList)
	dfver := *common[4].(*string)
	if addonDirs.Empty() {
		addonDirs.Set("rubble/addons")
	}

	verok := false
	verman := false
	verauto := false

	verparts := strings.Split(dfver, ".")
	if len(verparts) == 2 {
		M, erra := strconv.Atoi(verparts[0])
		m, errb := strconv.Atoi(verparts[1])
		if erra == nil && errb == nil {
			verman = true
			rblutil.DFVMajor = M
			rblutil.DFVMinor = m
		} else {
			log.Println("-dfver option has invalid format. Both parts must be numeric like so: \"34.11\"")
			os.Exit(3)
		}
	} else if dfver != "" {
		log.Println("-dfver option has invalid format. Must have exactly two parts separated by a period like so: \"34.11\"")
		os.Exit(3)
	}

	// If we could do file IO at this point it would be possible to try to guess the DF version by reading
	// "df/release notes.txt" and looking for the first occurrence of "Release notes for 0.x.x"
	// Sadly AXIS is not available yet.

	// You know what? Screw it. We'll use traditional file IO.
	content, err := ioutil.ReadFile(rblutil.ReplacePrefix(dfDir, "rubble", rblDir) + "/release notes.txt")
	if err == nil {
		parts := regexp.MustCompile(`Release notes for 0.([0-9]+).([0-9]+)`).FindSubmatch(content)
		M, erra := strconv.Atoi(string(parts[1]))
		m, errb := strconv.Atoi(string(parts[2]))
		if erra == nil && errb == nil {
			verauto = true
			if rblutil.DFVMajor == M && rblutil.DFVMinor == m {
				verok = true
			} else if !verman {
				rblutil.DFVMajor = M
				rblutil.DFVMinor = m
			}
		}
	}

	log.Printf("  Current DF version: 0.%v.%v\n", rblutil.DFVMajor, rblutil.DFVMinor)
	switch {
	case verman && verok:
		log.Println("    Version was set manually.")
		log.Println("    Version confirmed by reading \"df/release notes.txt\".")
	case verman && verauto:
		log.Println("    Version was set manually.")
		log.Println("    This does not match the version read from \"df/release notes.txt\".")
		log.Println("    Are you sure you set it properly?")
	case verman:
		log.Println("    Version was set manually.")
		log.Println("    Could not confirm by reading \"df/release notes.txt\".")
		log.Println("    I'll assume you set this properly...")
	case verok:
		log.Println("    Using hardcoded version.")
		log.Println("    Version confirmed by reading \"df/release notes.txt\".")
	case verauto:
		log.Println("    Version acquired by reading \"df/release notes.txt\".")
		log.Println("    This does not match the hardcoded version.")
		log.Println("    If the stated version is not correct restart Rubble with")
		log.Println("    the -dfver option or by setting the dfver key in rubble.ini")
	default:
		log.Println("    Using hardcoded version.")
		log.Println("    Could not confirm by reading \"df/release notes.txt\".")
		log.Println("    If the stated version is not correct restart Rubble with")
		log.Println("    the -dfver option or by setting the dfver key in rubble.ini")
	}

	log.Println("  Calling action for mode:", mode)

	action := actions[mode]
	ok := action.Run(log, rblDir, dfDir, outDir, *addonDirs, options)
	if !ok {
		// Operation failed!
		// The action should have already logged an error message.
		os.Exit(1)
	}
	os.Exit(0)
}

// Wrapper type for action functions.
type funcWrapper ActionFunc

func (f funcWrapper) Run(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool {
	return f(log, rblDir, dfDir, outDir, addonDirs, options)
}

// Action is the interface types providing actions to the universal interface must satisfy.
type Action interface {
	// Carry out the action.
	// The only tricky bit is `options`, this is a slice of a mix of `*bool`, `*string`, and `*rblutil.ArgList` values.
	// Which ones are where is determined by the option specifiers you pass to Register.
	// Most of the other arguments are set from the "common options" all actions support.
	Run(log rblutil.Logger, rblDir, dfDir, outDir string, addonDirs []string, options []interface{}) bool
}
