
local ores = {
	IRON = true,
	NICKEL = true,
	GOLD = true,
	SILVER = true,
	COPPER = true,
	LEAD = true,
	ZINC = true,
	TIN = true,
	PLATINUM = true,
	BISMUTH = true,
	ALUMINUM = true,
}

rubble.fileaction(rubble.filters.inorganic, function(file)
	rubble.print("    "..file.Name.."\n")
	
	file.Content = rubble.rparse.walk(file.Content, function(tag)
		if tag.ID == "METAL_ORE" and not tag.CommentsOnly then
			if ores[tag.Params[1]] then
				if tonumber(tag.Params[2]) < 100 then
					tag.Comments = "[REACTION_CLASS:"..tag.Params[1].."_ORE_POOR]"..tag.Comments
				else
					tag.Comments = "[REACTION_CLASS:"..tag.Params[1].."_ORE]"..tag.Comments
				end
				tag.CommentsOnly = true
			end
		end
	end)
end)
