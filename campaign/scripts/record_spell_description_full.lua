--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
local function getReferenceSpell(string_spell_name)
	local tFormats = { ['Greater'] = false, ['Lesser'] = false, ['Communal'] = false, ['Mass'] = false }
	local tTrims = { ['Maximized'] = false, ['Heightened'] = false, ['Empowered'] = false, ['Quickened'] = false }

	-- remove tags from spell name
	for s, _ in pairs(tFormats) do
		if string_spell_name:gsub(', ' .. s, '') or string_spell_name:gsub(', ' .. s:lower(), '') then tTrims[s] = true end
	end
	for s, _ in pairs(tTrims) do
		if string_spell_name:gsub(', ' .. s, '') or string_spell_name:gsub(', ' .. s:lower(), '') then tTrims[s] = true end
	end

	-- remove certain sets of characters
	string_spell_name = string_spell_name:gsub('%u%u%u%u', '')
	string_spell_name = string_spell_name:gsub('%u%u%u', '')
	string_spell_name = string_spell_name:gsub('AP%d+', '')
	string_spell_name = string_spell_name:gsub('%u%u', '')
	string_spell_name = string_spell_name:gsub('.+:', '')
	string_spell_name = string_spell_name:gsub(',.+', '')
	string_spell_name = string_spell_name:gsub('%[.-%]', '')
	string_spell_name = string_spell_name:gsub('%(.-%)', '')
	string_spell_name = string_spell_name:gsub('%A+', '')

	-- remove uppercase D or M at end of name
	local number_name_end = string.find(string_spell_name, 'D', string.len(string_spell_name))
		or string.find(string_spell_name, 'M', string.len(string_spell_name))
	if number_name_end then string_spell_name = string_spell_name:sub(1, number_name_end - 1) end

	-- convert to lower-case
	string_spell_name = string_spell_name:lower()

	-- append relevant tags to end of spell name
	for s, v in pairs(tFormats) do
		if tTrims[v] then string_spell_name = string_spell_name .. ', ' .. s end
	end

	return DB.findNode('spelldesc.' .. string_spell_name .. '@*') or DB.findNode('reference.spells.' .. string_spell_name .. '@*')
end

--- This function converts an existing string value into formattedtext
--	Then it writes it to the description_full field on the spell sheet.
--	It checks for linked spells and appends them to the description.
--	It then looks for a better description in loaded spell modules.
local function upgradeSpellDescToFormattedText(nodeSpell)
	if not nodeSpell then return end

	local nodeDesc = DB.getChild(nodeSpell, 'description')
	if nodeDesc then
		if not string.match(DB.getValue(nodeDesc), '<p>', 1) then
			local nodeReferenceSpell = getReferenceSpell(string.lower(DB.getValue(nodeSpell, 'name')))
			if nodeReferenceSpell then
				local nodeReferenceDesc = DB.getChild(nodeReferenceSpell, 'description')
				DB.copyNode(nodeReferenceDesc, DB.createChild(nodeSpell, 'description_full', 'formattedtext'))
			else
				local sValue = '<p>' .. DB.getValue(nodeDesc) .. '</p>'
				sValue = sValue:gsub('\n\n', '</p><p>')
				sValue = sValue:gsub('\n', '</p><p>')
				sValue = sValue:gsub('\r\r', '</p><p>')
				sValue = sValue:gsub('\r', '</p><p>')

				local nodeLinkedSpells = DB.getChild(nodeSpell, 'linkedspells')
				if nodeLinkedSpells then
					if nodeLinkedSpells.getChildCount() > 0 then
						sValue = sValue .. '<linklist>'
						for _, v in ipairs(DB.getChildList(nodeLinkedSpells)) do
							local sLinkName = DB.getValue(v, 'linkedname', '')
							local sLinkClass, sLinkRecord = DB.getValue(v, 'link', '', '')
							sValue = (sValue .. "<link class='" .. sLinkClass .. "' recordname='" .. sLinkRecord .. "'>" .. sLinkName .. '</link>')
						end
						sValue = sValue .. '</linklist>'
					end
				end

				DB.setValue(nodeSpell, 'description_full', 'formattedtext', sValue)
			end
		end
	end
end

--- This function saves changes made to the formattedtext in the description_full field back to the basic string version.
--	This is good protection in case the extension is removed in the future. With this in place, no custom notes/clarifications should be lost.
local function updateSpellDescString(nodeSpell)
	local nodeDesc = DB.getChild(nodeSpell, 'description_full')
	if nodeDesc then
		local sDescType = DB.getType(nodeDesc)
		if sDescType == 'formattedtext' then
			local sDesc = DB.getText(nodeDesc)
			local sValue = DB.getValue(nodeDesc)

			DB.setValue(nodeSpell, 'description', 'string', sDesc)

			local nodeLinkedSpells = DB.createChild(nodeSpell, 'linkedspells')
			if nodeLinkedSpells then
				local nIndex = 1
				local nLinkStartB, nLinkStartE, sClass, sRecord = string.find(sValue, "<link class='([^']*)' recordname='([^']*)'>", nIndex)
				while nLinkStartB and sClass and sRecord do
					local nLinkEndB, nLinkEndE = string.find(sValue, '</link>', nLinkStartE + 1)

					if nLinkEndB then
						local sText = string.sub(sValue, nLinkStartE + 1, nLinkEndB - 1)

						local nodeLink = DB.createChild(nodeLinkedSpells)
						if nodeLink then
							DB.setValue(nodeLink, 'link', 'windowreference', sClass, sRecord)
							DB.setValue(nodeLink, 'linkedname', 'string', sText)
						end

						nIndex = nLinkEndE + 1
						nLinkStartB, nLinkStartE, sClass, sRecord = string.find(sValue, "<link class='([^']*)' recordname='([^']*)'>", nIndex)
					else
						nLinkStartB = nil
					end
				end
			end
		end
	end
end

-- luacheck: globals onValueChanged
function onValueChanged() updateSpellDescString(window.getDatabaseNode()) end

function onInit()
	local sDesc = window.description.getValue()
	local sDescFull = window.description_full.getValue()

	if sDesc ~= '' and (sDescFull == '' or sDescFull == '<p></p>' or sDescFull == '<p />') then
		upgradeSpellDescToFormattedText(DB.getParent(getDatabaseNode()))
	end
end
