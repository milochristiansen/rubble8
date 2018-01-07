
--[[
Rubble Persistent Timeout DFHack Lua Command

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

local utils = require 'utils'
local timeout = rubble.require 'libs_timeout'

validArgs = validArgs or utils.invert({
	'help',
	'id',
	'delete',
	'delay',
	'command',
	'list'
})

local args = utils.processArgs({...}, validArgs)

if args.help then
	print([[scripts/rubble_timeout

Create and manage persistent timeouts, eg timeouts that will survive a save/load.

Arguments:
    -help
        print this help message.
	-list
		Updates the persistence data and dumps the result to the console.
    -id
		The id to use for the delay (required!).
	-delete
		If specified removes an action instead of adding one.
    -delay
        How long to wait in ticks (defaults to 100).
	-command
		The command to run (as a string! defaults to `:lua print("rubble_timeout: Did we forget something?")`).

]])
	return
end

if args.list then
	print(timeout.dumppersist())
	return
end

if not args.id then
	error "rubble_timeout: You MUST specify an id!"
end

if not args.delay or not tonumber(args.delay) then
	args.delay = 100
end

if not args.command then
	args.command = ':lua print("rubble_timeout: Did we forget something?")'
end

if not args.delete then
	timeout.add(args.id, tonumber(args.delay), args.command)
else
	timeout.del(args.id)
end
