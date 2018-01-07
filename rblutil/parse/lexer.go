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

package parse

import "rubble8/rblutil"

type lexer struct {
	source []byte
	char   byte

	eof bool

	file      *rblutil.LineInfo
	offset    int
	tknoffset int

	lexeme []byte

	depth int

	Look    *Token
	Current *Token
}

// newLexer returns a new lexer.
func newLexer(input []byte, fname string, line int) *lexer {
	finfo := rblutil.NewLineInfo(fname, line, len(input))
	return newLexerAdv(input, finfo)
}

func newLexerAdv(input []byte, finfo *rblutil.LineInfo) *lexer {
	lex := new(lexer)
	lex.source = input
	lex.file = finfo

	// prime the pump
	lex.offset = -1
	lex.nextchar()
	lex.Look = &Token{"BEGIN", TknINVALID, lex.file, lex.tknoffset}
	lex.Advance()

	return lex
}

// Helpers

// nextchar fetches the next character.
func (lex *lexer) nextchar() {
	if lex.eof {
		return
	}

	lex.offset++
	if lex.offset >= len(lex.source) {
		lex.eof = true
		lex.char = 0
		return
	}
	lex.char = lex.source[lex.offset]

	if lex.char == '\n' {
		lex.file.AddLine(lex.offset)
	}
}

// match returns true if the current char matches one of the chars in the string.
func (lex *lexer) match(chars string) bool {
	for i := 0; i < len(chars); i++ {
		if lex.char == chars[i] {
			return true
		}
	}
	return false
}

// addLexeme adds the current char to the lexeme buffer.
func (lex *lexer) addLexeme() {
	lex.lexeme = append(lex.lexeme, lex.char)
}

// Lexing

// Advance retrieves the next token from the input.
func (lex *lexer) Advance() {
	lex.Current = lex.Look
	if lex.eof {
		lex.Look = &Token{"EOF", TknINVALID, lex.file, lex.tknoffset}
		return
	}
	lex.Look = nil

	// We are at the beginning of a token
	lex.tknoffset = lex.offset

	for !lex.eof {
		// Quoted chars
		if lex.char == ';' || lex.char == '{' || lex.char == '}' {
			if lex.offset > 0 && lex.offset < len(lex.source)-1 {
				if lex.source[lex.offset-1] == '\'' && lex.source[lex.offset+1] == '\'' {
					lex.addLexeme()
					lex.nextchar()
					continue
				}
			}
		}

		// String end conditions
		if lex.char == ';' || lex.char == '}' {
			if len(lex.lexeme) > 0 && lex.depth == 1 {
				lex.Look = &Token{string(lex.lexeme), TknString, lex.file, lex.tknoffset}
				// DO NOT call nextchar!
				break
			}
		}
		if lex.char == '{' {
			if len(lex.lexeme) > 0 && lex.depth == 0 {
				lex.Look = &Token{string(lex.lexeme), TknString, lex.file, lex.tknoffset}
				// DO NOT call nextchar!
				break
			}
		}

		if lex.char == ';' {
			if lex.depth != 1 {
				lex.addLexeme()
				lex.nextchar()
				continue
			}

			lex.Look = &Token{";", TknDelimiter, lex.file, lex.tknoffset}
			lex.nextchar()
			break
		}

		if lex.char == '{' {
			lex.depth++
			if lex.depth > 1 {
				lex.addLexeme()
				lex.nextchar()
				continue
			}

			lex.Look = &Token{"{", TknTagBegin, lex.file, lex.tknoffset}
			lex.nextchar()
			break
		}

		if lex.char == '}' {
			lex.depth--
			if lex.depth != 0 {
				if lex.depth < 0 {
					lex.depth = 0
				}
				lex.addLexeme()
				lex.nextchar()
				continue
			}

			lex.Look = &Token{"}", TknTagEnd, lex.file, lex.tknoffset}
			lex.nextchar()
			break
		}

		lex.addLexeme()
		lex.nextchar()
	}

	if lex.Look == nil {
		if len(lex.lexeme) > 0 {
			lex.Look = &Token{string(lex.lexeme), TknString, lex.file, lex.tknoffset}
		} else {
			lex.Look = &Token{"EOF", TknINVALID, lex.file, lex.tknoffset}
		}
	}

	// Clear the lexeme buffer.
	lex.lexeme = lex.lexeme[0:0]
}

// Reading

// GetNext gets the next token, and panics with an error if it's not of type tokenType.
func (lex *lexer) GetNext(tokenTypes ...int) {
	lex.Advance()

	for _, val := range tokenTypes {
		if lex.Current.Type == val {
			return
		}
	}

	exitOnTokenExpected(lex.Current, tokenTypes...)
}

// CheckLook checks to see if the lookahead is one of tokenTypes and if so returns true.
func (lex *lexer) CheckLook(tokenTypes ...int) bool {
	for _, val := range tokenTypes {
		if lex.Look.Type == val {
			return true
		}
	}
	return false
}
