-- Runs periodically and fixes unhanded gloves.

--[[
Rubble Glove Handedness Fix DFHack Script

Copyright 2014 Milo Christiansen

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

local repeatUtil = require 'repeat-util'

hand = hand or 1
gloveTyp = df.item_type["GLOVES"]

local fixHandedness = function()
	local count = 0
	for _,v in ipairs(df.global.world.items.all) do
		if v:getType() == gloveTyp then
			if v:getGloveHandedness() == 0 then
				count = count + 1
				v:setGloveHandedness(hand)
				if hand == 1 then
					hand = 2
				else
					hand = 1
				end
			end
		end
	end
	if count % 2 ~= 0 then
		print("rubble_fix_handedness: Uneven unhanded glove count found!")
	end
	if count ~= 0 then
		print("rubble_fix_handedness: Fixed "..count.." Unhanded gloves.")
	end
end

fixHandedness()
repeatUtil.scheduleEvery("rubble_fix_handedness", 2000, 'ticks', fixHandedness)
