
local howmanyW = tonumber(rubble.configvar("DEV_DUMMY_WSHOPS_COUNT"))
if howmanyW == nil then
	howmanyW = 5
end

local howmanyF = tonumber(rubble.configvar("DEV_DUMMY_WSHOPS_FURNACE_COUNT"))
if howmanyF == nil then
	howmanyF = 5
end

local out = '[OBJECT:BUILDING]\n\nThe following are "dummy" workshops and furnaces used to add content after worldgen.\n'

for count = 1, howmanyW, 1 do
	out = out.."\n{BUILDING_WORKSHOP;DUMMY_WSHOP_"..count..[[;ADDON_HOOK_PLAYABLE}
	# Replace this with your building body.
	[NAME:Dummy Workshop]
	[NAME_COLOR:7:0:1]
	[DIM:1:1]
	[WORK_LOCATION:1:1]
	[BLOCK:1:0]
	[TILE:0:1:'d']
	[COLOR:0:1:7:0:0]
	[TILE:1:1:'D']
	[COLOR:1:1:7:0:0]
]]
end

for count = 1, howmanyF, 1 do
	out = out.."\n{BUILDING_FURNACE;DUMMY_FURNACE_"..count..[[;ADDON_HOOK_PLAYABLE}
	# Replace this with your building body.
	[NAME:Dummy Workshop]
	[NAME_COLOR:7:0:1]
	[DIM:1:1]
	[WORK_LOCATION:1:1]
	[BLOCK:1:0]
	[TILE:0:1:'d']
	[COLOR:0:1:7:0:0]
	[TILE:1:1:'D']
	[COLOR:1:1:7:0:0]
]]
end

rubble.files["building_zzz_dev_dummy_wshops.txt"].Content = out
