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

// Types and functions to load template unit tests.
package test

import "strings"

// Data is a single template test unit.
type Data struct {
	ID string

	InLine int
	In     string

	OutLine int
	Out     string
}

func (t Data) String() string {
	return ">>> " + t.ID + ":\n" +
		t.In +
		"\n===\n" +
		t.Out +
		"\n<<<"
}

func (t Data) Example() string {
	out := t.ID + ":\n"
	lines := strings.SplitAfter(t.In, "\n")
	for _, line := range lines {
		out += "\t" + line
	}
	out += "\nReturns:\n"
	lines = strings.SplitAfter(t.Out, "\n")
	for _, line := range lines {
		out += "\t" + line
	}
	return out
}

func (t Data) FailMsg(addon, got string) string {
	out := "    Test: " + t.ID + " in Addon: \"" + addon + "\" Failed:\n      Got:\n"
	lines := strings.SplitAfter(got, "\n")
	for _, line := range lines {
		out += "        " + line
	}
	out += "\n      Expected:\n"
	lines = strings.SplitAfter(t.Out, "\n")
	for _, line := range lines {
		out += "        " + line
	}
	return out
}

func (t Data) PassMsg(addon, got string) string {
	out := "    Test: " + t.ID + " in Addon: \"" + addon + "\" Passed:\n      Got:\n"
	lines := strings.SplitAfter(got, "\n")
	for _, line := range lines {
		out += "        " + line
	}
	return out
}
