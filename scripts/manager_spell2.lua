-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function upgradeSpellDescToFormattedText(nodeSpell)
	local nodeDesc = nodeSpell.getChild("description");
	if nodeDesc then
		local sDescType = nodeDesc.getType();
		if sDescType == "string" then
			local sValue = "<p>" .. nodeDesc.getValue() .. "</p>";
			sValue = sValue:gsub("\n\n", "</p><p>");
			sValue = sValue:gsub("\n", "</p><p>");

			local nodeLinkedSpells = nodeSpell.getChild("linkedspells");
			if nodeLinkedSpells then
				if nodeLinkedSpells.getChildCount() > 0 then
					sValue = sValue .. "<linklist>";
					for _,v in pairs(nodeLinkedSpells.getChildren()) do
						local sLinkName = DB.getValue(v, "linkedname", "");
						local sLinkClass, sLinkRecord = DB.getValue(v, "link", "", "");
						sValue = sValue .. "<link class=\"" .. sLinkClass .. "\" recordname=\"" .. sLinkRecord .. "\">" .. sLinkName .. "</link>";
					end
					sValue = sValue .. "</linklist>";
				end
			end

			DB.setValue(nodeSpell, "description_full", "formattedtext", sValue .. "<p><b>To improve this spell's formatting, delete and re-add it.</b></p>");
		end
	end
end

function convertSpellDescToString(nodeSpell)
	local nodeDesc = nodeSpell.getChild("description");
	if nodeDesc then
		DB.setValue(nodeSpell, "description_full", "formattedtext", nodeDesc.getValue());
		local sDescType = nodeDesc.getType();
		if sDescType == "formattedtext" then
			local sDesc = nodeDesc.getText();
			local sValue = nodeDesc.getValue();

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

function updateSpellDescString(nodeSpell)
	local nodeDesc = nodeSpell.getChild("description_full");
	if nodeDesc then
		local sDescType = nodeDesc.getType();
		if sDescType == "formattedtext" then
			local sDesc = nodeDesc.getText();
			local sValue = nodeDesc.getValue();

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
	if DB.getChildCount(nodeNewSpell, "actions") == 0 then
		SpellManager.parseSpell(nodeNewSpell);
	end
	
	return nodeNewSpell;
end