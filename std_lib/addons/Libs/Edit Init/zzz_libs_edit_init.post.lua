
function merge(regkey, toptag, path)
	local data = rubble.registry[regkey]
	if #data.list > 0 then
		local objects, objlist = {}, {}
		
		-- Try to read the existing file (this may fail, as it is possible for this file to be missing).
		-- If reading the file succeeds then separate it into a list of objects.
		local ok, file = axis.read(path)
		if ok then
			local object, id = {}, ""
			for _, tag in ipairs(rubble.rparse.parse(file)) do
				if tag.ID == toptag then
					if id ~= "" then
						objects[id] = object
						table.insert(objlist, id)
					end
					object = {}
				elseif tag.ID == "TITLE" then
					id = tag.Params[1]
				else
					table.insert(object, tag)
				end
			end
			if id ~= "" then
				objects[id] = object
				table.insert(objlist, id)
			end
		end
		
		-- Add the first tag of the new file (to hold the leading whitespace)
		local tag = rubble.rparse.newtag()
		tag.CommentsOnly = true
		tag.Comments = "\n"
		local tags = {tag}
		
		-- Add any existing objects for which there are no replacements.
		for _, id in ipairs(objlist) do
			if data.table[id] == nil then
				tag = rubble.rparse.newtag()
				tag.ID = toptag
				tag.Comments = "\n\t"
				table.insert(tags, tag)
				
				tag = rubble.rparse.newtag()
				tag.ID = "TITLE"
				tag.Params = {id}
				tag.Comments = "\n\t"
				table.insert(tags, tag)
				
				for _, tag in ipairs(objects[id]) do
					if not tag.CommentsOnly then
						tag.Comments = "\n\t"
						table.insert(tags, tag)
					end
				end
				tags[#tags].Comments = "\n\n"
			end
		end
		
		-- Add any new objects.
		local ids = rubble.inverttable(data.table)
		for idx, raws in ipairs(data.list) do
			local id = ids[idx..""]
			
			tag = rubble.rparse.newtag()
			tag.ID = toptag
			tag.Comments = "\n\t"
			table.insert(tags, tag)
			
			tag = rubble.rparse.newtag()
			tag.ID = "TITLE"
			tag.Params = {id}
			tag.Comments = "\n\t"
			table.insert(tags, tag)
			
			for _, tag in ipairs(rubble.rparse.parse(raws)) do
				if not tag.CommentsOnly then
					tag.Comments = "\n\t"
					table.insert(tags, tag)
				end
			end
			tags[#tags].Comments = "\n\n"
		end
		
		-- If there are no objects then don't write anything.
		if #tags == 1 then
			return
		end
		
		-- Write the result.
		tags[#tags].Comments = "\n"
		axis.write(path, rubble.rparse.format(tags))
	end
end

merge("Libs/Base:ADD_WORLDGEN_PARAM", "WORLD_GEN", "df/data/init/world_gen.txt")
merge("Libs/Base:ADD_EMBARK_PROFILE", "PROFILE", "df/data/init/embark_profiles.txt")
