
print "    Fixing Tissues..."

local tissues = {
	["MUSCLE_TEMPLATE"] = true,
	["EYE_TEMPLATE"] = true,
	["BRAIN_TEMPLATE"] = true,
	["LUNG_TEMPLATE"] = true,
	["HEART_TEMPLATE"] = true,
	["LIVER_TEMPLATE"] = true,
	["GUT_TEMPLATE"] = true,
	["STOMACH_TEMPLATE"] = true,
	["GIZZARD_TEMPLATE"] = true,
	["PANCREAS_TEMPLATE"] = true,
	["SPLEEN_TEMPLATE"] = true,
	["KIDNEY_TEMPLATE"] = true,
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
