/*
Copyright 2014-2016 by Milo Christiansen

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

// Rubble Raw parser Package.
package rparse

import "io"
import "bytes"

// Lexer states
const (
	stEatComment = iota
	stReadTagID
	stReadParam
)

type Tag struct {
	// The first (or only) element of a raw tag.
	ID string

	// Any other raw tag elements.
	Params []string

	// Filled with all the "stuff" (including white space)
	// between this tag and the next.
	Comments string

	// String should only return the comments.
	// Used for some special tags (the leading comments placeholder basically).
	CommentsOnly bool
	
	Line int
}

func (t *Tag) String() string {
	if t.CommentsOnly {
		return t.Comments
	}

	out := "[" + t.ID
	for _, val := range t.Params {
		out += ":" + val
	}
	return out + "]" + t.Comments
}

// Used to keep error handling under control
type stringBuilder struct {
	err error
	w   io.Writer
}

func (sb *stringBuilder) Add(data string) {
	if sb.err == nil {
		_, err := io.WriteString(sb.w, data)
		if err != nil {
			sb.err = err
		}
	}
}

func (sb *stringBuilder) Err() error {
	return sb.err
}

// Write the string version of the tag to the provided writer.
// Should give much better performance than String.
func (t *Tag) Format(w io.Writer) error {
	sb := &stringBuilder{w: w}
	if t.CommentsOnly {
		sb.Add(t.Comments)
		return sb.Err()
	}

	sb.Add("[")
	sb.Add(t.ID)
	for _, val := range t.Params {
		sb.Add(":")
		sb.Add(val)
	}
	sb.Add("]")
	sb.Add(t.Comments)
	return sb.Err()
}

// Parse raw text and return as a series of tags, tag 0 is invalid and contain leading comments only.
func ParseRaws(input []byte) []*Tag {
	out := make([]*Tag, 0)

	// Some trickery to preserve leading comments, part A
	x := make([]byte, 0, len(input)+9)
	x = append(x, "[__NOP__]"...)
	input = append(x, input...)

	lexeme := make([]byte, 0, 20)
	rawtag := make([]byte, 0, 40)
	comments := make([]byte, 0, 100)
	state := stEatComment
	var prevTag *Tag
	var curTag *Tag

	line := 1
	column := 1

	for _, val := range input {
		// Unused, but better to have it and not use it than not to have it at all...
		if val == '\n' {
			line++
			column = 1
		} else {
			column++
		}

		if val == '[' {
			// Start new tag
			if state != stEatComment {
				comments = append(comments, rawtag...)
				comments = append(comments, lexeme...)

				lexeme = lexeme[0:0]
				rawtag = rawtag[0:1]
				rawtag[0] = '['

				if prevTag != nil {
					prevTag.Comments += string(comments)
				}
				comments = comments[0:0]
				curTag = new(Tag)
				curTag.Line = line
				state = stReadTagID
				continue
			}

			rawtag = rawtag[0:1]
			rawtag[0] = '['

			if curTag != nil {
				curTag.Comments = string(comments)
				out = append(out, curTag)
			}
			comments = comments[0:0]
			prevTag = curTag
			curTag = new(Tag)
			curTag.Line = line
			state = stReadTagID
			continue
		}
		if val == ']' {
			// Close out tag
			if state == stReadTagID {
				curTag.ID = string(lexeme)
			} else if state == stReadParam {
				curTag.Params = append(curTag.Params, string(lexeme))
			}
			lexeme = lexeme[0:0]
			state = stEatComment
			continue
		}
		if val == ':' {
			// Start new param
			if state == stReadTagID {
				curTag.ID = string(lexeme)
				rawtag = append(rawtag, lexeme...)
				rawtag = append(rawtag, ':')
				lexeme = lexeme[0:0]
				state = stReadParam
				continue
			} else if state == stReadParam {
				curTag.Params = append(curTag.Params, string(lexeme))
				rawtag = append(rawtag, lexeme...)
				rawtag = append(rawtag, ':')
				lexeme = lexeme[0:0]
				continue
			}
		}

		if state == stEatComment {
			comments = append(comments, val)
			continue
		}

		// Add char to lexeme
		lexeme = append(lexeme, val)
	}
	if curTag != nil {
		curTag.Comments = string(comments)
		comments = comments[0:0]
		out = append(out, curTag)
	}

	// Some trickery to preserve leading comments, part B
	out[0].CommentsOnly = true

	return out
}

// Utilities

// FormatFile takes a set of tags and turns them into a byte slice ready to write.
func FormatFile(tags []*Tag) []byte {
	out := new(bytes.Buffer)

	for _, tag := range tags {
		// Writes on a byte buffer will always return nil, so there is no need to check for errors.
		tag.Format(out)
	}
	return out.Bytes()
}
