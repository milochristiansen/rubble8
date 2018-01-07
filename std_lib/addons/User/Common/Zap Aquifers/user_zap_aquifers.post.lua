
rubble.fileaction(rubble.filters.inorganic, function(file)
	file.Content = rubble.rparse.walk(file.Content, function(tag)
		if tag.ID == "AQUIFER" and not tag.CommentsOnly then
			tag.Comments = "-AQUIFER-"..tag.Comments
			tag.CommentsOnly = true
		end
	end)
end)
