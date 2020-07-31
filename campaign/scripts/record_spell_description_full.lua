-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
	if window.description.getValue() ~= '' then
		if window.description_full.getValue() == "<p><b>To improve this spell's formatting, delete and re-add it.</b></p" or
			window.description_full.getValue() == '<p></p>' or
			window.description_full.getValue() == '\r<p></p>' or
			window.description_full.getValue() == '\n<p></p>' or
			window.description_full.getValue() == '\r\n<p></p>' then
			
			upgradeSpellDescToFormattedText(getDatabaseNode().getParent())
		end
	end
end

--- This function converts an existing string value into formattedtext and writes it to the description_full field on the spell sheet.
--	It also includes an informational message explaining that removing and re-adding the converted spell would be beneficial to its formatting.
function upgradeSpellDescToFormattedText(nodeSpell)
	local nodeDesc = nodeSpell.getChild('description')
	if nodeDesc then
		local sDescType = nodeDesc.getType()
		if sDescType == 'string' then
			local sValue = '<p>' .. nodeDesc.getValue() .. '</p>'
			sValue = sValue:gsub('\n\n', '</p><p>')
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

			window.description_full.setValue(sValue .. "<p><b>To improve this spell's formatting, delete and re-add it.</b></p>")
		end
	end
end

function onValueChanged()
	updateSpellDescString(getDatabaseNode().getParent())
end

--- This function saves changes made to the formattedtext in the description_full field back to the string version in the descriptionon field of the spell sheet.
--	This is good protection in case the extension is removed in the future. With this in place, no custom notes/clarifications should be lost.
function updateSpellDescString(nodeSpell)
	local nodeDesc = nodeSpell.getChild('description_full');
	if nodeDesc then
		local sDescType = nodeDesc.getType();
		if sDescType == 'formattedtext' then
			local sDesc = nodeDesc.getText();
			local sValue = nodeDesc.getValue();

			window.description.setValue(sDesc);
			
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