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

// ArgsList allows an argument to exist multiple times on the command line.
type ArgList []string

func (args *ArgList) String() string {
	if len(*args) == 0 {
		return ""
	}

	rtn := (*args)[0]
	args2 := (*args)[1:]
	for i := range args2 {
		rtn += " " + args2[i]
	}
	return rtn
}

func (args *ArgList) Set(arg string) error {
	*args = append(*args, arg)
	return nil
}

func (args *ArgList) Empty() bool {
	return len(*args) == 0
}
