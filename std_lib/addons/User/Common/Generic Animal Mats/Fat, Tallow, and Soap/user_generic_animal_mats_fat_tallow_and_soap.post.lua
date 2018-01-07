
print "    Fixing Tissues..."

local tissues = {
	["FAT_TEMPLATE"] = true,
	["TALLOW_TEMPLATE"] = true,
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

print "    Fixing Material Templates..."

local mats = {
	["FAT_TEMPLATE"] = "RENDER_MAT",
	["TALLOW_TEMPLATE"] = "SOAP_MAT",
}

rubble.fileaction(rubble.filters.material_template, function(file)
	local found = false
	
	file.Content = rubble.rparse.walk(file.Content, function(tag)
		if tag.ID == "MATERIAL_TEMPLATE" and not tag.CommentsOnly then
			found = mats[tag.Params[1]]
		end
		
		if tag.ID == "MATERIAL_REACTION_PRODUCT" and not tag.CommentsOnly and found then
			tag.Params = {found, "CREATURE_MAT", "ANIMAL", tag.Params[2]}
		end
	end)
end)
