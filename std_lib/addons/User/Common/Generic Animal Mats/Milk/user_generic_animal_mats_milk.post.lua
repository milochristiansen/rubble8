
print "    Fixing Creatures..."

rubble.fileaction(rubble.filters.creature, function(file)
	file.Content = rubble.rparse.walk(file.Content, function(tag)
		if tag.ID == "MILKABLE" and not tag.CommentsOnly then
			if #tag.Params == 3 then
				tag.Params = {"CREATURE_MAT", "ANIMAL", "MILK", "LIQUID"}
			else
				print "      MILKABLE tag in creature has non-standard argument count."
				print "        This is probably OK so ignoring."
			end
		end
	end)
end)

print "    Fixing Material Templates..."

local mats = {
	["MILK_TEMPLATE"] = "CHEESE_MAT",
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
