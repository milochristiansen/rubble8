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

package main

import "time"
import "fmt"
import "os"
import "io"
import "sync"

import "github.com/milochristiansen/rubble8"
import "github.com/milochristiansen/rubble8/rblutil"

// serverLogger writes to rubble.log and os.Stdout.
type serverLogger struct {
	file *os.File

	bc     int
	prefix string

	lock *sync.Mutex
}

func newLogger(name string) (error, rblutil.Logger) {
	file, err := os.Create(fmt.Sprintf("./"+name+" "+rubble8.Version+" %v.log", time.Now().UTC().Format("06-01-02 15.04.05")))
	if err != nil {
		return err, nil
	}

	log := &serverLogger{
		file: file,
		lock: new(sync.Mutex),
	}

	// Not useful. The log is never deleted before the program exits.
	//runtime.SetFinalizer(log, func(log *serverLogger){
	//	log.file.Close()
	//})

	return nil, log
}

func (log *serverLogger) Write(p []byte) (n int, err error) {
	log.lock.Lock()
	defer log.lock.Unlock()

	if log.bc > 1024*1024 {
		file, err := os.Create(fmt.Sprintf("./"+log.prefix+" %v.log", time.Now().UTC().Format("06-01-02 15.04.05")))
		if err != nil {
			return 0, err
		}
		log.file.Close()
		log.bc = 0
		log.file = file
	}

	log.bc += len(p)

	n, err = log.file.Write(p)
	if err != nil {
		return
	}
	if n != len(p) {
		err = io.ErrShortWrite
		return
	}

	n, err = os.Stdout.Write(p)
	if err != nil {
		return
	}
	if n != len(p) {
		err = io.ErrShortWrite
		return
	}

	return len(p), nil
}

func (log *serverLogger) Printf(format string, msg ...interface{}) {
	fmt.Fprintf(log, format, msg...)
}

func (log *serverLogger) Println(msg ...interface{}) {
	fmt.Fprintln(log, msg...)
}

func (log *serverLogger) Print(msg ...interface{}) {
	fmt.Fprint(log, msg...)
}

func (log *serverLogger) Warnf(format string, msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) Warnln(msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) Warn(msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) WarnExtraf(format string, msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) WarnExtraln(msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) WarnExtra(msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) WarnOnlyf(format string, msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) WarnOnlyln(msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) WarnOnly(msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) WarnOnlyExtraf(format string, msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) WarnOnlyExtraln(msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) WarnOnlyExtra(msg ...interface{}) {
	panic("Server logger does not support warnings.")
}

func (log *serverLogger) ClearWarnings() {

}

func (log *serverLogger) WarnCount() int {
	return 0
}

func (log *serverLogger) WarnBuffer() []byte {
	return nil
}

func (log *serverLogger) LogBuffer() []byte {
	return nil
}
