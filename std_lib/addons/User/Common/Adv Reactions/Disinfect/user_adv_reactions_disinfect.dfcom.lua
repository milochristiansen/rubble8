-- Removes infections from the adventure mode character.

-- I have a generic version of this script, ask if you want it.

unit = df.global.world.units.active[0]

unit.body.infection_level = 0
for _, w in ipairs(unit.body.wounds) do
	w.flags.infection = false
end

unit.flags3.compute_health = true
