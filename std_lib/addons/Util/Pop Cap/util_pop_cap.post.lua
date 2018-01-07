
axis.write("out/init.d/user_dfhack_pop_cap.lua", [[
-- "User/DFHack/Pop Cap" DFHack Lua Script

population_cap = population_cap or df.global.d_init.population_cap
strict_population_cap = strict_population_cap or df.global.d_init.strict_population_cap
baby_cap_absolute = baby_cap_absolute or df.global.d_init.baby_cap_absolute
baby_cap_percent = baby_cap_percent or df.global.d_init.baby_cap_percent
visitor_cap = visitor_cap or df.global.d_init.visitor_cap

population_cap_new = "]]..rubble.configvar("population_cap")..[["
strict_population_cap_new = "]]..rubble.configvar("strict_population_cap")..[["
baby_cap_absolute_new = "]]..rubble.configvar("baby_cap_absolute")..[["
baby_cap_percent_new = "]]..rubble.configvar("baby_cap_percent")..[["
visitor_cap_new = "]]..rubble.configvar("visitor_cap")..[["

function onUnload()
	print("User/DFHack/Pop Cap: Restoring global pop cap data.")
	df.global.d_init.population_cap = population_cap
	df.global.d_init.strict_population_cap = strict_population_cap
	df.global.d_init.baby_cap_absolute = baby_cap_absolute
	df.global.d_init.baby_cap_percent = baby_cap_percent
	df.global.d_init.visitor_cap = visitor_cap
end

print("User/DFHack/Pop Cap: Setting per-world pop cap data.")
df.global.d_init.population_cap = tonumber(population_cap_new) or population_cap
df.global.d_init.strict_population_cap = tonumber(strict_population_cap_new) or strict_population_cap
df.global.d_init.baby_cap_absolute = tonumber(baby_cap_absolute_new) or baby_cap_absolute
df.global.d_init.baby_cap_percent = tonumber(baby_cap_percent_new) or baby_cap_percent
df.global.d_init.visitor_cap = tonumber(visitor_cap_new) or visitor_cap

dfhack.run_script("fix/population-cap")
]])
