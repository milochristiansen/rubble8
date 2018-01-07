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

package rblutil

// Expand variables in a string.
func Expand(input string, openchar byte, nest bool, data map[string]string) string {
	return ExpandFunc(input, openchar, nest, func(key string) string {
		return data[key]
	})
}

// Expand variables in a string.
func ExpandFunc(input string, openchar byte, nest bool, mapper func(string) string) string {
	buf := make([]byte, 0, len(input))

	depth := 0
	x := 0
	for y := 0; y < len(input); y++ {
		if !nest {
			if input[y] == '{' {
				depth++
			}
			if input[y] == '}' && depth > 0 {
				depth--
			}
		}

		if input[y] == openchar && y+1 < len(input) && depth == 0 {
			if input[y+1] == openchar {
				y++
				continue
			}

			buf = append(buf, input[x:y]...)
			name, w := getVarName(input[y+1:])
			if name == "" { // Error case, no name (handles the single literal percent case).
				buf = append(buf, openchar)
			} else if name == "{" { // Error case, name had non-alphanumeric before closing brace.
				buf = append(buf, openchar, '{')
			} else {
				buf = append(buf, mapper(name)...)
			}
			y += w
			x = y + 1
		}
	}

	return string(buf) + input[x:]
}

func getVarName(input string) (string, int) {
	if input[0] == '{' {
		// Scan alphanumerics to closing brace
		var i int
		for i = 1; i < len(input) && isAlphaNum(input[i]); i++ {
		}
		if input[i] == '}' {
			return input[1:i], i + 1
		}
		return "{", 2 // Bad syntax
	}
	// Scan alphanumerics.
	var i int
	for i = 0; i < len(input) && isAlphaNum(input[i]); i++ {
	}
	return input[:i], i
}

func isAlphaNum(c byte) bool {
	return c == '_' || '0' <= c && c <= '9' || 'a' <= c && c <= 'z' || 'A' <= c && c <= 'Z'
}
