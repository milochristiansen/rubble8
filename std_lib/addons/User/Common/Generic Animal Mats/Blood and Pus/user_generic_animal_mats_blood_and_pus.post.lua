
print "    Fixing Creatures..."

rubble.fileaction(rubble.filters.creature, function(file)
	file.Content = rubble.rparse.walk(file.Content, function(tag)
		if (tag.ID == "BLOOD" or tag.ID == "PUS") and not tag.CommentsOnly then
			if #tag.Params == 3 then
				tag.Params = {"CREATURE_MAT", "ANIMAL", tag.Params[2], "LIQUID"}
			else
				print "      BLOOD or PUS tag in creature has non-standard argument count."
				print "        This is probably OK so ignoring."
			end
		end
	end)
end)
