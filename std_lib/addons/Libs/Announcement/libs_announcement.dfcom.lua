-- Display an announcement and write it to the game log.

--[[
Rubble Announcement DFHack Command

Copyright 2013-2014 Milo Christiansen

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

local helpstring = [[ Display an announcement and write it to the game log.
  announce message|? [color]
    message  The message you want to display.
    color    The color to display the message in.
    ?        Print this help.
]]

if not dfhack.isMapLoaded() then
	dfhack.printerr('Map is not loaded.')
	return
end

local args = {...}

local text = args[1]
if not text or text == "?" then
	print(helpstring)
	return
end

local color = _G[args[2]]
if not color then color = COLOR_WHITE end
	
dfhack.gui.showAnnouncement(text, color)
dfhack.gui.writeToGamelog(text)
