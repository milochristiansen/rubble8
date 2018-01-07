/*
Copyright 2015-2018 by Milo Christiansen

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

package merge

import "io"
import "fmt"
import "bytes"

// Rule boundaries are delimited by any case where two non-separator tokens are in a row.
// The first token is the last token in the first rule and the second token is the first
// token in the second rule.

const (
	tknINVALID    = iota
	tknRuleSplit  // '|', this is a separator token.
	tknTagSplit   // ':', this is a separator token.
	tknDeclare    // '!'
	tknInsert     // '%'
	tknWCMatch    // '$'
	tknWCMerge    // '?'
	tknWCDiscard  // '&'
	tknBlockOpen  // '{'
	tknBlockClose // '}'
	tknArgOpen    // '('
	tknArgClose   // ')'
	tknArgSep     // ','
	tknItem       // a string or number
)

var delimiters = "|:(){},\n#"

// TEST:$|?(4,4)
// tknItem tknTagSplit tknWCMatch tknRuleSplit tknWCMerge tknArgOpen tknItem tknArgSep tknItem tknArgClose

type token struct {
	Lexeme string
	Type   int
	Line   int
}

type lexer struct {
	look    *token
	current *token

	source io.RuneReader
	char   rune
	eof    bool // true if there are no more chars to read

	line    int
	tknline int

	lexeme []rune
}

func newLexer(input []byte) *lexer {
	lex := new(lexer)

	lex.source = bytes.NewReader(input)

	lex.line = 0
	lex.tknline = 0

	lex.lexeme = make([]rune, 0, 20)

	// prime the pump
	lex.nextchar()
	lex.look = &token{"INVALID", tknINVALID, 0}
	lex.advance()

	return lex
}

// This advances the Lexer one token.
// For most purposes use GetToken instead.
func (lex *lexer) advance() {
	lex.current = lex.look
	if lex.eof {
		lex.look = &token{"EOF", tknINVALID, lex.tknline}
		return
	}

	lex.eatWS()
	if lex.eof {
		lex.look = &token{"EOF", tknINVALID, lex.tknline}
		return
	}

	// We are at the beginning of a token
	lex.tknline = lex.line
	switch lex.char {
	case '|':
		lex.look = &token{"", tknRuleSplit, lex.tknline}
		lex.nextchar()
	case ':':
		lex.look = &token{"", tknTagSplit, lex.tknline}
		lex.nextchar()
	case '!':
		lex.look = &token{"", tknDeclare, lex.tknline}
		lex.nextchar()
	case '%':
		lex.look = &token{"", tknInsert, lex.tknline}
		lex.nextchar()
	case '$':
		lex.look = &token{"", tknWCMatch, lex.tknline}
		lex.nextchar()
	case '?':
		lex.look = &token{"", tknWCMerge, lex.tknline}
		lex.nextchar()
	case '&':
		lex.look = &token{"", tknWCDiscard, lex.tknline}
		lex.nextchar()
	case '{':
		lex.look = &token{"", tknBlockOpen, lex.tknline}
		lex.nextchar()
	case '}':
		lex.look = &token{"", tknBlockClose, lex.tknline}
		lex.nextchar()
	case '(':
		lex.look = &token{"", tknArgOpen, lex.tknline}
		lex.nextchar()
	case ')':
		lex.look = &token{"", tknArgClose, lex.tknline}
		lex.nextchar()
	case ',':
		lex.look = &token{"", tknArgSep, lex.tknline}
		lex.nextchar()
	default:
		lex.matchItem()
	}

	lex.lexeme = lex.lexeme[0:0]
}

// Gets the next token, and panics with an error if it's not of type tokenType.
func (lex *lexer) getToken(tokenTypes ...int) {
	lex.advance()

	for _, val := range tokenTypes {
		if lex.current.Type == val {
			return
		}
	}

	panic(fmt.Sprint("Line: ", lex.current.Line))
}

// Checks to see if the look ahead is one of tokenTypes and if so returns true
func (lex *lexer) checkLookAhead(tokenTypes ...int) bool {
	for _, val := range tokenTypes {
		if lex.look.Type == val {
			return true
		}
	}
	return false
}
func (lex *lexer) match(chars string) bool {
	for _, char := range chars {
		if lex.char == char {
			return true
		}
	}
	return false
}

// Fetch the next char (actually a Unicode code point).
// I don't like the way EOF is handled, but there is really no better way that is flexible enough.
func (lex *lexer) nextchar() {
	if lex.eof {
		return
	}

	// err should only ever be io.EOF
	var err error
	lex.char, _, err = lex.source.ReadRune()
	if err != nil {
		lex.eof = true
		return
	}

	if lex.char == '\n' {
		lex.line++
	}
}

// Add the current char to the lexeme buffer.
func (lex *lexer) addLexeme() {
	lex.lexeme = append(lex.lexeme, lex.char)
}

// Eat white space and comments.
func (lex *lexer) eatWS() {
	for {
		if lex.match("#") {
			lex.nextchar()
			if lex.eof {
				return
			}
			for {
				if lex.match("\n") {
					lex.nextchar()
					if lex.eof {
						return
					}
					break
				}
				lex.nextchar()
				if lex.eof {
					return
				}
			}
			continue
		}
		if lex.match("\n\r \t") {
			lex.nextchar()
			if lex.eof {
				return
			}
			continue
		}
		break
	}
}

func (lex *lexer) matchItem() {
	for !lex.match(delimiters) {
		// Handle backslash escapes
		if lex.char == '\\' {
			lex.nextchar()
			if lex.eof {
				lex.lexeme = append(lex.lexeme, '\\')
				break
			}
		}

		lex.addLexeme()
		lex.nextchar()
		if lex.eof {
			break
		}
	}
	lex.look = &token{string(lex.lexeme), tknItem, lex.tknline}
}
