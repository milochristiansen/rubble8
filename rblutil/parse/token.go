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
import "rubble8/rblutil/errors"

// Token Types
const (
	TknINVALID = iota
	TknString
	TknTagBegin
	TknTagEnd
	TknDelimiter
)

type Token struct {
	Lexeme string
	Type   int

	File   *rblutil.LineInfo
	Offset int
}

func (tok *Token) String() string {
	return tokenTypeToString(tok.Type)
}

func tokenTypeToString(tokenType int) string {
	switch tokenType {
	case TknINVALID:
		return "TknINVALID"
	case TknString:
		return "TknString"
	case TknTagBegin:
		return "TknTagBegin"
	case TknTagEnd:
		return "TknTagEnd"
	case TknDelimiter:
		return "TknDelimiter"
	default:
		return "INVALID_TOKEN_TYPE"
	}
}

// Panics with a message formatted like one of the following:
//	Invalid token: Found: thecurrenttoken. Expected: expected1, expected2, or expected3.
//	Invalid token: Found: thecurrenttoken. Expected: expected1 or expected2.
//	Invalid token: Found: thecurrenttoken. Expected: expected.
//	Invalid token: Found: thecurrenttoken (Lexeme: test). Expected: expected1, expected2, or expected3.
//	Invalid token: Found: thecurrenttoken (Lexeme: test). Expected: expected1 or expected2.
//	Invalid token: Found: thecurrenttoken (Lexeme: test). Expected: expected.
// If the lexeme is long it is truncated.
func exitOnTokenExpected(token *Token, expected ...int) {
	expectedString := ""
	expectedCount := len(expected) - 1
	for i, val := range expected {
		// Is the only value
		if expectedCount == 0 {
			expectedString = tokenTypeToString(val)
			continue
		}

		// Is last of a list (2 or more)
		if i == expectedCount && expectedCount > 0 {
			expectedString += "or " + tokenTypeToString(val)
			continue
		}

		// Is the first of two
		if expectedCount == 1 {
			expectedString += tokenTypeToString(val) + " "
			continue
		}

		// Is any but the last of a list of 3 or more
		expectedString += tokenTypeToString(val) + ", "
	}

	found := token.String()
	if token.Lexeme != "" {
		if len(token.Lexeme) < 20 {
			found += " (Lexeme: " + token.Lexeme + ")"
		} else {
			found += " (Lexeme: " + token.Lexeme[:17] + "...)"
		}
	}
	panic(&errors.Error{
		Msg:    "Invalid token: Found: " + found + ". Expected: " + expectedString,
		File:   token.File,
		Offset: token.Offset,
	})
}
