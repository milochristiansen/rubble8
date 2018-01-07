
print "    Fixing Tissues..."

local tissues = {
	["NERVE_TEMPLATE"] = true,
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

print "    Fixing Creatures..."

rubble.fileaction(rubble.filters.creature, function(file)
	file.Content = rubble.rparse.walk(file.Content, function(tag)
		if (tag.ID == "TENDONS" or tag.ID == "LIGAMENTS") and not tag.CommentsOnly then
			if #tag.Params == 3 then
				tag.Params = {"CREATURE_MAT", "ANIMAL", "SINEW", tag.Params[3]}
			else
				print "      TENDONS or LIGAMENTS tag in creature has non-standard argument count."
				print "        This is probably OK so ignoring."
			end
		end
	end)
end)
