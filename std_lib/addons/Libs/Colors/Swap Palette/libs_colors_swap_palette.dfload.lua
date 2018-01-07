--[[
Rubble Color Palette Switcher

Copyright 2016 Milo Christiansen

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
]]

local mapingsA = {
	["BLACK"] = 0,
	["BLUE"] = 1,
	["GREEN"] = 2,
	["CYAN"] = 3,
	["RED"] = 4,
	["MAGENTA"] = 5,
	["BROWN"] = 6,
	["LGRAY"] = 7,
	["DGRAY"] = 8,
	["LBLUE"] = 9,
	["LGREEN"] = 10,
	["LCYAN"] = 11,
	["LRED"] = 12,
	["LMAGENTA"] = 13,
	["YELLOW"] = 14,
	["WHITE"] = 15,
}

local mapingsB = {
	["R"] = 0,
	["G"] = 1,
	["B"] = 2,
}

local function LoadPalette(path)
	print("Attempting to load color palette from: \""..path.."\"")
	
	local file, err = io.open(path, "rb")
	if file == nil then
		print("  Load failed: "..err)
		return false
	end
	
	local contents = file:read("*a")
	file:close()
	
	-- Keep track of the old colors so we can revert to them if we have trouble parsing the new color file.
	local revcolors = {}
	for a = 0, 15, 1 do
		revcolors[a] = {}
		for b = 0, 2, 1 do
			revcolors[a][b] = df.global.enabler.ccolor[a][b]
		end
	end
	
	-- If only I could use the Rubble raw parser here... Oh well, I suppose regular expressions will do almost as well.
	for a, b, v in string.gmatch(contents, "%[([A-Z]+)_([RGB]):([0-9]+)%]") do
		local ka, kb, v = mapingsA[a], mapingsB[b], tonumber(v)
		if ka == nil or kb == nil or v == nil then
			-- Parse error, revert changes.
			for x = 0, 15, 1 do
				for y = 0, 2, 1 do
					df.global.enabler.ccolor[x][y] = revcolors[x][y]
				end
			end
			print("  Load failed: Color file parse error (changes reverted).")
			return false
		end
		
		if v == 0 then
			df.global.enabler.ccolor[ka][kb] = 0
		else
			v = v / 255
			if v > 1 then
				print("  Warning: The "..b.." component for color "..a.." is out of range! Adjusting value.")
				v = 1
			end
			df.global.enabler.ccolor[ka][kb] = v
		end
	end
	return true
end

LoadPalette(dfhack.getSavePath().."/raw/colors.txt")

function OnUnload()
	LoadPalette(dfhack.getDFPath().."/data/init/colors.txt")
end
