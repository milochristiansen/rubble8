
_ENV = mkmodule("libs_edit_init")

function addworldgen(id, raws)
	local data = rubble.registry["Libs/Base:ADD_WORLDGEN_PARAM"]
	if data.table[id] == nil then
		data.table[id] = #data.list+1
	end
	data:listappend(raws)
end

function addembarkprofile(id, raws)
	local data = rubble.registry["Libs/Base:ADD_EMBARK_PROFILE"]
	if data.table[id] == nil then
		data.table[id] = #data.list+1
	end
	data:listappend(raws)
end

return _ENV
