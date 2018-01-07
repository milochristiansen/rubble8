
rubble.template("!COLOR_DEF", [[
	local id, fbi, rgb = rubble.targs({...}, {"", "", ""})
	
	local data = rubble.registry["Libs/Colors"]
	
	if data.table[id] ~= nil then
		rubble.error("Color: "..id.." already exists.")
	else
		data.table[id] = #data.list+1
		data:listappend(id)
		data:listappend(fbi)
		data:listappend(rgb)
	end
]])

rubble.template("!SHARED_COLOR_DEF", [[
	local id, fbi, rgbraws = rubble.targs({...}, {"", "", ""})
	
	local data = rubble.registry["Libs/Colors"]
	
	if data.table[id] ~= nil then
		rubble.error("Color: "..id.." already exists.")
	else
		data.table[id] = #data.list+1
		data:listappend(id)
		data:listappend(fbi)
		data:listappend(id)
		rubble.registry["Libs/Colors:RAWS"]:listappend("{!SHARED_COLOR;"..id..";"..rgbraws.."}")
	end
]])

rubble.template("!SHARED_COLOR_DEFS_INSERT", [[
	local data = rubble.registry["Libs/Colors:RAWS"]
	if data.table["once"] == nil then
		data.table["once"] = "t"
		
		local out = ""
		for _, v in ipairs(data.list) do
			out = out.."\n"..v.."\n"
		end
		return rubble.parse(out)
	else
		return "!SHARED_COLOR_DEFS_INSERT already called elsewhere. Don't worry, your colors are properly inserted, just not here."
	end
]])

rubble.template("@COLOR", [[
	local fg, bg, args = nil, nil, {...}
	if #args > 1 then
		fg, bg = rubble.targs(args, {"", ""})
	else
		fg = rubble.targs(args, {""})
	end
	
	local data = rubble.registry["Libs/Colors"]
	
	
	if bg == nil then
		local idx = data.table[fg]
		if idx == nil then
			rubble.error("Foreground color: "..fg.." is not defined.")
		end
		return data.list[idx+2]
	end
	
	if bg == "-" then
		local idx = data.table[fg]
		if idx == nil then
			rubble.error("Foreground color: "..fg.." is not defined.")
		end
		return data.list[idx+1]..":0"
	end
	
	local fidx = data.table[fg]
	if fidx == nil then
		rubble.error("Foreground color: "..fg.." is not defined.")
	end
	local bidx = data.table[bg]
	if bidx == nil then
		rubble.error("Background color: "..bg.." is not defined.")
	end
	return data.list[fidx+1]..":"..data.list[bidx+1]..":0"
]])

rubble.usertemplate("@COLOR_MATTAGS", {{"fg", ""}, {"bg", ""}},
	"[DISPLAY_COLOR:{@COLOR;%fg;%bg}][STATE_COLOR:ALL:{@COLOR;%fg}]")
