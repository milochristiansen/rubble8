
local ores = {
	IRON = true,
}

rubble.fileaction(rubble.filters.inorganic, function(file)
	rubble.print("    "..file.Name.."\n")
	
	file.Content = rubble.rparse.walk(file.Content, function(tag)
		if tag.ID == "METAL_ORE" and not tag.CommentsOnly then
			if ores[tag.Params[1]] then
				tag.Comments = "[REACTION_CLASS:"..tag.Params[1].."_ORE]"..tag.Comments
				tag.CommentsOnly = true
			end
		end
	end)
end)
