
local _ENV = rubble.mkmodule("libs_get_tile_material")

--[[
	This module contains functions for finding the material of a tile.
	
	There is a function that will find the material of the tile based on it's type (in other words
	it will return the material DF is using for that tile), and there are functions that will attempt
	to return only a certain class of materials.
	
	Most users will be most interested in the generic "GetTileMat" function, but the other functions
	should be useful in certain cases. For example "GetLayerMat" will always return the material of
	the stone (or soil) in the current layer, ignoring any veins or other inclusions.
	
	Some tile types/materials have special behavior with the "GetTileMat" function.
	
	* Open space and other "material-less" tiles (such as semi-molten rock or eerie glowing pits)
	  will return nil.
	* Ice will return the hard-coded water material ("WATER:NONE").
	* Grass is ignored.
	
	The specialized functions will return nil if a material of their type is not possible for a tile.
	For example calling "GetVeinMat" for a tile that does not have (and has never had) a mineral vein
	will always return nil.
	
	There are two functions for dealing with constructions, one to get the material of the construction
	and one that gets the material of the tile the construction was built over.
	
	I am not sure how caved in tiles are handled, but after some quick testing it appears that the
	game creates mineral veins for them. I am not 100% sure if these functions will reliably work
	with all caved in tiles, but I can confirm that they do in at least some cases...
]]

-- GetLayerMat returns the layer material for the given tile.
-- AFAIK this will never return nil.
function GetLayerMat(x, y, z)
	local pos = nil
	if y == nil and z == nil then
		pos = x
	else
		pos = {x = x, y = y, z = z}
	end
	
	local region_info = dfhack.maps.getRegionBiome(dfhack.maps.getTileBiomeRgn(pos))
	local map_block = dfhack.maps.ensureTileBlock(pos)
	
	local biome = df.world_geo_biome.find(region_info.geo_index)
	
	local layer_index = map_block.designation[pos.x%16][pos.y%16].geolayer_index
	local layer_mat_index = biome.layers[layer_index].mat_index
	
	return dfhack.matinfo.decode(0, layer_mat_index)
end

-- GetLavaStone returns the biome lava stone material (generally obsidian).
function GetLavaStone(x, y, z)
	local pos = nil
	if y == nil and z == nil then
		pos = x
	else
		pos = {x = x, y = y, z = z}
	end
	
	local regions = df.global.world.world_data.region_details
	
	local rx, ry = dfhack.maps.getTileBiomeRgn(pos)
	
	for _, region in ipairs(regions) do
		if region.pos.x == rx and region.pos.y == ry then
			return dfhack.matinfo.decode(0, region.lava_stone)
		end
	end
	return nil
end

-- GetVeinMat returns the vein material of the given tile or nil if the tile has no veins.
-- Multiple veins in one tile should be handled properly (smallest vein type, last in the list wins,
-- which seems to be the rule DF uses).
function GetVeinMat(x, y, z)
	local pos = nil
	if y == nil and z == nil then
		pos = x
	else
		pos = {x = x, y = y, z = z}
	end
	
	local region_info = dfhack.maps.getRegionBiome(dfhack.maps.getTileBiomeRgn(pos))
	local map_block = dfhack.maps.ensureTileBlock(pos)
	
	local events = {}
	for _, event in ipairs(map_block.block_events) do
		if getmetatable(event) == "block_square_event_mineralst" then
			if dfhack.maps.getTileAssignment(event.tile_bitmask, pos.x, pos.y) then
				table.insert(events, event)
			end
		end
	end
	
	if #events == 0 then
		return nil
	end
	
	local event_priority = function(event)
		if event.flags.cluster then
			return 1
		elseif event.flags.vein then
			return 2
		elseif event.flags.cluster_small then
			return 3
		elseif event.flags.cluster_one then
			return 4
		else
			return 5
		end
	end
	
	local priority = events[1]
	for _, event in ipairs(events) do
		if event_priority(event) >= event_priority(priority) then
			priority = event
		end
	end
	
	return dfhack.matinfo.decode(0, priority.inorganic_mat)
end

-- GetConstructionMat returns the material of the construction at the given tile or nil if the tile
-- has no construction.
function GetConstructionMat(x, y, z)
	local pos = nil
	if y == nil and z == nil then
		pos = x
	else
		pos = {x = x, y = y, z = z}
	end
	
	for _, construction in ipairs(df.global.world.constructions) do
		if construction.pos.x == pos.x and construction.pos.y == pos.y and construction.pos.z == pos.z then
			return dfhack.matinfo.decode(construction)
		end
	end
	return nil
end

-- GetConstructOriginalTileMat returns the material of the tile under the construction at the given
-- tile or nil if the tile has no construction.
function GetConstructOriginalTileMat(x, y, z)
	local pos = nil
	if y == nil and z == nil then
		pos = x
	else
		pos = {x = x, y = y, z = z}
	end
	
	for _, construction in ipairs(df.global.world.constructions) do
		if construction.pos.x == pos.x and construction.pos.y == pos.y and construction.pos.z == pos.z then
			return GetTileTypeMat(construction.original_tile, pos)
		end
	end
	return nil
end

-- GetTreeMat returns the material of the tree at the given tile or nil if the tile does not have a
-- tree or giant mushroom.
-- Currently roots are ignored.
function GetTreeMat(x, y, z)
	local pos = nil
	if y == nil and z == nil then
		pos = x
	else
		pos = {x = x, y = y, z = z}
	end
	
	local function coordInTree(pos, tree)
		local x1 = tree.pos.x - math.floor(tree.tree_info.dim_x / 2)
		local x2 = tree.pos.x + math.floor(tree.tree_info.dim_x / 2)
		local y1 = tree.pos.y - math.floor(tree.tree_info.dim_y / 2)
		local y2 = tree.pos.y + math.floor(tree.tree_info.dim_y / 2)
		local z1 = tree.pos.z
		local z2 = tree.pos.z + tree.tree_info.body_height
		
		if not ((pos.x >= x1 and pos.x <= x2) and (pos.y >= y1 and pos.y <= y2) and (pos.z >= z1 and pos.z <= z2)) then
			return false
		end
		
		return not tree.tree_info.body[pos.z - tree.pos.z]:_displace((pos.y - y1) * tree.tree_info.dim_x + (pos.x - x1)).blocked
	end
	
	for _, tree in ipairs(df.global.world.plants.all) do
		if tree.tree_info ~= nil then
			if coordInTree(pos, tree) then
				return dfhack.matinfo.decode(419, tree.material)
			end
		end
	end
	return nil
end

-- GetShrubMat returns the material of the shrub at the given tile or nil if the tile does not
-- contain a shrub or sapling.
function GetShrubMat(x, y, z)
	local pos = nil
	if y == nil and z == nil then
		pos = x
	else
		pos = {x = x, y = y, z = z}
	end
	
	for _, shrub in ipairs(df.global.world.plants.all) do
		if shrub.tree_info == nil then
			if shrub.pos.x == pos.x and shrub.pos.y == pos.y and shrub.pos.z == pos.z then
				return dfhack.matinfo.decode(419, shrub.material)
			end
		end
	end
	return nil
end

-- GetFeatureMat returns the material of the feature (adamantine tube, underworld surface, etc) at
-- the given tile or nil if the tile is not made of a feature stone.
function GetFeatureMat(x, y, z)
	local pos = nil
	if y == nil and z == nil then
		pos = x
	else
		pos = {x = x, y = y, z = z}
	end
	
	local map_block = dfhack.maps.ensureTileBlock(pos)
	
	if df.tiletype.attrs[map_block.tiletype[pos.x%16][pos.y%16]].material ~= df.tiletype_material.FEATURE then
		return nil
	end
	
	if map_block.designation[pos.x%16][pos.y%16].feature_local then
		-- adamantine tube, etc
		for id, idx in ipairs(df.global.world.features.feature_local_idx) do
			if idx == map_block.local_feature then
				return dfhack.matinfo.decode(df.global.world.features.map_features[id])
			end
		end
	elseif map_block.designation[pos.x%16][pos.y%16].feature_global then
		-- cavern, magma sea, underworld, etc
		for id, idx in ipairs(df.global.world.features.feature_global_idx) do
			if idx == map_block.global_feature then
				return dfhack.matinfo.decode(df.global.world.features.map_features[id])
			end
		end
	end
	
	return nil
end

local function fixedMat(id)
	local mat = dfhack.matinfo.find(id)
	return function(x, y, z)
		return mat
	end
end

-- GetTileMat will return the material of the specified tile as determined by its tile type and the
-- world geology data, etc.
-- The returned material should exactly match the material reported by DF except in cases where is
-- is impossible to get a material.
function GetTileMat(x, y, z)
	local pos = nil
	if y == nil and z == nil then
		pos = x
	else
		pos = {x = x, y = y, z = z}
	end
	
	local typ = dfhack.maps.getTileType(pos)
	if typ == nil then
		return nil
	end
	
	return GetTileTypeMat(typ, pos)
end

-- GetTileTypeMat is exactly like GetTileMat except it allows you to specify the notional type for
-- the tile. This allows you to see what the tile would be made of it it was a certain type.
-- Unless the tile could be the given type this function will probably return nil.
function GetTileTypeMat(typ, x, y, z)
	local pos = nil
	if y == nil and z == nil then
		pos = x
	else
		pos = {x = x, y = y, z = z}
	end
	
	local type_mat = df.tiletype.attrs[typ].material
	
	local mat_actions = {
		[df.tiletype_material.AIR] = nil, -- Empty
		[df.tiletype_material.SOIL] = GetLayerMat,
		[df.tiletype_material.STONE] = GetLayerMat,
		[df.tiletype_material.FEATURE] = GetFeatureMat,
		[df.tiletype_material.LAVA_STONE] = GetLavaStone,
		[df.tiletype_material.MINERAL] = GetVeinMat,
		[df.tiletype_material.FROZEN_LIQUID] = fixedMat("WATER:NONE"),
		[df.tiletype_material.CONSTRUCTION] = GetConstructionMat,
		[df.tiletype_material.GRASS_LIGHT] = GetLayerMat,
		[df.tiletype_material.GRASS_DARK] = GetLayerMat,
		[df.tiletype_material.GRASS_DRY] = GetLayerMat,
		[df.tiletype_material.GRASS_DEAD] = GetLayerMat,
		[df.tiletype_material.PLANT] = GetShrubMat,
		[df.tiletype_material.HFS] = nil, -- Eerie Glowing Pit
		[df.tiletype_material.CAMPFIRE] = GetLayerMat,
		[df.tiletype_material.FIRE] = GetLayerMat,
		[df.tiletype_material.ASHES] = GetLayerMat,
		[df.tiletype_material.MAGMA] = nil, -- SMR
		[df.tiletype_material.DRIFTWOOD] = GetLayerMat,
		[df.tiletype_material.POOL] = GetLayerMat,
		[df.tiletype_material.BROOK] = GetLayerMat,
		[df.tiletype_material.ROOT] = GetLayerMat,
		[df.tiletype_material.TREE] = GetTreeMat,
		[df.tiletype_material.MUSHROOM] = GetTreeMat,
		[df.tiletype_material.UNDERWORLD_GATE] = nil, -- I guess this is for the gates found in vaults?
	}
	
	local mat_getter = mat_actions[type_mat]
	if mat_getter == nil then
		return nil
	end
	return mat_getter(pos)
end

return _ENV
