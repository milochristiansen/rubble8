/*
Copyright 2014-2018 by Milo Christiansen

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

package errors

import "github.com/milochristiansen/rubble8/rblutil"
import "fmt"
import "runtime"

// Error is a generic error wrapper for all Rubble errors.
type Error struct {
	// Flags the error as an "abort", eg something that stops generation but is not a fatal
	// error (for example configuration problems should be aborts).
	Abort bool

	// The error message if any (most errors will have a message).
	Msg string

	// An underlying error value if any.
	Err error

	// Error position information, leave nil for none.
	File   *rblutil.LineInfo
	Offset int
}

func (err Error) Error() string {
	at := ""
	if err.File != nil {
		at = " Near: " + err.File.PosString(err.Offset)
	}

	msg := ""
	if err.Msg != "" {
		msg = ": " + err.Msg
	}

	errmsg := ""
	if err.Err != nil {
		errmsg = ": " + err.Err.Error()
	}

	if err.Abort {
		return "Abort" + msg + errmsg + at
	}
	return "Error" + msg + errmsg + at
}

// Takes any error and retuns true if it is a Rubble Error with the abort flag set.
func IsAbort(err error) bool {
	if e, ok := err.(Error); ok {
		return e.Abort
	}
	return false
}

// RaiseError converts a string to a Error and then panics with it.
func RaiseError(msg string) {
	panic(Error{Msg: msg})
}

// RaiseError converts a string to a Error with the abort flag set and then panics with it.
func RaiseAbort(msg string) {
	panic(Error{Abort: true, Msg: msg})
}

// RaiseWrappedError wraps an error value together with a message and panics with the result.
func RaiseWrappedError(msg string, err error) {
	panic(Error{Msg: msg, Err: err})
}

// TrapError traps panics and turns them into returnable errors.
// If possible provide a logger for more output in special cases, if no logger is readily available just pass nil.
func TrapError(err *error, log rblutil.Logger) {
	if x := recover(); x != nil {
		switch y := x.(type) {
		case error:
			*err = y
		default:
			*err = Error{Msg: "Some idiot panicked with a non-error value", Err: fmt.Errorf("%v", x)}
		}

		// Print a native stack trace to help debugging.
		if false && log != nil {
			log.Println("Debugging Mode:")
			log.Println("  ", x)
			log.Printf("  Raw Error: %#v\n", x)

			log.Println("Stack Trace:")
			buf := make([]byte, 4096)
			buf = buf[:runtime.Stack(buf, true)]
			log.Printf("%s", buf)
		}
	}
}
