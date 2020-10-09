-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

---	This function sets up spell descriptions for the new player copy of the spell.
--	It is implemented here so that it can write the fully-formatted text to description_full before it discards it in favor of the string version.
function convertSpellDescToString(nodeSpell)
	local nodeDesc = nodeSpell.getChild("description");
	if nodeDesc then
		DB.setValue(nodeSpell, "description_full", "formattedtext", nodeDesc.getValue());

		local sDescType = nodeDesc.getType();
		if sDescType == "formattedtext" then
			local sDesc = nodeDesc.getText();
			local sValue = nodeDesc.getValue();

			nodeSpell.getChild("description").delete();
			DB.setValue(nodeSpell, "description", "string", sDesc);
			
			local nodeLinkedSpells = nodeSpell.createChild("linkedspells");
			if nodeLinkedSpells then
				local nIndex = 1;
				local nLinkStartB, nLinkStartE, sClass, sRecord = string.find(sValue, "<link class=\"([^\"]*)\" recordname=\"([^\"]*)\">", nIndex);
				while nLinkStartB and sClass and sRecord do
					local nLinkEndB, nLinkEndE = string.find(sValue, "</link>", nLinkStartE + 1);
					
					if nLinkEndB then
						local sText = string.sub(sValue, nLinkStartE + 1, nLinkEndB - 1);
						
						local nodeLink = nodeLinkedSpells.createChild();
						if nodeLink then
							DB.setValue(nodeLink, "link", "windowreference", sClass, sRecord);
							DB.setValue(nodeLink, "linkedname", "string", sText);
						end
						
						nIndex = nLinkEndE + 1;
						nLinkStartB, nLinkStartE, sClass, sRecord = string.find(sValue, "<link class=\"([^\"]*)\" recordname=\"([^\"]*)\">", nIndex);
					else
						nLinkStartB = nil;
					end
				end
			end
		end
	end
end

---	This function sets up spells in the spellset+level that they are dragged to.
function addSpell(nodeSource, nodeSpellClass, nLevel)
	-- Validate
	if not nodeSource or not nodeSpellClass or not nLevel then
		return nil;
	end
	
	-- Create the new spell entry
	local nodeTargetLevelSpells = nodeSpellClass.getChild("levels.level" .. nLevel .. ".spells");
	if not nodeTargetLevelSpells then
		return nil;
	end
	local nodeNewSpell = nodeTargetLevelSpells.createChild();
	if not nodeNewSpell then
		return nil;
	end
	
	-- Copy the spell details over
	DB.copyNode(nodeSource, nodeNewSpell);
	
	-- Convert the description field from module data
	convertSpellDescToString(nodeNewSpell);

	local nodeParent = nodeTargetLevelSpells.getParent();
	if nodeParent then
		-- Set the default cost for points casters
		local nCost = tonumber(string.sub(nodeParent.getName(), -1)) or 0;
		if nCost > 0 then
			nCost = ((nCost - 1) * 2) + 1;
		end
		DB.setValue(nodeNewSpell, "cost", "number", nCost);

		-- If spell level not visible, then make it so.
		local sAvailablePath = "....available" .. nodeParent.getName();
		local nAvailable = DB.getValue(nodeTargetLevelSpells, sAvailablePath, 1);
		if nAvailable <= 0 then
			DB.setValue(nodeTargetLevelSpells, sAvailablePath, "number", 1);
		end
	end
	
	-- Parse spell details to create actions
	-- KEL Here tag parsing separate such that it is always parsed? Ursprüngliche tags mitnehmen? Mit Option?
	if DB.getChildCount(nodeNewSpell, "actions") == 0 then
		SpellManager.parseSpell(nodeNewSpell);
	elseif StringManager.contains(Extension.getExtensions(), 'Full OverlayPackage with alternative icons')
		or StringManager.contains(Extension.getExtensions(), 'Save versus tags')
		or StringManager.contains(Extension.getExtensions(), 'Full OverlayPackage') then
		local nodeActions = nodeNewSpell.createChild("actions");
		if nodeActions then
			local nodeAction = nodeActions.getChildren();
			if nodeAction then
				for k, v in pairs(nodeAction) do
					if DB.getValue(v, "type") == "cast" then
						SpellManager.addTags(nodeNewSpell, v);
					end
				end
			end
		end
	end
	
	return nodeNewSpell;
end