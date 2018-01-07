
print "    Fixing Tissues..."

local tissues = {
	["HAIR_TEMPLATE"] = true,
	["CHEEK_WHISKERS_TEMPLATE"] = true,
	["CHIN_WHISKERS_TEMPLATE"] = true,
	["MOUSTACHE_TEMPLATE"] = true,
	["SIDEBURNS_TEMPLATE"] = true,
	["EYEBROW_TEMPLATE"] = true,
	["EYELASH_TEMPLATE"] = true,
	["FEATHER_TEMPLATE"] = true,
}

rubble.fileaction(rubble.filters.tissue_template, function(file)
	local found = false
	
	file.Content = rubble.rparse.walk(file.Content, function(tag)
		if tag.ID == "TISSUE_TEMPLATE" and not tag.CommentsOnly then
			found = tissues[tag.Params[1]]
		end
		
		if tag.ID == "TISSUE_MATERIAL" and tag.Params[1] == "LOCAL_CREATURE_MAT" and not tag.CommentsOnly and found then
			tag.Params = {"CREATURE_MAT", "ANIMAL", tag.Params[2]}
		end
	end)
end)
