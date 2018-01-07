
rubble.template("!ADD_WORLDGEN_PARAM", function(id, raws)
	id, raws = rubble.expandargs(id, raws)
	
	return "{ADD_WORLDGEN_PARAM;"..id..";"..rubble.parse(raws).."}"
end)

rubble.template("ADD_WORLDGEN_PARAM", function(id, raws)
	id, raws = rubble.expandargs(id, raws)
	
	return "{#ADD_WORLDGEN_PARAM;"..id..";"..rubble.parse(raws).."}"
end)

rubble.template("#ADD_WORLDGEN_PARAM", function(id, raws)
	id, raws = rubble.expandargs(id, raws)
	
	local data = rubble.registry["Libs/Base:ADD_WORLDGEN_PARAM"]
	if data.table[id] == nil then
		data.table[id] = #data.list+1
	end
	data:listappend(raws)
end)

rubble.template("!ADD_EMBARK_PROFILE", function(id, raws)
	id, raws = rubble.expandargs(id, raws)
	
	return "{ADD_EMBARK_PROFILE;"..id..";"..rubble.parse(raws).."}"
end)

rubble.template("ADD_EMBARK_PROFILE", function(id, raws)
	id, raws = rubble.expandargs(id, raws)
	
	return "{#ADD_EMBARK_PROFILE;"..id..";"..rubble.parse(raws).."}"
end)

rubble.template("#ADD_EMBARK_PROFILE", function(id, raws)
	id, raws = rubble.expandargs(id, raws)
	
	local data = rubble.registry["Libs/Base:ADD_EMBARK_PROFILE"]
	if data.table[id] == nil then
		data.table[id] = #data.list+1
	end
	data:listappend(raws)
end)
