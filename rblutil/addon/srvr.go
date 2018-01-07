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

package addon

import "github.com/milochristiansen/rubble8/rblutil"
import "github.com/milochristiansen/rubble8/rblutil/errors"
import "github.com/milochristiansen/rubble8/rblutil/login"
import "github.com/milochristiansen/rubble8/rblutil/dffd"

import "github.com/milochristiansen/axis2"
import "github.com/milochristiansen/axis2/sources/zip"

import "encoding/json"
import "encoding/binary"
import "strings"
import "io/ioutil"
import "crypto/md5"
import "net"
import "net/http"
import "sync"
import "time"

// PackBase is used by the content server to store it's addon pack information and sync it for concurrent access.
type PackBase struct {
	sync.RWMutex

	data  map[string]*[]*PackMeta
	locks map[string]*sync.RWMutex
}

func NewPackBase(fs *axis2.FileSystem) (*PackBase, error) {
	packs := &PackBase{
		data:  map[string]*[]*PackMeta{},
		locks: map[string]*sync.RWMutex{},
	}

	for _, filename := range fs.ListFiles("addons") {
		if strings.HasSuffix(filename, ".json") {
			name := rblutil.StripExt(filename)

			data := &[]*PackMeta{}
			content, err := fs.ReadAll("addons/" + filename)
			if err != nil {
				return nil, err
			}
			err = json.Unmarshal(content, data)
			if err != nil {
				return nil, err
			}

			packs.data[name] = data
			packs.locks[name] = new(sync.RWMutex)
		}
	}

	return packs, nil
}

// List returns information on every addon pack that is compatible with the given versions that is in this database.
func (packs *PackBase) List(ver *HostVersions) map[string]*PackMeta {
	packs.RLock()
	defer packs.RUnlock()

	rtn := map[string]*PackMeta{}
	for pack := range packs.data {
		meta := packs.LookUp(pack, ver)
		if meta != nil {
			rtn[pack] = meta
		}
	}
	return rtn
}

// LookUp returns the information of the newest addon pack compatible with the given host versions or nil.
func (packs *PackBase) LookUp(id string, ver *HostVersions) *PackMeta {
	packs.RLock()
	packv, ok := packs.data[id]
	packs.RUnlock()
	if !ok {
		return nil
	}
	lock := packs.locks[id]
	lock.RLock()
	defer lock.RUnlock()

	idx := -1
	for i, pack := range *packv {
		if !pack.MatchVersions(ver) {
			continue
		}

		if idx != -1 {
			last := (*packv)[idx]
			if pack.VerMajor == last.VerMajor {
				if pack.VerMinor == last.VerMinor {
					if pack.VerPatch < last.VerPatch {
						continue
					}
				} else if pack.VerMinor < last.VerMinor {
					continue
				}
			} else if pack.VerMajor < last.VerMajor {
				continue
			}
		}

		idx = i
	}
	if idx != -1 {
		return (*packv)[idx]
	}
	return nil
}

// Add adds a new entry to the database.
func (packs *PackBase) Add(id, ver string, meta *PackMeta, fs *axis2.FileSystem) error {
	packs.Lock()
	defer packs.Unlock()

	packv, ok := packs.data[id]
	if ok {
		lock := packs.locks[id]
		lock.Lock()
		defer lock.Unlock()

		idx := -1
		for i, pack := range *packv {
			if (pack.DFFDID != -1 && pack.DFFDID == meta.DFFDID) || pack.URL == meta.URL || (ver != "" && pack.VersionStr == ver) {
				idx = i
				break
			}
		}

		if idx == -1 {
			idx = len(*packv)
			*packv = append(*packv, meta)
			packs.data[id] = packv
		} else {
			(*packv)[idx] = meta
		}
	} else {
		tmp := make([]*PackMeta, 1)
		tmp[0] = meta
		packv = &tmp
		packs.data[id] = packv
		packs.locks[id] = new(sync.RWMutex)
	}

	out, err := json.Marshal(packv)
	if err != nil {
		return err
	}
	return fs.WriteAll("addons/"+id+".json", out)
}

// AddFromDFFD downloads the given item, then reads the pack.meta file from the downloaded pack and uses the result to call Add.
func (packs *PackBase) AddFromDFFD(id, ver string, dffdid int64, user string, fs *axis2.FileSystem) (err error) {
	info, err := dffd.Query(dffdid)
	if err != nil {
		return err
	}

	return packs.AddFromUrl(id, ver, info.URL(), user, fs)
}

// AddFromUrl downloads the given item, then reads the pack.meta file from the downloaded pack and uses the result to call Add.
func (packs *PackBase) AddFromUrl(id, ver, url, user string, fs *axis2.FileSystem) (err error) {
	defer errors.TrapError(&err, nil) // loadPackMeta may panic

	client := new(http.Client)
	r, err := client.Get(url)
	if err != nil {
		return err
	}

	content, err := ioutil.ReadAll(r.Body)
	r.Body.Close()
	if err != nil {
		return err
	}

	nds, err := zip.NewRawDir(content)
	if err != nil {
		return err
	}

	fs.Mount("loader/pack", nds, false)
	meta := loadPackMeta(fs, "loader/pack")
	fs.Unmount("loader/pack", true)

	meta.URL = url
	meta.Owner = user
	sum := md5.Sum(content)
	meta.MD5 = &sum

	return packs.Add(id, ver, meta, fs)
}

// Remove removes an entry from the database. If no matching entry exists nothing happens.
func (packs *PackBase) Remove(id, ver string, fs *axis2.FileSystem) error {
	packs.Lock()
	defer packs.Unlock()

	packv, ok := packs.data[id]
	if ok {
		lock := packs.locks[id]
		lock.Lock()
		defer lock.Unlock()

		for i, pack := range *packv {
			if pack.VersionStr == ver {
				copy((*packv)[i:], (*packv)[i+1:])
				*packv = (*packv)[:len(*packv)-1]

				if len(*packv) == 0 {
					delete(packs.data, id)
					delete(packs.locks, id)
					return fs.Delete("addons/" + id + ".json")
				}
				packs.data[id] = packv

				out, err := json.Marshal(packv)
				if err != nil {
					return err
				}
				return fs.WriteAll("addons/"+id+".json", out)
			}
		}
	}
	return nil
}

// SrvrRequest is the structure used to hold information for content server requests.
type SrvrRequest struct {
	Action string

	// Pack ID. Needed for all actions except adding a new user.
	PackID string

	// Version to delete when deleting, or version to replace when uploading.
	PackVer string

	// The URL of the pack to upload when uploading. The other information the server needs
	// is then read from the pack's pack.meta file.
	PackURL string

	// Client version numbers.
	HostVer *HostVersions

	// User name and token for uploading or adding a new user.
	User  string
	Token *[1024]byte
}

func ReadRequest(conn net.Conn) (*SrvrRequest, error) {
	var rlen int64
	err := binary.Read(conn, binary.BigEndian, &rlen)
	if err != nil {
		return nil, err
	}

	rbody := make([]byte, rlen)
	_, err = conn.Read(rbody)
	if err != nil {
		return nil, err
	}

	rtn := &SrvrRequest{}
	err = json.Unmarshal(rbody, rtn)
	if err != nil {
		return nil, err
	}
	return rtn, nil
}

func (req *SrvrRequest) SendRequest(conn net.Conn) {
	out, err := json.Marshal(req)
	if err != nil {
		panic(err) // <- Should be impossible, but better to crash and burn then continue oblivious...
	}

	binary.Write(conn, binary.BigEndian, int64(len(out)))
	conn.Write(out)
}

// LookupContentServerPack attempts to connect to the content server at the given address and
// lookup the requested addon pack. Any failure simply causes nil to be returned. This is for
// use in cases where failure is half expected (such as in the addon loader).
//
// Not suitable for interactive use.
func LookupContentServerPack(addr, name string) *PackMeta {
	rcode, rtn, err := ContactContentServer(addr, "Info", name, "", "", "", nil)
	if rcode != "OK" || err != nil {
		return nil
	}
	return rtn.(*PackMeta)
}

var invalidArguments = &errors.Error{Msg: "Invalid arguments for content server action."}
var invalidAction = &errors.Error{Msg: "Invalid content server action."}

// ContactContentServer is a generic function that wrap the entire process of querying a content server.
// Some arguments are only required for certain actions.
//
// A nil error does not always mean success! Check the server response code as well!
//
// Unless you know what you are doing do not use this function!
func ContactContentServer(addr, action, pack, ver, url, user string, token *[1024]byte) (string, interface{}, error) {
	switch action {
	case "List":
		// NOP
	case "Info":
		if pack == "" {
			return "", nil, invalidArguments
		}
	case "Upload":
		if pack == "" || url == "" || user == "" || token == nil {
			return "", nil, invalidArguments
		}
	case "Delete":
		if pack == "" || ver == "" || user == "" || token == nil {
			return "", nil, invalidArguments
		}
	case "AddUser":
		if user == "" || token == nil {
			return "", nil, invalidArguments
		}
	default:
		return "", nil, invalidAction
	}

	conn, err := net.Dial("tcp", addr)
	if err != nil {
		return "", nil, err
	}
	defer conn.Close()

	(&SrvrRequest{
		Action: action,

		PackID:  pack,
		PackVer: ver,
		PackURL: url,

		HostVer: &HostVersions{
			DFMajor: rblutil.DFVMajor,
			DFPatch: rblutil.DFVMinor,

			RblRewrite: rblutil.VMajor,
			RblMajor:   rblutil.VMinor,
			RblPatch:   rblutil.VPatch,
		},

		User:  user,
		Token: token,
	}).SendRequest(conn)

	var rlen byte
	err = binary.Read(conn, binary.BigEndian, &rlen)
	if err != nil {
		return "", nil, err
	}
	rcode := make([]byte, rlen)
	_, err = conn.Read(rcode)
	if err != nil {
		return "", nil, err
	}

	if string(rcode) != "OK" {
		return string(rcode), nil, nil
	}

	if action == "Info" || action == "List" {
		var rlen int64
		err = binary.Read(conn, binary.BigEndian, &rlen)
		if err != nil {
			return "OK", nil, err
		}
		rbody := make([]byte, rlen)
		_, err = conn.Read(rbody)
		if err != nil {
			return "OK", nil, err
		}
		var rtn interface{}
		if action == "Info" {
			rtn = NewPackMeta()
		} else {
			rtn = &map[string]*PackMeta{}
		}
		err = json.Unmarshal(rbody, rtn)
		if err != nil {
			println(err.Error())
			return "OK", nil, err
		}
		if action == "List" {
			rtn = *rtn.(*map[string]*PackMeta)
		}
		return "OK", rtn, nil
	}
	return "OK", nil, nil
}

// ServeConn handles a single content server connection. This function contains the "guts" of the content server.
// The connection is closed before return.
func (packs *PackBase) ServeConn(log rblutil.Logger, fs *axis2.FileSystem, conn net.Conn) {
	defer conn.Close()

	// Read Request
	req, err := ReadRequest(conn)
	if err != nil {
		log.Println("Error reading request:", err)
		conn.Write(errCommandReadFailed)
		return
	}

	// Handle actions that do not require a valid user here.
	if req.Action == "AddUser" {
		if fs.Exists("rubble/users/" + req.User + ".tkn") {
			loggit(log, req, "Failed: User already exists.")
			conn.Write(errUserExists)
			return
		}

		if req.Token == nil {
			loggit(log, req, "Failed: No token provided.")
			conn.Write(errCommandFailed)
			return
		}

		err := fs.WriteAll("rubble/users/"+req.User+".tkn", (*req.Token)[:])
		if err != nil {
			loggit(log, req, "Failed: "+err.Error())
			conn.Write(errCommandFailed)
			return
		}

		loggit(log, req, "OK!")
		conn.Write(rOK)
		return
	}
	if req.Action == "Info" {
		meta := packs.LookUp(req.PackID, req.HostVer)
		if meta == nil {
			loggit(log, req, "Failed: Could not find match.")
			conn.Write(errNoMatchingPack)
			return
		}

		conn.Write(rOK)
		out, err := json.Marshal(meta)
		if err != nil {
			loggit(log, req, "Failed: "+err.Error())
			conn.Write(errCommandFailed)
			return
		}
		binary.Write(conn, binary.BigEndian, int64(len(out)))
		conn.Write(out)
		loggit(log, req, "OK!")
		return
	}
	if req.Action == "List" {
		list := packs.List(req.HostVer)
		if err != nil {
			loggit(log, req, "Failed: "+err.Error())
			conn.Write(errCommandFailed)
			return
		}

		conn.Write(rOK)
		out, err := json.Marshal(list)
		if err != nil {
			loggit(log, req, "Failed: "+err.Error())
			conn.Write(errCommandFailed)
			return
		}
		binary.Write(conn, binary.BigEndian, int64(len(out)))
		conn.Write(out)
		loggit(log, req, "OK!")
		return
	}

	if !login.Validate(req.User, req.Token, fs) {
		loggit(log, req, "Failed: Invalid user name or token.")
		conn.Write(errInvalidUser)
		return
	}

	if req.Action == "Upload" {
		err := packs.AddFromUrl(req.PackID, req.PackVer, req.PackURL, req.User, fs)
		if err != nil {
			loggit(log, req, "Failed: "+err.Error())
			conn.Write(errCommandFailed)
			return
		}

		loggit(log, req, "OK!")
		conn.Write(rOK)
		return
	}
	if req.Action == "Delete" {
		err := packs.Remove(req.PackID, req.PackVer, fs)
		if err != nil {
			loggit(log, req, "Failed: "+err.Error())
			conn.Write(errCommandFailed)
			return
		}
		loggit(log, req, "OK!")
		conn.Write(rOK)
		return
	}
	conn.Write(errBadCommand)
}

func makeRCode(code string) []byte {
	rtn := make([]byte, 1, len(code)+1)
	rtn[0] = byte(len(code))
	return append(rtn, code...)
}

var errBadCommand = makeRCode("ERR-BAD-COMMAND")
var errCommandReadFailed = makeRCode("ERR-COMMAND-READ-FAILED")
var errUserExists = makeRCode("ERR-USER-EXISTS")
var errInvalidUser = makeRCode("ERR-INVALID-USER")
var errNoMatchingPack = makeRCode("ERR-NO-MATCHING-PACK")
var errCommandFailed = makeRCode("ERR-COMMAND-FAILED")
var rOK = makeRCode("OK")

func loggit(log rblutil.Logger, req *SrvrRequest, status string) {
	log.Printf(`  [%v] A: "%v" U: "%v" P: "%v" DF: 0.%v.%v Rubble: %v.%v.%v Status: %v
`, time.Now().UTC().Format("06/01/02 15:04:05"), req.Action, req.User, req.PackID, req.HostVer.DFMajor, req.HostVer.DFPatch, req.HostVer.RblRewrite, req.HostVer.RblMajor, req.HostVer.RblPatch, status)
}
