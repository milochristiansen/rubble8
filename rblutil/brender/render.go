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

// Rubble Workshop Renderer.
//
// This package has tools for parsing and rendering Dwarf Fortress workshops.
package brender

import "image"
import "image/color"
import "image/draw"

func Render(wshop *Building, stg int, tileset image.Image) image.Image {
	bounds := tileset.Bounds()
	tileW := (bounds.Max.Y - bounds.Min.Y) / 16
	tileH := (bounds.Max.X - bounds.Min.X) / 16

	var tiles [256]image.Point
	for i := 0; i < 256; i++ {
		tiles[i] = image.Pt((i%16)*tileH, (i/16)*tileW)
	}

	wshopimg := image.NewRGBA(image.Rect(0, 0, tileW*wshop.W, tileH*wshop.H))
	for x := range wshop.Tiles {
		for y := range wshop.Tiles[x] {
			tile := image.Rect(x*tileW, y*tileH, x*tileW+tileW, y*tileH+tileH)

			// Fill tile with background color
			draw.Draw(wshopimg, tile, stdcolors[wshop.Tiles[x][y][stg].BG], image.ZP, draw.Src)

			// Then draw the character
			draw.DrawMask(wshopimg, tile, stdcolors[wshop.Tiles[x][y][stg].FG], image.ZP, tileset,
				tiles[wshop.Tiles[x][y][stg].Tile], draw.Over)
		}
	}
	return wshopimg
}

var stdcolors = [16]image.Image{
	//                                                                // C I AC Name
	image.NewUniform(color.RGBA{R: 0x00, G: 0x00, B: 0x00, A: 0xFF}), // 0 0 00 Black
	image.NewUniform(color.RGBA{R: 0x00, G: 0x00, B: 0x80, A: 0xFF}), // 1 0 01 Blue
	image.NewUniform(color.RGBA{R: 0x00, G: 0x80, B: 0x00, A: 0xFF}), // 2 0 02 Green
	image.NewUniform(color.RGBA{R: 0x00, G: 0x80, B: 0x80, A: 0xFF}), // 3 0 03 Cyan
	image.NewUniform(color.RGBA{R: 0x80, G: 0x00, B: 0x00, A: 0xFF}), // 4 0 04 Red
	image.NewUniform(color.RGBA{R: 0x80, G: 0x00, B: 0x80, A: 0xFF}), // 5 0 05 Magenta
	image.NewUniform(color.RGBA{R: 0x80, G: 0x80, B: 0x00, A: 0xFF}), // 6 0 06 Brown
	image.NewUniform(color.RGBA{R: 0xC0, G: 0xC0, B: 0xC0, A: 0xFF}), // 7 0 07 Light Gray
	image.NewUniform(color.RGBA{R: 0x80, G: 0x80, B: 0x80, A: 0xFF}), // 0 1 08 Dark Gray
	image.NewUniform(color.RGBA{R: 0x00, G: 0x00, B: 0xFF, A: 0xFF}), // 1 1 09 Light Blue
	image.NewUniform(color.RGBA{R: 0x00, G: 0xFF, B: 0x00, A: 0xFF}), // 2 1 10 Light Green
	image.NewUniform(color.RGBA{R: 0x00, G: 0xFF, B: 0xFF, A: 0xFF}), // 3 1 11 Light Cyan
	image.NewUniform(color.RGBA{R: 0xFF, G: 0x00, B: 0x00, A: 0xFF}), // 4 1 12 Light Red
	image.NewUniform(color.RGBA{R: 0xFF, G: 0x00, B: 0xFF, A: 0xFF}), // 5 1 13 Light Magenta
	image.NewUniform(color.RGBA{R: 0xFF, G: 0xFF, B: 0x00, A: 0xFF}), // 6 1 14 Yellow
	image.NewUniform(color.RGBA{R: 0xFF, G: 0xFF, B: 0xFF, A: 0xFF}), // 7 1 15 White
}
