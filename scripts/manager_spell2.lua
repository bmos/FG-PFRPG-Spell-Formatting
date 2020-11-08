-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- local convertSpellDescToString_old = nil
local addSpell_old = nil

-- Function Overrides
function onInit()
	-- convertSpellDescToString_old = SpellManager.convertSpellDescToString;
	-- SpellManager.convertSpellDescToString = convertSpellDescToString_new;
	addSpell_old = SpellManager.addSpell;
	SpellManager.addSpell = addSpell_new;
end

function onClose()
	-- SpellManager.convertSpellDescToString = convertSpellDescToString_old;
	SpellManager.addSpell = addSpell_old;
end

---	This function sets up spell descriptions for the new player copy of the spell.
--	It is implemented here so that it can write the fully-formatted text to description_full before it discards it in favor of the string version.
function convertSpellDescToString_new(nodeSpell)
	local nodeDesc = nodeSpell.getChild('description');
	if nodeDesc then
		DB.setValue(nodeSpell, 'description_full', 'formattedtext', nodeDesc.getValue());

		local sDescType = nodeDesc.getType();
		if sDescType == 'formattedtext' then
			local sDesc = nodeDesc.getText();
			local sValue = nodeDesc.getValue();

			nodeSpell.getChild('description').delete();
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
						nLinkStartB, nLinkStartE, sClass, sRecord = string.find(sValue, '<link class=\"([^\"]*)\' recordname=\"([^\"]*)\">', nIndex);
					else
						nLinkStartB = nil;
					end
				end
			end
		end
	end
end

---	This function copies the fully-formatted text into newly-created spells
function addSpell_new(nodeSource, nodeSpellClass, nLevel)
	-- Validate
	if not nodeSource or not nodeSpellClass or not nLevel then
		return nil;
	end
	
	-- Get the new spell entry
	local nodeNewSpell = addSpell_old(nodeSource, nodeSpellClass, nLevel)
	if not nodeNewSpell then
		return nil;
	end
	
	-- Copy the formatted spell details over
	DB.setValue(nodeNewSpell, 'description_full', 'formattedtext', DB.getValue(nodeSource, 'description', '<p></p>'));
	
	return nodeNewSpell;
end