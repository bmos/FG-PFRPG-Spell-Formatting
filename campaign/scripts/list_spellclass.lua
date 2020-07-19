-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local bInit = false;
function onInit()
	bInit = true;
end

function onListChanged()
	if not minisheet then
		update();
	end
end

function update()
	if minisheet then
		return;
	end
	
	if bInit then
		local bEditMode = window.getEditMode();
		for _,w in ipairs(getWindows()) do
			w.update(bEditMode);
		end
	end
end

function onFilter(w)
	return w.getFilter();
end

function onDrop(x, y, draginfo)
	if isReadOnly() then
		return false;
	end

	if draginfo.isType("spellmove") then
		local winClass = getWindowAt(x, y);
		if winClass then
			local nodeWin = winClass.getDatabaseNode();
			if nodeWin then
				local nodeSource = draginfo.getDatabaseNode();
				local nTargetLevel = draginfo.getNumberData();

				local nSourceLevel = nil;
				if nodeSource then
					nSourceLevel = nodeSource.getChild("...level");
				end

				if nSourceLevel and nSourceLevel ~= nTargetLevel then
					local nodeNew = SpellManager2.addSpell(nodeSource, nodeWin, nTargetLevel);
					if nodeNew then
						nodeSource.delete();
						winClass.showSpellsForLevel(nTargetLevel);
						DB.setValue(window.getDatabaseNode(), "spellmode", "string", "standard");
					end
				end
			end

			return true;
		end

	-- Spell link with level information (i.e. class spell list)
	elseif draginfo.isType("spelldescwithlevel") then
		local winClass = getWindowAt(x, y);
		if winClass then
			local nodeWin = winClass.getDatabaseNode();
			if nodeWin then
				local nodeSource = draginfo.getDatabaseNode();
				local nSourceLevel = draginfo.getNumberData();

				local nodeNew = SpellManager2.addSpell(nodeSource, nodeWin, nSourceLevel);
				if nodeNew then
					winClass.showSpellsForLevel(nSourceLevel);
					DB.setValue(window.getDatabaseNode(), "spellmode", "string", "standard");
				end
			end
			
			return true;
		end

	-- Spell link with no level information
	elseif draginfo.isType("shortcut") then
		local sDropClass, sSource = draginfo.getShortcutData();

		if sDropClass == "spelldesc" or sDropClass == "spelldesc2" then
			local winClass = getWindowAt(x, y);
			if winClass then
				local aSelections = {};
				for i = 0,9 do
					table.insert(aSelections, tostring(i));
				end
				local nodeSource = DB.findNode(sSource);
				
				local nSuggestedLevel = nil;
				local sSpellLevelField = DB.getValue(nodeSource, "level", "");
				if sSpellLevelField ~= "" then
					local sCurrentSpellClassLower = StringManager.trim(winClass.label.getValue()):lower();
					local aSpellClassChoices = StringManager.split(sSpellLevelField, ",");
					for _, sSpellClassChoice in ipairs(aSpellClassChoices) do
						local sComboClassName, sSpellClassLevel = sSpellClassChoice:match("(.*) (%d)");
						if sComboClassName then
							local aClassChoices = StringManager.split(sComboClassName, "/", true);
							for _,sClassChoice in ipairs(aClassChoices) do
								if sClassChoice:lower() == sCurrentSpellClassLower then
									nSuggestedLevel = tonumber(sSpellClassLevel);
									break;
								elseif #sClassChoice == 3 and DataCommon.class_stol[sClassChoice:lower()] == sCurrentSpellClassLower then
									nSuggestedLevel = tonumber(sSpellClassLevel);
									break;
								end
							end
						end
						if nSuggestedLevel then
							break;
						end
					end
				end
				if nSuggestedLevel and (nSuggestedLevel >= 0) and (nSuggestedLevel <= 9) then
					aSelections[nSuggestedLevel + 1] = { text = tostring(nSuggestedLevel), selected = "true" };
				end
				
				-- Display dialog to choose spell level
				local wSelect = Interface.openWindow("select_dialog", "");
				local sTitle = Interface.getString("char_spell_title_selectlevel");
				local sMessage = string.format(Interface.getString("char_spell_message_selectlevel"), DB.getValue(nodeSource, "name", ""), winClass.label.getValue());
				wSelect.requestSelection (sTitle, sMessage, aSelections, onSpellAddToLevel, { nodeSource = nodeSource, nodeClass = winClass.getDatabaseNode() } );
				
				return true;
			end
		end
	end
end

function onSpellAddToLevel(aSelection, vCustom)
	local nTargetLevel = tonumber(aSelection[1]) or nil;
	local nodeNew = SpellManager2.addSpell(vCustom.nodeSource, vCustom.nodeClass, nTargetLevel);
	if nodeNew then
		for _,winClass in ipairs(getWindows()) do
			if winClass.getDatabaseNode() == vCustom.nodeClass then
				winClass.showSpellsForLevel(nTargetLevel);
				break;
			end
		end
		DB.setValue(window.getDatabaseNode().getChild("..."), "spellmode", "string", "standard");
	end
end
