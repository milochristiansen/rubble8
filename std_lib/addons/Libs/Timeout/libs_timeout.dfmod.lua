
--[[
Rubble Persistent Timeout DFHack Lua Pseudo Module

Copyright 2014-2015 Milo Christiansen

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

local _ENV = rubble.mkmodule("libs_timeout")

local data = {}
local dellist = nil
local rawdata = dfhack.persistent.get("rubble_libs_timeout")

if rawdata == nil then
	rawdata, _ = dfhack.persistent.save({key = "rubble_libs_timeout"})
else
	local f, err = load(rawdata.value)
	if f == nil then
		error(err)
	end
	data = f()
	if data == nil then
		data = {}
	end
end

function dumppersist()
	savepersist()
	return rawdata.value
end

function savepersist()
	local out = "return {\n"
	for k, v in pairs(data) do
		if v ~= nil then
			out = out..'\t["'..k..'"] = {'
			out = out..' delay = '..v.delay..','
			out = out..' command = [[ '..v.command..' ]]'
			out = out..' },\n'
		end
	end
	out = out.."}"
	rawdata.value = out
	rawdata:save()
end

function add(id, delay, command)
	--print("Timeout: "..id.." Added.")
	if dellist ~= nil then
		dellist[id] = false
	end
	data[id] = {delay = delay, command = command}
	savepersist()
end

function del(id)
	--print("Timeout: "..id.." Deleted.")
	data[id] = nil
	savepersist()
end

function onUnload()
	savepersist()
	data = {}
end

function tick()
	dellist = {}
	for k, v in pairs(data) do
		if v ~= nil then
			v.delay = v.delay - 1
			if v.delay <= 0 then
				--print("Timeout: "..k.." Triggered.")
				dellist[k] = true
				dfhack.run_command(v.command)
			end
		end
	end
	
	for k, v in pairs(dellist) do
		if v then
			del(k)
		end
	end
	dellist = nil
	
	dfhack.timeout(1, 'ticks', tick)
end
tick()

return _ENV
