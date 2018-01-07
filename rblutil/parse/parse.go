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

// Rubble template parser.
package parse

import "strings"
import "strconv"

import "rubble8/rblutil"
import "rubble8/rblutil/addon"
import "rubble8/rblutil/errors"

// Parse stage constants
type Stage int

const (
	StgPreParse Stage = iota
	StgParse
	StgPostParse
)

// Dispatcher is a template call dispatcher. It's job is to satisfy raw template calls by calling the appropriate
// handlers or scripts.
type Dispatcher func(args []string, stage Stage, file *rblutil.LineInfo, offsets []int) string

// PreDispatcher should return true if the given template call should be processed.
type PreDispatcher func(args []string, stage Stage, file *rblutil.LineInfo, offsets []int) bool

// ParseFile parses a file "in place". If an error is encountered the file is not modified.
func ParseFile(file *addon.File, stage Stage, handler Dispatcher) (err error) {
	defer errors.TrapError(&err, nil)
	file.Content = Parse(file.Content, file.Source+"/"+file.Name, 1, stage, handler, nil)
	return nil
}

func prepArg(arg string) string {
	arg = strings.TrimSpace(arg)
	tmp, err := strconv.Unquote(arg)
	if err != nil {
		return arg
	}
	return tmp
}

// Parse parses a block of raw text using the given template dispatcher to handle template calls.
// This function will panic on error.
// If a PreDispatcher is proved Parse enters a special mode where you may have greater control over parsing.
func Parse(input []byte, name string, line int, stage Stage, handler Dispatcher, prehandler PreDispatcher) []byte {
	if stage != StgPreParse && stage != StgParse && stage != StgPostParse {
		errors.RaiseError("Parse called with invalid parse stage.")
	}

	// 100k sounds like a lot, but there are vanilla raw files that are almost 400k.
	// Most seem to be around 50k-70k so 100k is not too high or low.
	out := make([]byte, 0, 102400)
	lex := newLexer(input, name, line)
	file := lex.Current.File

loop:
	for {
		lex.Advance()

		switch lex.Current.Type {
		case TknTagBegin:
			if !stageTemplate(lex.Look.Lexeme, stage) {
				out = append(out, templateToString(lex)...)
				continue
			}
			
			lex.GetNext(TknString)
			var rawparams []string
			if prehandler != nil {
				rawparams = []string{lex.Current.Lexeme}
			}
			params := []string{prepArg(lex.Current.Lexeme)}
			offsets := []int{lex.Current.Offset}
			for lex.CheckLook(TknDelimiter) {
				lex.GetNext(TknDelimiter)
				if lex.CheckLook(TknString) {
					lex.GetNext(TknString)
					params = append(params, prepArg(lex.Current.Lexeme))
					if prehandler != nil {
						rawparams = append(rawparams, lex.Current.Lexeme)
					}
					offsets = append(offsets, lex.Current.Offset)
				} else {
					params = append(params, "")
					if prehandler != nil {
						rawparams = append(rawparams, "")
					}
					offsets = append(offsets, lex.Current.Offset)
				}
			}
			lex.GetNext(TknTagEnd)
			
			if prehandler == nil || prehandler(params, stage, file, offsets) {
				out = append(out, handler(params, stage, file, offsets)...)
			} else {
				out = append(out, '{')
				for _, param := range rawparams {
					out = append(out, param...)
					out = append(out, ';')
				}
				out[len(out)-1] = '}'
			}

		case TknINVALID:
			break loop

		default:
			out = append(out, lex.Current.Lexeme...)
		}
	}

	return []byte(out)
}

func stageTemplate(name string, stage Stage) bool {
	name = prepArg(name)
	if len(name) < 1 {
		return false
	}

	a := name[0]

	if a == '@' {
		return true
	}

	switch stage {
	case StgPreParse:
		return a == '!'

	case StgParse:
		if a == '!' {
			errors.RaiseError("Attempt to parse pre template in main parse stage. Please ensure that this template is not nested in a later parse stage template.")
		}
		return !(a == '#' || a == '!')

	case StgPostParse:
		if a != '#' {
			errors.RaiseError("Attempt to parse pre or main template in post parse stage. Please ensure that this template is not nested in a later parse stage template.")
		}
		return true

	}
	return false
}

func templateToString(lex *lexer) string {
	out := "{"
	for {
		lex.Advance()

		if lex.Current.Type == TknTagEnd {
			return out + "}"
		}

		if lex.Current.Type == TknINVALID {
			return out
		}

		out += lex.Current.Lexeme
	}
}
