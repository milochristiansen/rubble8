/*
Copyright 2015-2018 by Milo Christiansen

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

package brender

import "fmt"

import "errors"
import "regexp"
import "strconv"

import "github.com/milochristiansen/rubble8/rblutil/rparse"

// Isolate isolates a single building definition in a parsed raw file.
// Returns an empty slice if the building was not found.
func Isolate(target string, tags []*rparse.Tag) []*rparse.Tag {
	out := make([]*rparse.Tag, 0)

	found := false
	for _, tag := range tags {
		if tag.ID == "BUILDING_WORKSHOP" || tag.ID == "BUILDING_FURNACE" {
			found = tag.Params[0] == target
		}
		if found {
			out = append(out, tag)
		}
	}

	return out
}

var buildingWshop = regexp.MustCompile("{[^;]+_WORKSHOP;([^;]+);[^};]+[};]")
var buildingFurnace = regexp.MustCompile("{[^;]+_FURNACE;([^;]+);[^};]+[};]")

// Fix replaces several common Rubble templates with the equivalent raw tags so the building
// parser can properly find/read the building.
func Fix(in string) string {
	in = buildingWshop.ReplaceAllString(in, "[BUILDING_WORKSHOP:$1]")
	return buildingFurnace.ReplaceAllString(in, "[BUILDING_FURNACE:$1]")
}

type Tile struct {
	FG, BG int
	Tile   int
	Mat    bool
}

type Building struct {
	// Building size
	W, H int

	// The work location
	WX, WY int

	// Blocking tiles: x, y
	Block [][]bool

	// x, y, stage
	Tiles [][][4]Tile
}

func (wshop *Building) String() string {
	out := fmt.Sprintf("\t[DIM:%v:%v]\n\t[WORK_LOCATION:%v:%v]\n", wshop.W, wshop.H, wshop.WX, wshop.WY)

	for y := 0; y < wshop.H; y++ {
		out += fmt.Sprintf("\t[BLOCK:%v", y)
		for x := 0; x < wshop.W; x++ {
			if wshop.Block[x][y] {
				out += ":1"
			} else {
				out += ":0"
			}
		}
		out += "]\n"
	}

	for stg := 0; stg < 4; stg++ {
		// TILE
		for y := 0; y < wshop.H; y++ {
			out += fmt.Sprintf("\t[TILE:%v:%v", stg, y)
			for x := 0; x < wshop.W; x++ {
				out += fmt.Sprintf(":%v", wshop.Tiles[x][y][stg].Tile)
			}
			out += "]\n"
		}
		// COLOR
		for y := 0; y < wshop.H; y++ {
			out += fmt.Sprintf("\t[TILE:%v:%v", stg, y)
			for x := 0; x < wshop.W; x++ {
				if wshop.Tiles[x][y][stg].Mat {
					out += ":MAT"
				} else {
					out += fmt.Sprintf(":%v:%v:0", wshop.Tiles[x][y][stg].FG, wshop.Tiles[x][y][stg].BG)
				}
			}
			out += "]\n"
		}
	}
	return out
}

func parseInt8(in string) int {
	i, _ := strconv.ParseInt(in, 10, 9)
	return int(i)
}

func parseTile(in string) int {
	if len(in) == 3 && in[0] == '\'' && in[2] == '\'' {
		return int(in[1])
	}
	return parseInt8(in)
}

// Parse parses a building.
func Parse(tags []*rparse.Tag, matFG, matBG int) (*Building, error) {
	wshop := new(Building)

	for _, tag := range tags {
		if tag.ID == "DIM" {
			wshop.W = parseInt8(tag.Params[0])
			wshop.H = parseInt8(tag.Params[1])

			wshop.Tiles = make([][][4]Tile, wshop.W)
			for i := range wshop.Tiles {
				wshop.Tiles[i] = make([][4]Tile, wshop.H)
			}

			wshop.Block = make([][]bool, wshop.W)
			for i := range wshop.Block {
				wshop.Block[i] = make([]bool, wshop.H)
			}
		}

		if tag.ID == "WORK_LOCATION" {
			wshop.WX = parseInt8(tag.Params[0])
			wshop.WY = parseInt8(tag.Params[1])
		}

		if tag.ID == "BLOCK" {
			if len(tag.Params) != wshop.W+1 {
				return nil, errors.New("BLOCK tag with invalid length.")
			}

			y := parseInt8(tag.Params[0])
			y--
			if y < 0 || y >= wshop.H {
				return nil, errors.New("BLOCK tag Y value out of range.")
			}

			for x := 1; x < len(tag.Params); x++ {
				if tag.Params[x] == "1" {
					wshop.Block[x-1][y] = true
				}
			}
		}

		if tag.ID == "TILE" {
			if len(tag.Params) != wshop.W+2 {
				return nil, errors.New("TILE tag with invalid length.")
			}

			stg := parseInt8(tag.Params[0])

			y := parseInt8(tag.Params[1])
			y--
			if y < 0 || y >= wshop.H {
				return nil, errors.New("TILE tag Y value out of range.")
			}

			for x := 2; x < len(tag.Params); x++ {
				wshop.Tiles[x-2][y][stg].Tile = parseTile(tag.Params[x])
			}
		}

		if tag.ID == "COLOR" {
			stg := parseInt8(tag.Params[0])

			y := parseInt8(tag.Params[1])
			y--
			if y < 0 || y >= wshop.H {
				return nil, errors.New("COLOR tag Y value out of range.")
			}

			j := 2
			for x := 0; x < len(wshop.Tiles); x++ {
				if tag.Params[j] == "MAT" {
					wshop.Tiles[x][y][stg].FG = matFG
					wshop.Tiles[x][y][stg].BG = matBG
					wshop.Tiles[x][y][stg].Mat = true
					j++
					continue
				}

				if len(tag.Params) < j+3 {
					return nil, errors.New("COLOR tag with invalid length.")
				}

				wshop.Tiles[x][y][stg].FG = parseInt8(tag.Params[j])
				j++
				wshop.Tiles[x][y][stg].BG = parseInt8(tag.Params[j])
				j++
				wshop.Tiles[x][y][stg].FG += parseInt8(tag.Params[j]) * 8
				j++
			}
		}
	}
	return wshop, nil
}
