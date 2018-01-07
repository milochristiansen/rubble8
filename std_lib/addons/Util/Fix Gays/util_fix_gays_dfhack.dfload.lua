
local repeatUtil = require 'repeat-util'

local fixGays = function()
	local allUnits = df.global.world.units.active
	for i = #allUnits - 1, 0, -1 do
		local unit = allUnits[i]
		if unit.sex == 0 then
			unit.status.current_soul.orientation_flags.romance_male = false
			unit.status.current_soul.orientation_flags.marry_male = true
			unit.status.current_soul.orientation_flags.romance_female = false
			unit.status.current_soul.orientation_flags.marry_female = false
		elseif unit.sex == 1 then
			unit.status.current_soul.orientation_flags.romance_male = false
			unit.status.current_soul.orientation_flags.marry_male = false
			unit.status.current_soul.orientation_flags.romance_female = false
			unit.status.current_soul.orientation_flags.marry_female = true
		end
	end
end

fixGays()

-- Should trigger once per minute at 100 FPS.
repeatUtil.scheduleEvery("rubble_util_fix_gays", 6000, 'ticks', fixGays)

