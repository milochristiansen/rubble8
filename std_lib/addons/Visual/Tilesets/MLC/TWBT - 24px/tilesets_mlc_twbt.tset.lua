
local shapes = {
	"FloorTrackN",
	"FloorTrackS",
	"FloorTrackE",
	"FloorTrackW",
	"FloorTrackNS",
	"FloorTrackNE",
	"FloorTrackNW",
	"FloorTrackSE",
	"FloorTrackSW",
	"FloorTrackEW",
	"FloorTrackNSE",
	"FloorTrackNSW",
	"FloorTrackNEW",
	"FloorTrackSEW",
	"FloorTrackNSEW",
	"RampTrackN",
	"RampTrackS",
	"RampTrackE",
	"RampTrackW",
	"RampTrackNS",
	"RampTrackNE",
	"RampTrackNW",
	"RampTrackSE",
	"RampTrackSW",
	"RampTrackEW",
	"RampTrackNSE",
	"RampTrackNSW",
	"RampTrackNEW",
	"RampTrackSEW",
	"RampTrackNSEW",
}

local mats = {
	"Constructed",
	"Feature",
	"Frozen",
	"Lava",
	"Mineral",
	"Stone",
}

-- Shape -> tile number in d_init file
local shape_to_dtile = {
	FloorTrackN = "208",
	FloorTrackS = "210",
	FloorTrackE = "198",
	FloorTrackW = "181",
	FloorTrackNS = "186",
	FloorTrackNE = "200",
	FloorTrackNW = "188",
	FloorTrackSE = "201",
	FloorTrackSW = "187",
	FloorTrackEW = "205",
	FloorTrackNSE = "204",
	FloorTrackNSW = "185",
	FloorTrackNEW = "202",
	FloorTrackSEW = "203",
	FloorTrackNSEW = "206",
	RampTrackN = "30",
	RampTrackS = "30",
	RampTrackE = "30",
	RampTrackW = "30",
	RampTrackNS = "30",
	RampTrackNE = "30",
	RampTrackNW = "30",
	RampTrackSE = "30",
	RampTrackSW = "30",
	RampTrackEW = "30",
	RampTrackNSE = "30",
	RampTrackNSW = "30",
	RampTrackNEW = "30",
	RampTrackSEW = "30",
	RampTrackNSEW = "30",
}

-- Shape -> tile number on override sheet
local shape_to_otile = {
	FloorTrackN = "64",
	FloorTrackS = "65",
	FloorTrackE = "66",
	FloorTrackW = "67",
	FloorTrackNS = "68",
	FloorTrackNE = "72",
	FloorTrackNW = "73",
	FloorTrackSE = "70",
	FloorTrackSW = "71",
	FloorTrackEW = "69",
	FloorTrackNSE = "77",
	FloorTrackNSW = "78",
	FloorTrackNEW = "76",
	FloorTrackSEW = "75",
	FloorTrackNSEW = "74",
	RampTrackN = "80",
	RampTrackS = "81",
	RampTrackE = "82",
	RampTrackW = "83",
	RampTrackNS = "84",
	RampTrackNE = "88",
	RampTrackNW = "89",
	RampTrackSE = "86",
	RampTrackSW = "87",
	RampTrackEW = "85",
	RampTrackNSE = "93",
	RampTrackNSW = "94",
	RampTrackNEW = "92",
	RampTrackSEW = "91",
	RampTrackNSEW = "90",
}

local tracks = ""
for _, shape in ipairs(shapes) do
	for _, mat in ipairs(mats) do
		tracks = tracks.."[OVERRIDE:"..shape_to_dtile[shape]..":T:"..mat..shape..":ex1:"..shape_to_otile[shape].."]\n"
	end
	tracks = tracks.."\n"
end

rubble.files["tilesets_mlc_twbt.tset.twbt"].Content = [[
[TILESET:MLC 24x24 - Overrides.png:MLC 24x24 - Overrides.png:ex1] 

[OVERRIDE:210:I:CHAIR:::ex1:0]
[OVERRIDE:210:B:CHAIR:::ex1:0]

[OVERRIDE:209:I:TABLE:::ex1:16]
[OVERRIDE:209:B:TABLE:::ex1:16]

[OVERRIDE:197:I:DOOR:::ex1:1]
[OVERRIDE:197:B:DOOR:::ex1:1]

[OVERRIDE:88:I:FLOODGATE:::ex1:2]
[OVERRIDE:88:B:FLOODGATE:::ex1:2]

[OVERRIDE:227:I:CABINET:::ex1:3]
[OVERRIDE:227:B:CABINET:::ex1:3]

[OVERRIDE:233:I:BED:::ex1:4]
[OVERRIDE:233:B:BED:::ex1:4]

[OVERRIDE:155:I:HATCH_COVER:::ex1:5]
[OVERRIDE:155:B:HATCH:::ex1:5]

[OVERRIDE:239:I:SLAB:::ex1:6]
[OVERRIDE:239:B:SLAB:::ex1:6]

[OVERRIDE:48:I:COFFIN:::ex1:7]
[OVERRIDE:48:B:COFFIN:::ex1:7]

[OVERRIDE:234:I:STATUE:::ex1:8]
[OVERRIDE:234:B:STATUE:::ex1:8]

[OVERRIDE:19:I:CAGE:::ex1:9]
[OVERRIDE:19:B:CAGE:::ex1:9]

# Space (1 tile)

[OVERRIDE:251:I:WEAPONRACK:::ex1:11]
[OVERRIDE:251:B:WEAPON_RACK:::ex1:11]

[OVERRIDE:14:I:ARMORSTAND:::ex1:12]
[OVERRIDE:14:B:ARMOR_STAND:::ex1:12]

[OVERRIDE:135:I:TOTEM:::ex1:13]

[OVERRIDE:232:I:TRACTION_BENCH:::ex1:14]
[OVERRIDE:232:B:TRACTION_BENCH:::ex1:14]

[OVERRIDE:88:B:ARCHERY_TARGET:::ex1:15]

[OVERRIDE:15:I:ANY_WEBS:::ex1:17]

[OVERRIDE:21:I:CHAIN:::ex1:18]
[OVERRIDE:21:B:CHAIN:::ex1:18]

[OVERRIDE:73:B:SUPPORT:::ex1:19]

# Is the tile number for this correct?
[OVERRIDE:47:B:WEAPON_UPRIGHT:::ex1:20]

# NS
[OVERRIDE:186:B:AXLE_HORIZONTAL:::ex1:21]
[OVERRIDE:179:B:AXLE_HORIZONTAL:::ex1:22]
# EW
[OVERRIDE:205:B:AXLE_HORIZONTAL:::ex1:23]
[OVERRIDE:196:B:AXLE_HORIZONTAL:::ex1:24]

[OVERRIDE:9:B:AXLE_VERTICAL:::ex1:25]
[OVERRIDE:111:B:AXLE_VERTICAL:::ex1:26]

[OVERRIDE:15:B:GEAR_ASSEMBLY:::ex1:27]
[OVERRIDE:42:B:GEAR_ASSEMBLY:::ex1:28]

[OVERRIDE:94:B:TRAP:::ex1:29]

# Chest/coffer
[OVERRIDE:146:I:BOX:::ex1:30]
[OVERRIDE:146:B:BOX:::ex1:30]

# Bag
[OVERRIDE:11:I:BOX:::ex1:31]
[OVERRIDE:11:B:BOX:::ex1:31]

[OVERRIDE:35:I:GRATE:::ex1:32]
[OVERRIDE:35:B:GRATE_FLOOR:::ex1:32]
[OVERRIDE:215:B:GRATE_WALL:::ex1:33]

[OVERRIDE:215:B:BARS_FLOOR:::ex1:34]
[OVERRIDE:19:B:BARS_VERTICAL:::ex1:35]

[OVERRIDE:176:B:WINDOW_ANY:::ex1:36]

[OVERRIDE:09:B:WELL:::ex1:37]
# under construction :)
[OVERRIDE:111:B:WELL:::ex1:38] 

# All weapons look like swords for now
# It would be good to make a few variations
[OVERRIDE:47:I:WEAPON:::ex1:39]
[OVERRIDE:91:I:SHIELD:::ex1:40]
[OVERRIDE:91:I:ARMOR:::ex1:41]
[OVERRIDE:91:I:SHOES:::ex1:42]
[OVERRIDE:91:I:HELM:::ex1:43]
[OVERRIDE:91:I:GLOVES:::ex1:44]
[OVERRIDE:91:I:PANTS:::ex1:45]

# Space (2 tiles)

# NW Corner
[OVERRIDE:201:B:BRIDGE:::ex1:48]
# NE Corner
[OVERRIDE:187:B:BRIDGE:::ex1:49]
# SW Corner
[OVERRIDE:200:B:BRIDGE:::ex1:50]
# SE Corner
[OVERRIDE:188:B:BRIDGE:::ex1:51]
# N Side
[OVERRIDE:210:B:BRIDGE:::ex1:52]
# S Side
[OVERRIDE:208:B:BRIDGE:::ex1:53]
# E Side
[OVERRIDE:181:B:BRIDGE:::ex1:54]
# W Side
[OVERRIDE:198:B:BRIDGE:::ex1:55]
# NS Side
[OVERRIDE:186:B:BRIDGE:::ex1:56]
# EW Side
[OVERRIDE:205:B:BRIDGE:::ex1:57]
# Single tile
[OVERRIDE:206:B:BRIDGE:::ex1:58]
# Center (smooth)
[OVERRIDE:43:B:BRIDGE:::ex1:59]
# Center (rough)
[OVERRIDE:247:B:BRIDGE:::ex1:60]

# Space (3 tiles)

# Tracks
]]..tracks
