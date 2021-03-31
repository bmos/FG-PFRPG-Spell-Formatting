-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local function getReferenceSpell(string_spell_name)
	local is_greater = string.find(string_spell_name:lower(), ', greater')
	local is_lesser = string.find(string_spell_name:lower(), ', lesser')
	local is_communal = string.find(string_spell_name:lower(), ', communal')
	local is_mass = string.find(string_spell_name:lower(), ', mass')

	-- remove tags from spell name
	if is_greater then
		string_spell_name = string_spell_name:gsub(', greater', '')
		string_spell_name = string_spell_name:gsub(', Greater', '')
	end
	if is_lesser then
		string_spell_name = string_spell_name:gsub(', lesser', '')
		string_spell_name = string_spell_name:gsub(', Lesser', '')
	end
	if is_communal then
		string_spell_name = string_spell_name:gsub(', communal', '')
		string_spell_name = string_spell_name:gsub(', Communal', '')
	end
	if is_mass then
		string_spell_name = string_spell_name:gsub(', mass', '')
		string_spell_name = string_spell_name:gsub(', Mass', '')
	end

	-- remove anything after open parentheses
	local number_name_end = string.find(string_spell_name, '%(')
	string_spell_name = string_spell_name:sub(1, number_name_end)

	-- remove certain sets of characters
	string_spell_name = string_spell_name:gsub('%u%u%u%u', '')
	string_spell_name = string_spell_name:gsub('%u%u%u', '')
	string_spell_name = string_spell_name:gsub('AP%d+', '')
	string_spell_name = string_spell_name:gsub('%u%u', '')
	string_spell_name = string_spell_name:gsub('.+:', '')
	string_spell_name = string_spell_name:gsub(',.+', '')
	string_spell_name = string_spell_name:gsub('%[%a%]', '')
	string_spell_name = string_spell_name:gsub('%A+', '')

	-- remove uppercase D or M at end of name
	number_name_end = string.find(string_spell_name, 'D', string.len(string_spell_name)) or string.find(string_spell_name, 'M', string.len(string_spell_name))
	if number_name_end then string_spell_name = string_spell_name:sub(1, number_name_end - 1) end

	-- convert to lower-case
	string_spell_name = string_spell_name:lower()

	-- append relevant tags to end of spell name
	if is_greater then
		string_spell_name = string_spell_name .. 'greater'
	end
	if is_lesser then
		string_spell_name = string_spell_name .. 'lesser'
	end
	if is_communal then
		string_spell_name = string_spell_name .. 'communal'
	end
	if is_mass then
		string_spell_name = string_spell_name .. 'mass'
	end

	return DB.findNode('spelldesc.' .. string_spell_name .. '@*') or DB.findNode('reference.spells.' .. string_spell_name .. '@*')
end

--- This function converts an existing string value into formattedtext and writes it to the description_full field on the spell sheet.
--	It checks for linked spells and appends them to the description.
--	It then looks for a better description in loaded spell modules.
local function upgradeSpellDescToFormattedText(nodeSpell)
	if not nodeSpell then
		return
	end

	local nodeDesc = nodeSpell.getChild('description')
	if nodeDesc then
		if not string.match(nodeDesc.getValue(), '<p>', 1) then
			local nodeReferenceSpell = getReferenceSpell(string.lower(DB.getValue(nodeSpell, 'name')))
			if nodeReferenceSpell then
				DB.copyNode(nodeReferenceSpell.getChild('description'), nodeSpell.createChild('description_full', 'formattedtext'))
			else
				local sValue = '<p>' .. nodeDesc.getValue() .. '</p>'
				sValue = sValue:gsub('\n\n', '</p><p>')
				sValue = sValue:gsub('\n', '</p><p>')
				sValue = sValue:gsub('\r\r', '</p><p>')
				sValue = sValue:gsub('\r', '</p><p>')
				
				local nodeLinkedSpells = nodeSpell.getChild('linkedspells')
				if nodeLinkedSpells then
					if nodeLinkedSpells.getChildCount() > 0 then
						sValue = sValue .. '<linklist>'
						for _,v in pairs(nodeLinkedSpells.getChildren()) do
							local sLinkName = DB.getValue(v, 'linkedname', '')
							local sLinkClass, sLinkRecord = DB.getValue(v, 'link', '', '')
							sValue = sValue .. '<link class=\'' .. sLinkClass .. '\' recordname=\'' .. sLinkRecord .. '\'>' .. sLinkName .. '</link>'
						end
						sValue = sValue .. '</linklist>'
					end
				end
				
				DB.setValue(nodeSpell, 'description_full', 'formattedtext', sValue)
			end
		end
	end
end

--- This function saves changes made to the formattedtext in the description_full field back to the string version in the descriptionon field of the spell sheet.
--	This is good protection in case the extension is removed in the future. With this in place, no custom notes/clarifications should be lost.
local function updateSpellDescString(nodeSpell)
	local nodeDesc = nodeSpell.getChild('description_full');
	if nodeDesc then
		local sDescType = nodeDesc.getType();
		if sDescType == 'formattedtext' then
			local sDesc = nodeDesc.getText();
			local sValue = nodeDesc.getValue();

			DB.setValue(nodeSpell, 'description', 'string', sDesc);
			
			local nodeLinkedSpells = nodeSpell.createChild('linkedspells');
			if nodeLinkedSpells then
				local nIndex = 1;
				local nLinkStartB, nLinkStartE, sClass, sRecord = string.find(sValue, '<link class=\'([^\']*)\' recordname=\'([^\']*)\'>', nIndex);
				while nLinkStartB and sClass and sRecord do
					local nLinkEndB, nLinkEndE = string.find(sValue, '</link>', nLinkStartE + 1);
					
					if nLinkEndB then
						local sText = string.sub(sValue, nLinkStartE + 1, nLinkEndB - 1);
						
						local nodeLink = nodeLinkedSpells.createChild();
						if nodeLink then
							DB.setValue(nodeLink, 'link', 'windowreference', sClass, sRecord);
							DB.setValue(nodeLink, 'linkedname', 'string', sText);
						end
						
						nIndex = nLinkEndE + 1;
						nLinkStartB, nLinkStartE, sClass, sRecord = string.find(sValue, '<link class=\'([^\']*)\' recordname=\'([^\']*)\'>', nIndex);
					else
						nLinkStartB = nil;
					end
				end
			end
		end
	end
end

function onValueChanged()
	updateSpellDescString(window.getDatabaseNode())
end

function onInit()
	local sDesc = window.description.getValue()
	local sDescFull = window.description_full.getValue()
	
	if sDesc ~= '' and (sDescFull == '' or sDescFull == '<p></p>' or sDescFull == '<p />') then
		upgradeSpellDescToFormattedText(getDatabaseNode().getParent())
	end
end