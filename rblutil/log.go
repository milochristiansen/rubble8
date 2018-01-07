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

import "math/rand"
import "time"
import "fmt"
import "os"
import "io"
import "bytes"
import "sync"

// Logger is the interface any logger that is to be used with Rubble must implement.
// Most if not all interfaces will use the default logger, but if you really need a
// custom logger you can provide your own.
type Logger interface {
	io.Writer
	
	// Printf prints to the log, see ftm.Printf.
	Printf(format string, msg ...interface{})
	
	// Println prints to the log, see ftm.Println.
	Println(msg ...interface{})
	
	// Print prints to the log, see ftm.Print.
	Print(msg ...interface{})
	
	// Warnf prints to the log and the warnings buffer, see ftm.Printf.
	Warnf(format string, msg ...interface{})
	
	// Warnln prints to the log and the warnings buffer, see ftm.Println.
	Warnln(msg ...interface{})
	
	// Warn prints to the log and the warnings buffer, see ftm.Print.
	Warn(msg ...interface{})
	
	// WarnExtraf prints to the log and the warnings buffer but does not increment the warning count, see ftm.Printf.
	WarnExtraf(format string, msg ...interface{})
	
	// WarnExtraln prints to the log and the warnings buffer but does not increment the warning count, see ftm.Println.
	WarnExtraln(msg ...interface{})
	
	// WarnExtra prints to the log and the warnings buffer but does not increment the warning count, see ftm.Print.
	WarnExtra(msg ...interface{})
	
	// WarnOnlyf prints to the warnings buffer, see ftm.Printf.
	WarnOnlyf(format string, msg ...interface{})
	
	// WarnOnlyln prints to the warnings buffer, see ftm.Println.
	WarnOnlyln(msg ...interface{})
	
	// WarnOnly prints to the warnings buffer, see ftm.Print.
	WarnOnly(msg ...interface{})
	
	// WarnOnlyExtraf prints to the warnings buffer but does not increment the warning count, see ftm.Printf.
	WarnOnlyExtraf(format string, msg ...interface{})
	
	// WarnOnlyExtraln prints to the warnings buffer but does not increment the warning count, see ftm.Println.
	WarnOnlyExtraln(msg ...interface{})
	
	// WarnOnlyExtra prints to the warnings buffer but does not increment the warning count, see ftm.Print.
	WarnOnlyExtra(msg ...interface{})
	
	// ClearWarnings clears the warnings buffer and resets the warning count.
	ClearWarnings()
	
	// WarnCount returns the number of warnings in the current buffer.
	WarnCount() int
	
	// WarnBuffer returns the warnings buffer
	WarnBuffer() []byte
	
	// LogBuffer returns the log up to now or a shortened version if it gets too large.
	LogBuffer() []byte
}

// defaultLogger writes to rubble.log and os.Stdout.
type defaultLogger struct {
	wc int
	wb *bytes.Buffer
	
	lb *bytes.Buffer
	
	file *os.File
	
	lock *sync.Mutex
}

// NewLogger creates a new default logger.
// 
// The default logger writes to a single file and an in-memory buffer. The buffer is limited to
// 50K. Longer logs will have their beginnings periodically truncated to keep the buffer from
// getting too large. The log file will, of course, contain the entire log.
// 
// All methods are safe for concurrent access.
func NewLogger() (error, Logger) {
	file, err := os.Create("./rubble.log")
	if err != nil {
		return err, nil
	}

	log := &defaultLogger {
		wb: new(bytes.Buffer),
		lb: new(bytes.Buffer),
		file: file,
		lock: new(sync.Mutex),
	}
	
	// Not useful. The log is never deleted before the program exits.
	//runtime.SetFinalizer(log, func(log *defaultLogger){
	//	log.file.Close()
	//})
	
	return nil, log
}

var truncMsg = []byte("\n(Buffer Truncated)\n")

func (log *defaultLogger) Write(p []byte) (n int, err error) {
	log.lock.Lock()
	defer log.lock.Unlock()
	
	// If the buffer is greater than 50K shift the last half up and truncate it.
	// This also prefixes the buffer with a message stating it was truncated.
	if log.lb != nil && log.lb.Len() > 50*1024 {
		
		b := log.lb.Bytes()
		
		// Make sure we truncate at a line boundary
		bb := b[25*1024:]
		for len(bb) > 0 && bb[0] != '\n' {
			bb = bb[1:]
		}
		
		copy(b, truncMsg)
		copy(b[len(truncMsg):], bb)
		log.lb.Truncate(len(truncMsg)+len(bb))
	}
	
	if log.lb != nil {
		log.lb.Write(p) // No error possible on writes to a bytes.Buffer
	}
	
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

func (log *defaultLogger) Printf(format string, msg ...interface{}) {
	fmt.Fprintf(log, format, msg...)
}

func (log *defaultLogger) Println(msg ...interface{}) {
	fmt.Fprintln(log, msg...)
}

func (log *defaultLogger) Print(msg ...interface{}) {
	fmt.Fprint(log, msg...)
}

func (log *defaultLogger) Warnf(format string, msg ...interface{}) {
	fmt.Fprintf(log, format, msg...)
	fmt.Fprintf(log.wb, format, msg...)
	log.wc++
}

func (log *defaultLogger) Warnln(msg ...interface{}) {
	fmt.Fprintln(log, msg...)
	fmt.Fprintln(log.wb, msg...)
	log.wc++
}

func (log *defaultLogger) Warn(msg ...interface{}) {
	fmt.Fprint(log, msg...)
	fmt.Fprint(log.wb, msg...)
	log.wc++
}

func (log *defaultLogger) WarnExtraf(format string, msg ...interface{}) {
	fmt.Fprintf(log, format, msg...)
	fmt.Fprintf(log.wb, format, msg...)
}

func (log *defaultLogger) WarnExtraln(msg ...interface{}) {
	fmt.Fprintln(log, msg...)
	fmt.Fprintln(log.wb, msg...)
}

func (log *defaultLogger) WarnExtra(msg ...interface{}) {
	fmt.Fprint(log, msg...)
	fmt.Fprint(log.wb, msg...)
}

func (log *defaultLogger) WarnOnlyf(format string, msg ...interface{}) {
	fmt.Fprintf(log.wb, format, msg...)
	log.wc++
}

func (log *defaultLogger) WarnOnlyln(msg ...interface{}) {
	fmt.Fprintln(log.wb, msg...)
	log.wc++
}

func (log *defaultLogger) WarnOnly(msg ...interface{}) {
	fmt.Fprint(log.wb, msg...)
	log.wc++
}

func (log *defaultLogger) WarnOnlyExtraf(format string, msg ...interface{}) {
	fmt.Fprintf(log.wb, format, msg...)
}

func (log *defaultLogger) WarnOnlyExtraln(msg ...interface{}) {
	fmt.Fprintln(log.wb, msg...)
}

func (log *defaultLogger) WarnOnlyExtra(msg ...interface{}) {
	fmt.Fprint(log.wb, msg...)
}

func (log *defaultLogger) ClearWarnings() {
	log.wb.Reset()
	log.wc = 0
}

func (log *defaultLogger) WarnCount() int {
	return log.wc
}

func (log *defaultLogger) WarnBuffer() []byte {
	return log.wb.Bytes()
}

func (log *defaultLogger) LogBuffer() []byte {
	return log.lb.Bytes()
}

// Separator writes a section separator to the log.
// Use for consistency.
func LogSeparator(log Logger) {
	log.Println("================================================================================")
}

// Header writes the standard header to the log.
// Use for consistency.
func LogHeader(log Logger, version string) {
	rand.Seed(time.Now().Unix())
	log.Print("Rubble v"+version+"\n")
	log.Print(startupLines[rand.Int()%(len(startupLines)-1)]+"\n")
	LogSeparator(log)
}

var startupLines = [...]string{
	"After Blast comes Rubble.",
	"Modding made easy!",
	"Scriptable!",
	"Templates!",
	"Now with random startup lines!",
	"Why did I add this feature?",
	"Rubblize it!",
	"Now with a web UI!",
	"Use the command line!",
	"Configurable!",
	"Now with more addons you will never use!",
	"Please report any problems.",
	"Feedback is greatly appreciated!",
	"Unintentionally Ironic!",
	"Why do these all end with exclamation points!",
	"Free exclamation points!",
	"Guaranteed 50% bug free!",
	"There better not be an error log!",
	"Run it again, this line might change.",
	"Over 100 addons!",
	"Now with meta data!",
	"Lua Scripting!",
	"Read the documentation!",
	"Runs natively on Windows, Linux, and OSX!",
	"Under continuous development since June 2013!",
	"Open source!",
	"Supports DFHack!",
	"Include the ENTIRE log in any bug reports!",
	"Long hours of debugging later...",
	"Rule-based tileset installation!",
	"Suggestions welcome!",
	"Supports DFFD!",
}
