
_ENV = rubble.mkmodule('libs_buildings_replace_add_job')

local buildings = rubble.require "libs_dfhack_buildings"

local eventful = require 'plugins.eventful'

local gui = require 'gui'
local guidm = require 'gui.dwarfmode'
local widgets = require 'gui.widgets'

local ws = require 'dfhack.workshops'

workshopJobOverlay = defclass(workshopJobOverlay, guidm.WorkshopOverlay)
workshopJobOverlay.menulvl = 0
workshopJobOverlay.menuTable = {}

workshopJobOverlay.ATTRS {
	wshop = DEFAULT_NIL,
	frame_inset = 1,
	frame_background = COLOR_BLACK,
}

--[[
-- Menu Table Structure:

-- Each entry in the menu table will have one extra key added, `callback` will be used to store
-- temporary callback functions wrapping `data`.
menu_table = {
	{
		text = 'item name',
		key = 'CUSTOM_A',
		data = callback_function_or_menu_table,
	},
}

function callback_function(wshop)
	-- Do whatever you want (generally adding a job to the workshop).
	
	-- The menu will close as soon as this returns.
end

-- Usage Example:

raddjob.Register("SOME_WORKSHOP", {
	{
		text = 'menu a',
		key = 'CUSTOM_A',
		data = {
			{
				text = 'run some reaction',
				key = 'CUSTOM_R',
				data = raddjob.AddReaction("SOME_REACTION_ID"),
			},
			-- ...
		},
	},
	{
		text = 'menu b',
		key = 'CUSTOM_B',
		data = {
			-- ...
		},
	},
})

]]

-- Register a replacement add-job menu to a particular workshop ID.
function Register(wshopid, menuTable)
	local function queryfocus()
		local wshop = dfhack.gui.getSelectedBuilding()
		if wshop and buildings.GetWShopID(wshop.getType(), wshop.getSubtype(), wshop.getCustomType()) == wshopid then
			if dfhack.gui.getFocusString(dfhack.gui.getCurViewscreen()) == "dwarfmode/QueryBuilding/Some/Workshop/AddJob" then
				workshopJobOverlay{
					wshop = wshop,
					menuTable = menuTable,
				}:show()
				dfhack.timeout_active(timer, nil)
				return
			end
			timer = dfhack.timeout(1, 'frames', queryFocus)
		else
			dfhack.timeout_active(timer, nil)
			return
		end
	end
	
	local function callback(wshop)
		timer = dfhack.timeout(1, 'frames', queryFocus)
	end
	
	eventful.registerSidebar(wshopid, callback, true)
end

-- Add a reaction to a workshop as a job.
-- This function returns a callback function for use in the menu table.
-- 
-- This may not work with all reactions, but it should cover common cases.
-- 
-- Most users will probably want to provide a custom version of this with more/other
-- customization options.
-- 
-- Currently known unhandled cases:
-- * Reactions with the FUEL tag.
function AddReaction(reactionID)
	return function(wshop)
		-- No point in caching this, as it will only be called when the game is paused.
		local rid, reaction = nil, nil
		for i, v in ipairs(df.global.world.raws.reactions) do
			if v.code == reactionID then
				rid, reaction = i, v
				break
			end
		end
		
		local job = df.job:new()
		job.id = df.global.job_next_id   
		df.global.job_next_id = df.global.job_next_id + 1
		dfhack.job.linkIntoWorld(job, true)
		
		job_fields = {
			job_type = df.job_type.CustomReaction,
			reaction_name = reactionID, 
			mat_type = -1,
			mat_index = -1,
		}
		job:assign(job_fields)
		job.general_refs:insert("#", {new = df.general_ref_building_holderst, building_id = wshop.id})
		
		-- Reaction reagents need some more fields before they can be used in the job.
		for id, reagent in pairs(reaction.reagents) do
			local jitem = utils.clone_with_default(reagent, ws.input_filter_defaults)
			jitem.reaction_id = rid
			jitem.reagent_index = id
			jitem.new = true
			job.job_items:insert('#', jitem)
		end
		
		-- TODO: Handle FUEL reactions.
		-- AFAIK it is impossible to get this far with an unpowered magma workshop, so all that
		-- needs to be done is check to see if the workshop is a magma workshop and add a bar of
		-- fuel to the list of job items if not.
		
		wshop.jobs:insert("#", job)
	end
end

function workshopJobOverlay:init(args)
	self:processMenuTable(self.menuTable)
	
	self:addviews{
		widgets.Label{
			frame = { l = 0, t = 0 },
			text = {
				{ text = 'workshop',}
			}
		},
		widgets.List{
			view_id = 'list',
			frame = { l = 0, r = 0, t = 2 },
			on_submit = self:callback('onSubmitItem'),
			scroll_keys = widgets.SECONDSCROLL,
		},
		widgets.Label{
			view_id = 'back',
			frame = { l = 0, b = 0 },
			text = {
				{
					key = 'LEAVESCREEN',
					text = ': Back',
					on_activate = self:callback('dismiss'),
				}
			}
		},
	}
	self:initListChoices()
end

-- This transforms the menu table so all entries have proper call backs.
function workshopJobOverlay:processMenuTable(menuTable)
	for k, v in pairs(menuTable) do
		if not v.data then
			error "Malformed menu table (missing data)."
		elseif type(v.data) == "table" then
			self:processMenuTable(v.data)
			menuTable[k].callback = self:callback('makeMenu', k, v.data)
		elseif type(v.data) == "function" then
			menuTable[k].callback = self:callback('makeCallback', v.data)
		else
			error "Malformed menu table (invalid data type)."
		end
	end
end

function workshopJobOverlay:makeMenu(key, menuTable)
	self:pushContext(""..key, menuTable)
end

function workshopJobOverlay:makeCallback(callback)
	callback(wshop)
	self:dismiss()
end

function workshopJobOverlay:pushContext(name, choices)
	if not self.back_stack then
		self.back_stack = {}
		self.menulvl = 0
	else
		table.insert(self.back_stack, {
			context_str = self.context_str,
			all_choices = self.subviews.list:getChoices(),
			selected = self.subviews.list:getSelected(),
		})
		self.menulvl = self.menulvl + 1
	end
	self.context_str = name
	self.subviews.list:setChoices(choices, 1)
end


function workshopJobOverlay:onGoBack()
	local save = table.remove(self.back_stack)
	self.menulvl = self.menulvl - 1
	self.context_str = save.context_str
	self.subviews.list:setChoices(save.all_choices)
end


function workshopJobOverlay:onSubmitItem(idx, item)
	if item.callback then
		item:callback(idx)
	end
end

function workshopJobOverlay:onInput(keys)
	if keys.LEAVESCREEN or keys.LEAVESCREEN_ALL then
		if self.menulvl ~= 0 and not keys.LEAVESCREEN_ALL then
			self:onGoBack()
		else
			self:dismiss()
			if self.on_cancel then
				self.on_cancel()
			end
		end
	else
		self:inputToSubviews(keys)
	end
end


function workshopJobOverlay:onDestroy()
	if self.on_close then
		self.on_close()
	end
end

-- If we submit a job choice, we don't want to leave the whole workshop, so we just re-enter it :)
function workshopJobOverlay:on_close()
	gui.simulateInput(dfhack.gui.getCurViewscreen(), 'LEAVESCREEN')
	gui.simulateInput(dfhack.gui.getCurViewscreen(), 'D_BUILDJOB')
end

return _ENV
