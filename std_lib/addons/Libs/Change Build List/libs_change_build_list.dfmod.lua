
local _ENV = rubble.mkmodule("libs_change_build_list")

--[[
	-- Examples:
	
	-- Remove the carpenters workshop.
	ChangeBuilding("CARPENTERS", "WORKSHOPS", false)
	
	-- Make it impossible to build walls.
	ChangeBuildingAdv(df.building_type.Construction, df.construction_type.Wall, -1, "CONSTRUCTIONS", false)
	
	-- Add the mechanic's workshops to the machines category.
	ChangeBuilding("MECHANICS", "MACHINES", true, "CUSTOM_E")
]]

local buildings = rubble.require "libs_buildings"

local category_name_to_id = {
	["MAIN_PAGE"] = 0,
	["SIEGE_ENGINES"] = 1,
	["TRAPS"] = 2,
	["WORKSHOPS"] = 3,
	["FURNACES"] = 4,
	["CONSTRUCTIONS"] = 5,
	["MACHINES"] = 6,
	["CONSTRUCTIONS_TRACK"] = 7,
}

--[[
	{
		category = 0, -- The menu category id (from category_name_to_id)
		add = true, -- Are we adding a workshop or removing one?
		id = {
			-- The building IDs.
			type = 0,
			subtype = 0,
			custom = 0,
		},
	}
]]
stuffToChange = {}

-- Returns true if DF would normally allow you to build a workshop or furnace.
-- Use this if you want to change a building, but only if it is permitted in the current entity.
function IsEntityPermitted(id)
	local wshop = buildings.GetWShopType(id)
	
	-- It's hard coded, so yes, of course it's permitted, why did you even ask?
	if wshop.custom == -1 then
		return true
	end
	
	local entsrc = df.historical_entity.find(df.global.ui.civ_id)
	if entsrc == nil then
		return false
	end
	local entity = entsrc.entity_raw
	
	for _, bid in ipairs(entity.workshops.permitted_building_id) do
		if wshop.custom == bid then
			return true
		end
	end
	return false
end

function RevertBuildingChanges(id, category)
	local wshop = buildings.GetWShopType(id)
	if wshop == nil then
		qerror("RevertBuildingChanges: Invalid workshop ID: "..id)
	end
	
	RevertBuildingChangesAdv(wshop.type, wshop.subtype, wshop.custom, category)
end

function RevertBuildingChangesAdv(typ, subtyp, custom, category)
	local cat
	if tonumber(category) ~= nil then
		cat = tonumber(category)
	else
		cat = category_name_to_id[category]
		if cat == nil then
			qerror("ChangeBuilding: Invalid category ID: "..category)
		end
	end
	
	for i = #stuffToChange, 1, -1 do
		local change = stuffToChange[i]
		if change.category == cat then
			if typ == change.id.type and subtyp == change.id.subtype and custom == change.id.custom then
				table.remove(stuffToChange, i)
			end
		end
	end
end

function ChangeBuilding(id, category, add, key)
	local cat
	if tonumber(category) ~= nil then
		cat = tonumber(category)
	else
		cat = category_name_to_id[category]
		if cat == nil then
			qerror("ChangeBuilding: Invalid category ID: "..category)
		end
	end
	
	local wshop = buildings.GetWShopType(id)
	if wshop == nil then
		qerror("ChangeBuilding: Invalid workshop ID: "..id)
	end
	
	if tonumber(key) == nil then
		key = df.interface_key[key]
	end
	if key == nil then
		key = 0
	end
	
	ChangeBuildingAdv(wshop.type, wshop.subtype, wshop.custom, category, add, key)
end

function ChangeBuildingAdv(typ, subtyp, custom, category, add, key)
	local cat
	if tonumber(category) ~= nil then
		cat = tonumber(category)
	else
		cat = category_name_to_id[category]
		if cat == nil then
			qerror("ChangeBuilding: Invalid category ID: "..category)
		end
	end
	
	if tonumber(key) == nil then
		key = df.interface_key[key]
	end
	if key == nil then
		key = 0
	end
	
	table.insert(stuffToChange, {
		category = cat,
		add = add,
		key = key,
		id = {
			type = typ,
			subtype = subtyp,
			custom = custom,
		},
	})
end

-- These two store the values we *think* are in effect, they are used to detect changes.
sidebarLastCat = -1
sidebarIsBuild = false
tickerOn = true

local function checkSidebar()
	-- Needs to be "frames" so it ticks over while paused.
	if tickerOn then
		dfhack.timeout(1, "frames", checkSidebar)
	end
	
	local sidebar = df.global.ui_sidebar_menus.building
	
	if not sidebarIsBuild and df.global.ui.main.mode ~= df.ui_sidebar_mode.Build then
		-- Not in build mode.
		return
	elseif sidebarIsBuild and df.global.ui.main.mode ~= df.ui_sidebar_mode.Build then
		-- Just exited build mode
		sidebarIsBuild = false
		sidebarLastCat = -1
		return
	elseif sidebarIsBuild and sidebar.category_id == sidebarLastCat then
		-- In build mode, but category has not changed since last frame.
		return
	end
	-- Either we just entered build mode or the category has changed.
	sidebarIsBuild = true
	sidebarLastCat = sidebar.category_id
	
	-- Changes made here do not persist, they need to be made every time the side bar is shown.
	-- Will just deleting stuff cause a memory leak? (probably, but how can it be avoided?)
	
	local stufftoremove = {}
	local stufftoadd = {}
	for i, btn in ipairs(sidebar.choices_all) do
		if getmetatable(btn) == "interface_button_construction_building_selectorst" then
			for _, change in ipairs(stuffToChange) do
				if not change.add and sidebar.category_id == change.category and 
				btn.building_type == change.id.type and btn.building_subtype == change.id.subtype and
				btn.custom_type == change.id.custom then
					table.insert(stufftoremove, i)
				end
			end
		end
	end
	for _, change in ipairs(stuffToChange) do
		if sidebar.category_id == change.category and change.add then
			table.insert(stufftoadd, change)
		end
	end
	
	-- Do the actual adding and removing.
	-- We need to iterate the list backwards to keep from invalidating the stored indexes.
	for x = #stufftoremove, 1, -1 do
		-- AFAIK item indexes always match (except for one extra item at the end of "choices_all").
		local i = stufftoremove[x]
		sidebar.choices_visible:erase(i)
		sidebar.choices_all:erase(i)
	end
	for _, change in ipairs(stufftoadd) do
		local button = df.interface_button_construction_building_selectorst:new()
		button.hotkey_id = change.key
		button.building_type = change.id.type
		button.building_subtype = change.id.subtype
		button.custom_type = change.id.custom
		
		local last = #sidebar.choices_visible
		sidebar.choices_visible:insert(last, button)
		sidebar.choices_all:insert(last, button)
	end
end
checkSidebar()

function onUnload()
	-- This will kill the ticker in the frame after this returns.
	-- No need to clear the change table, as it (and all the other parts of this script) will go to
	-- the land of the garbage collector shortly after this returns (I love garbage collection).
	tickerOn = false
end

return _ENV
