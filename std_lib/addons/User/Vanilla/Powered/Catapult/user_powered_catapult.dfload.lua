
local eventful = require "plugins.eventful"
local script = require 'gui.script'

local pwshops = rubble.require "workshops_libs_powered"
local punits = rubble.require "units_libs_powered"
local pitems = rubble.require "items_libs_powered"
local pfilter = rubble.require "filter_libs_powered"
local ppersist = rubble.require "persist_libs_powered"
local pdisaster = rubble.require "disaster_libs_powered"

alreadyAdjusting = false
function launcherAdjust(reaction, reaction_product, unit, in_items, in_reag, out_items, call_native)
	call_native.value = false
	
	if alreadyAdjusting == false then
		alreadyAdjusting = true
		
		script.start(function()
			local thold = "50"
			
			local dir = 0
			repeat
				_, dir = script.showInputPrompt('Catapult Adjust', 'Select the direction in degrees (0-360)', COLOR_LIGHTGREEN, dir)
			until tonumber(dir) and tonumber(dir) >= 0 and tonumber(dir) <= 360
			
			local angle = 0
			repeat
				_, angle = script.showInputPrompt('Catapult Adjust', 'Set the vertical angle (0-90)', COLOR_LIGHTGREEN, angle)
			until tonumber(angle) and tonumber(angle) >= 0 and tonumber(angle) <= 90
			
			local power = 0
			repeat
				_, power = script.showInputPrompt('Catapult Adjust', 'Set the power level (0-270)', COLOR_LIGHTGREEN, power)
			until tonumber(power) and tonumber(power) >= 0 and tonumber(power) <= 270
			
			local wshop = pwshops.MakeFake(unit.pos.x, unit.pos.y, unit.pos.z, 1)
			ppersist.SetOutputType(wshop, "return {dir = "..dir..", angle = "..angle..", power = "..power.."}")
			
			alreadyAdjusting = false
		end)
	end
end


function flingItem(item, settings)
	local proj = dfhack.items.makeProjectile(item)
	proj.origin_pos.x = item.pos.x
	proj.origin_pos.y = item.pos.y
	proj.origin_pos.z = item.pos.z
	proj.prev_pos.x = item.pos.x
	proj.prev_pos.y = item.pos.y
	proj.prev_pos.z = item.pos.z
	proj.cur_pos.x = item.pos.x
	proj.cur_pos.y = item.pos.y
	proj.cur_pos.z = item.pos.z
	
	proj.flags.no_impact_destroy = true
	proj.flags.piercing = true
	proj.flags.parabolic = true
	proj.flags.unk9 = true
	
	local phi = settings.dir * (math.pi / 180)
	local theta = (90 - settings.angle) * (math.pi / 180)
	local radius = settings.power * 1000
	local yc = math.floor(radius * math.sin(theta) * math.cos(phi))
	local xc = math.floor(radius * math.sin(theta) * math.sin(phi))
	local zc = math.floor(radius * math.cos(theta))
	
	proj.speed_x = xc
	proj.speed_y = -yc
	proj.speed_z = zc
end

function flingUnit(unit, settings)
	--[[
		This is why when you make a linked list you use two node types,
		a "head" node and a "body" node.
		
		The head node contains links to both the head and the tail,
		while the body just contains links to the next node and the
		item being stored.
		
		No need for a linear search to find the end of the list when
		inserting, although you do need to update one more link.
	]]
	local l = df.global.world.proj_list
	local lastlist = l
	l = l.next
	local count = 0
	while l do
		count = count + 1
		if l.next == nil then
			lastlist = l
		end
		l = l.next
	end
	
	newlist = df.proj_list_link:new()
	lastlist.next = newlist
	newlist.prev = lastlist
	proj = df.proj_unitst:new()
	newlist.item = proj
	proj.link = newlist
	proj.id = df.global.proj_next_id
	df.global.proj_next_id = df.global.proj_next_id+1
	proj.unit = unit
	proj.origin_pos.x = unit.pos.x
	proj.origin_pos.y = unit.pos.y
	proj.origin_pos.z = unit.pos.z
	proj.prev_pos.x = unit.pos.x
	proj.prev_pos.y = unit.pos.y
	proj.prev_pos.z = unit.pos.z
	proj.cur_pos.x = unit.pos.x
	proj.cur_pos.y = unit.pos.y
	proj.cur_pos.z = unit.pos.z
	
	proj.flags.no_impact_destroy = true
	proj.flags.piercing = true
	proj.flags.parabolic = true
	proj.flags.unk9 = true
	
	local phi = settings.dir * (math.pi / 180)
	local theta = (90 - settings.angle) * (math.pi / 180)
	local radius = settings.power * 1000
	local yc = math.floor(radius * math.sin(theta) * math.cos(phi))
	local xc = math.floor(radius * math.sin(theta) * math.sin(phi))
	local zc = math.floor(radius * math.cos(theta))
	
	proj.speed_x = xc
	proj.speed_y = -yc
	proj.speed_z = zc
	
	unitoccupancy = dfhack.maps.getTileBlock(unit.pos).occupancy[unit.pos.x%16][unit.pos.y%16]
	if not unit.flags1.on_ground then 
		unitoccupancy.unit = false 
	else 
		unitoccupancy.unit_grounded = false
	end
	unit.flags1.projectile=true
	unit.flags1.on_ground=false
end


function makeLaunchThing()
	return function(wshop)
		if pwshops.IsUnpowered(wshop) then
			return
		end
		
		-- Read settings
		local output = ppersist.GetOutputTypeAsCode(wshop)
		if output == nil then
			return
		end
		
		local pos = pwshops.Center(wshop)
		
		-- Try to launch an item
		local item = pitems.FindItemAtInput(wshop, pfilter.Dummy)
		if item ~= nil then
			item.pos.x = pos.x
			item.pos.y = pos.y
			item.pos.z = pos.z
			flingItem(item, output)
			return
		end
		
		-- Otherwise try for a creature
		if pdisaster.EnabledUnits then
			local unit = punits.FindAtWorkshop(wshop)
			if unit ~= nil then
				unit.pos.x = pos.x
				unit.pos.y = pos.y
				unit.pos.z = pos.z
				flingUnit(unit, output)
				return
			end
		end
	end
end

pwshops.Register("DFHACK_POWERED_CATAPULT", nil, 20, 0, 200, makeLaunchThing)

eventful.registerReaction("ADJUST_POWERED_CATAPULT", launcherAdjust)
