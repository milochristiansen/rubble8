
local pwshops = rubble.require "workshops_libs_powered"
local pswitch = rubble.require "switchable_libs_powered"

function isInput(x, y, z, cb, wshop)
	if cb == nil then
		return
	end
	
	local pos = pwshops.Center(wshop)
	if getmetatable(cb) == "building_axle_horizontalst" then
		if (cb.is_vertical == true and (x == pos.x)) or (cb.is_vertical == false and (y == pos.y)) then
			return true
		end
	elseif getmetatable(cb) == "building_axle_verticalst" then
		if cb.z ~= pos.z and x == pos.x and y == pos.y then
			return true
		end
	end
	return false
end

-- only works with single tile workshops
function findInputs(wshop)
	local offsets = {
		{x = 1, y = 0, z = 0},
		{x = -1, y = 0, z = 0},
		{x = 0, y = 1, z = 0},
		{x = 0, y = -1, z = 0},
		{x = 0, y = 0, z = 1}
	}
	local pos = pwshops.Center(wshop)
	local inputs = {}
	
	for _, off in pairs(offsets) do
		local cb = dfhack.buildings.findAtTile(pos.x + off.x, pos.y + off.y, pos.z + off.z)
		if isInput(pos.x + off.x, pos.y + off.y, pos.z + off.z, cb, wshop) then
			table.insert(inputs, cb)
		end
	end
	return inputs
end

function makeLogicGate(gatetyp)
	return function(wshop)
		local inputs = findInputs(wshop)
		local outputs = pswitch.Switchables(wshop)
		
		if #inputs == 0 or #outputs == 0 then
			return
		end
		
		local pI = false
		local uI = false
		for _, input in ipairs(inputs) do
			if input.machine.machine_id ~= -1 then
				-- Cache inputs?
				local machine = df.machine.find(input.machine.machine_id)
				if machine.flags.active then
					pI = true
				else
					uI = true
				end
				if pI and uI then
					break
				end
			end
		end
		
		if not pI and not uI then
			-- No valid inputs
			-- This is probably impossible
			return
		end
		
		local command = false
		if gatetyp == "AND" then
			command = pI and not uI
		elseif gatetyp == "OR" then
			command = pI
		elseif gatetyp == "NOT" then
			command = not pI
		elseif gatetyp == "XOR" then
			command = pI and uI
		end
		
		for _, output in ipairs(outputs) do
			pswitch.SwitchBuilding(output, command)
		end
	end		
end

local outputs = {
	"AND",
	"OR",
	"NOT",
	"XOR"
}

pwshops.Register("DFHACK_POWERED_LOGIC_GATES", outputs, 0, 0, 10, makeLogicGate)
