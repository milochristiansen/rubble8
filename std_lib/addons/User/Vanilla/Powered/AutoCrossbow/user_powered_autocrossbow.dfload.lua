
local pwshops = rubble.require "workshops_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"
local preact = rubble.require "reaction_libs_powered"

function fireitem(items, wshop, extras)
	local pos = pwshops.Center(wshop)
	local outputs = pwshops.Outputs(wshop)
	
	local item = items[1]
	if item.stack_size == 1 then
		dfhack.items.moveToGround(item, pos)
	else
		item.stack_size = item.stack_size - 1
		local mat = dfhack.matinfo.decode(item.mat_type, item.mat_index)
		local nitem = pitems.CreateItemNumeric(mat, item:getType(), item:getSubtype(), nil, 0)
		nitem.quality = item.quality
		dfhack.items.moveToGround(nitem, pos)
		item = nitem
	end
	
	-- The following is lifted from the Roses Script Collection projectile script.
	local proj = dfhack.items.makeProjectile(item)
	proj.origin_pos.x = pos.x
	proj.origin_pos.y = pos.y
	proj.origin_pos.z = pos.z
	proj.prev_pos.x = pos.x
	proj.prev_pos.y = pos.y
	proj.prev_pos.z = pos.z
	proj.cur_pos.x = pos.x
	proj.cur_pos.y = pos.y
	proj.cur_pos.z = pos.z
	
	-- This *should* cause projectiles to fly towards a random output tile.
	local targetdir = outputs[math.random(#outputs)]
	proj.target_pos.x = targetdir.x
	proj.target_pos.y = targetdir.y
	proj.target_pos.z = targetdir.z
	
	proj.flags.no_impact_destroy = false
	proj.flags.bouncing = false
	proj.flags.piercing = true
	proj.flags.parabolic = false
	proj.flags.unk9 = false
	proj.flags.no_collide = false
	-- Need to figure out these numbers!!!
	proj.distance_flown = 0 -- Self explanatory
	proj.fall_threshold = 40 -- Seems to be able to hit units further away with larger numbers
	proj.min_hit_distance = 1 -- Seems to be unable to hit units closer than this value
	proj.min_ground_distance = 30 -- No idea
	proj.fall_counter = 0 -- No idea
	proj.fall_delay = 0 -- No idea
	proj.hit_rating = 70 -- I think this is how likely it is to hit a unit (or to go where it should maybe?)
	proj.unk22 = 20 -- Velocity?
	proj.speed_x = 0
	proj.speed_y = 0
	proj.speed_z = 0
end

-- Should work to fire ANY kind of ammo, a good use for all those arrows you got from the elves.
preact.AddRecipe("DFHACK_POWERED_AUTOCROSSBOW", {
	validate = pfilter.Item("AMMO:NONE"),
	output_item = fireitem,
})

-- I have no idea if this works or not, I need to make a bigger workshop and give it a test...
--preact.AddRecipe("DFHACK_POWERED_AUTOCROSSBOW", {
--	validate = pfilter.Item("SIEGEAMMO:NONE"),
--	output_item = fireitem,
--})

pwshops.Register("DFHACK_POWERED_AUTOCROSSBOW", nil, 15, 0, 50, preact.MakeHandler("DFHACK_POWERED_AUTOCROSSBOW", {
	mangle_item = pdisaster.Switch({
		-- If the item is not hard then 1% chance of damage and rot it if possible, else pass it.
		{pfilter.Not(pfilter.MatFlag("ITEMS_HARD")), pdisaster.Damage(1, pdisaster.RotItem(pdisaster.PassItem))},
		
		-- Any other (invalid) item gives a 10% chance of damage, and the item is passed.
		{pfilter.Dummy, pdisaster.Damage(10, pdisaster.PassItem)},
	}),
	mangle_unit = pdisaster.MangleCreature,
}), 1, 1, {94, 7,0,0}, {94, 0,7,0})
