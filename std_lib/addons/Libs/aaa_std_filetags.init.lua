
-- Some helpful predefined filters.
rubble.filters = {
	raw	= {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true
	},
	graphics_raw = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=true,  AUXText=false, RawFile=true
	},
	b_detail_plan = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, BodyDetailRaws=true
	},
	body = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, BodyRaws=true
	},
	building = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, BuildingRaws=true
	},
	c_variation = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, CreatureVarRaws=true
	},
	creature = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, CreatureRaws=true
	},
	descriptor = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, DescriptorRaws=true
	},
	entity = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, EntityRaws=true
	},
	inorganic = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, InorganicRaws=true
	},
	interaction = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, InteractionRaws=true
	},
	item = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, ItemRaws=true
	},
	language = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, LanguageRaws=true
	},
	material_template = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, MatTemplateRaws=true
	},
	plant = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, PlantRaws=true
	},
	reaction = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, ReactionRaws=true
	},
	tissue_template = {
		Skip=false, NoWrite=false, TileSet=false, CreatureGraphics=false, AUXText=false, RawFile=true, TissueRaws=true
	},
}

local possibletypes = {
	["b_detail_plan_"] = "BodyDetailRaws",
	["body_"] = "BodyRaws",
	["building_"] = "BuildingRaws",
	["c_variation_"] = "CreatureVarRaws",
	["creature_"] = "CreatureRaws",
	["descriptor_"] = "DescriptorRaws",
	["entity_"] = "EntityRaws",
	["inorganic_"] = "InorganicRaws",
	["interaction_"] = "InteractionRaws",
	["item_"] = "ItemRaws",
	["language_"] = "LanguageRaws",
	["material_template_"] = "MatTemplateRaws",
	["plant_"] = "PlantRaws",
	["reaction_"] = "ReactionRaws",
	["tissue_template_"] = "TissueRaws",
}

print "    Applying extra file tags to raw files."

rubble.fileaction(rubble.filters.raw, function(file)
	for prefix, tag in pairs(possibletypes) do
		if string.hasprefix(file.Name, prefix) then
			file.Tags[tag] = true
		end
	end
end)
