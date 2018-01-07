/*
Copyright 2013-2018 by Milo Christiansen

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

// Functions to validate, retrieve, and create user tokens for the content server.
package login

import "time"
import "math/rand"
import "encoding/binary"

import "github.com/milochristiansen/axis2"

// EnsureToken makes sure the given user has a valid token in "rubble/users/".
func EnsureToken(name string, fs *axis2.FileSystem) error {
	if fs.Exists("rubble/users/"+name+".tkn") && fs.Size("rubble/users/"+name+".tkn") == 1024 {
		return nil
	}

	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	token := make([]byte, 1024)
	rng.Read(token) // Docs say returns no error

	return fs.WriteAll("rubble/users/"+name+".tkn", token)
}

func Validate(name string, token *[1024]byte, fs *axis2.FileSystem) bool {
	if !fs.Exists("rubble/users/" + name + ".tkn") {
		return false
	}

	ltkn := GetToken(name, fs)
	if ltkn == nil {
		return false
	}
	return *ltkn == *token
}

func GetToken(name string, fs *axis2.FileSystem) *[1024]byte {
	if !fs.Exists("rubble/users/" + name + ".tkn") {
		return nil
	}

	rdr, err := fs.Read("rubble/users/" + name + ".tkn")
	if err != nil {
		return nil
	}
	defer rdr.Close()

	ltkn := new([1024]byte)
	err = binary.Read(rdr, binary.BigEndian, ltkn)
	if err != nil {
		return nil
	}

	return ltkn
}
