
function upgradebuilding(pos, typ)
	local bldg = dfhack.buildings.findAtTile(pos)
	
	-- Change building to new building
	local ctype = nil
	for _, x in ipairs(df.global.world.raws.buildings.all) do
		if x.code == typ then ctype = x.id end
	end
	if ctype == nil then 
		error 'Cant find upgrade building!'
		return
	end
	
	bldg.custom_type = ctype
end

local utils = require 'utils'

validArgs = validArgs or utils.invert({
	'help',
	'loc',
	'type',
})

local args = utils.processArgs({...}, validArgs)

if args.help then
	print([[scripts/rubble_change-building

Change a workshop from one kind to annother.

Arguments:
    -help
        print this help message.
    -loc [ x y z ]
        Where to do the action (defaults to cursor location).
    -type
        ID of the building to change into.
]])
	return
end

local pos = df.coord:new();
if args.loc then
	pos.x = tonumber(args.loc[1] or 'a')
	pos.y = tonumber(args.loc[2] or 'a')
	pos.z = tonumber(args.loc[3] or 'a')
end
if not pos.x or not pos.y or not pos.z then
	pos = df.global.cursor
end
if pos.x == -30000 then
	error "Invalid position: Drop a cursor or specify coords on the command line."
end

if not args.type then
	error "Please specify a building id."
end

upgradebuilding(pos, args.type)
