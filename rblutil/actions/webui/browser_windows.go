/*
Copyright 2015-2016 by Milo Christiansen

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

package webui

import "rubble8/rblutil"

import "unsafe"

// #define WIN32_LEAN_AND_MEAN
// #include <windows.h>
// #include <shellapi.h>
// #include <stdlib.h>
import "C"

// LaunchBrowser attempts to launch your web browser via the Windows ShellExecute API.
func LaunchBrowser(log rblutil.Logger, rbldir, addr string) {
	log.Println("Starting the Default Web Browser...")
	log.Println("  Attempting to Open: \"http://" + addr + "/menu\"")

	caction := (*C.CHAR)(C.CString("Open"))
	defer C.free(unsafe.Pointer(caction))

	cpath := (*C.CHAR)(C.CString("http://" + addr + "/menu"))
	defer C.free(unsafe.Pointer(cpath))

	cnul := (*C.CHAR)(C.CString(""))
	defer C.free(unsafe.Pointer(cnul))

	// Yes, this really is the shortest way I could find to get a null pointer.
	// Simply passing "0" won't work.
	C.ShellExecuteA(C.HWND(unsafe.Pointer(uintptr(0))), caction, cpath, cnul, cnul, C.INT(1))
}
