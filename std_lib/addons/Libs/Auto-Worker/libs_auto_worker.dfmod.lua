
_ENV = rubble.mkmodule("libs_auto_worker")

local buildings = require 'plugins.building-hacks'

local function hasJob(wshop, reaction)
	for i = 0, #wshop.jobs - 1, 1 do
		if wshop.jobs[i].reaction_name == reaction then
			return true
		end
	end
	return false
end

local function lastJobLink()
	local link = df.global.world.job_list
	while link.next ~= nil do
		link = link.next
	end
	return link
end

-- Add a job to run the specified reaction at the given workshop, but only
-- if another job to do the same does not exist already.
-- Returns true if the job was added to the workshop.
function AddAutoJob(wshop, reaction, tweak)
	if hasJob(wshop, reaction) then
		return false
	end
	
	-- I think I filled in all the job fields I need...
	
	local job = df.job:new()
	
	job.job_type = df.job_type.CustomReaction
	job.reaction_name = reaction
	
	job.general_refs:insert("#", {new = df.general_ref_building_holderst, building_id = wshop.id})
	wshop.jobs:insert("#", job)
	job.pos.x = wshop.centerx -- Supposedly the work location
	job.pos.y = wshop.centery
	job.pos.z = wshop.z
	
	if tweak ~= nil then
		tweak(job)
	end
	
	dfhack.job.linkIntoWorld(job, true)
	
	return true
end

local function makeMainUpdater(outputs)
	return function(wshop)
		for reaction, check in pairs(outputs) do
			if type(check) == "table" then
				if check[1](wshop) then
					AddAutoJob(wshop, reaction, check[2])
				end
			elseif check(wshop) then
				AddAutoJob(wshop, reaction)
			end
		end
	end
end

-- Register a workshop type with the auto-worker system.
-- * id is the workshop ID
-- * outputs is a table of reactions IDs to functions, the function should return true if it is OK to queue the reaction
--   this update cycle. Advanced users may use a table of two function instead of a single function, the second function
--   is called with the job as a parameter so that extra stuff may be added to the job.
-- * ticks is how many ticks to wait between updates.
function Register(id, outputs, ticks)
	buildings.registerBuilding{
		name = id,
		action = {ticks, makeMainUpdater(outputs)},
	}
end

return _ENV