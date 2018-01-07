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

package test

import "strings"

// Parse reads all test units from the given input and returns them in a slice.
func Parse(input []byte, fname string, line int) []Data {
	inUnit := false
	inBlock := false
	blockAccum := make([]byte, 0, 10240)

	var units []Data
	var cUnit Data

	// This is basically a faster version of the commonly used retarded line-based parser.
	for i := 0; i < len(input); i++ {
		char := input[i]
		if char == '\n' {
			line++
		}

		// Possible beginning of unit
		if !inUnit && char == '>' {
			// If this is the start of a unit read the ID and anything else up to the end of the line.
			if len(input) > i+2 && input[i+1] == '>' && input[i+2] == '>' {
				i += 3
				inUnit = true
				inBlock = true
				cUnit = Data{}

				for ; i < len(input); i++ {
					if input[i] == '\n' {
						line++
					}
					if input[i] == ':' {
						break
					}
					blockAccum = append(blockAccum, input[i])
				}
				cUnit.InLine = line
				cUnit.ID = strings.TrimSpace(string(blockAccum))
				blockAccum = blockAccum[0:0]
				continue
			}
		}

		// Possible block switch
		if inUnit && inBlock && char == '=' {
			if len(input) > i+2 && input[i+1] == '=' && input[i+2] == '=' {
				i += 2
				inBlock = false

				cUnit.OutLine = line
				cUnit.In = strings.TrimSpace(string(blockAccum))
				blockAccum = blockAccum[0:0]
				continue
			}
		}

		// Possible end of unit
		if inUnit && !inBlock && char == '<' {
			if len(input) > i+2 && input[i+1] == '<' && input[i+2] == '<' {
				i += 2
				inUnit = false
				cUnit.Out = strings.TrimSpace(string(blockAccum))
				blockAccum = blockAccum[0:0]
				units = append(units, cUnit)
				continue
			}
		}

		if inUnit {
			blockAccum = append(blockAccum, char)
		}
	}
	return units
}
