-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();
	if node then
		node.createChild("level0");
		node.createChild("level1");
		node.createChild("level2");
		node.createChild("level3");
		node.createChild("level4");
		node.createChild("level5");
		node.createChild("level6");
		node.createChild("level7");
		node.createChild("level8");
		node.createChild("level9");
	end
end

function onFilter(w)
	return w.getFilter();
end

function addEntry()
	return createWindow();
end

function onDrop(x, y, draginfo)
	if isReadOnly() then
		return false;
	end
	
	local winLevel = getWindowAt(x, y);
	if not winLevel then
		return false;
	end

	-- Draggable spell name to move spells
	if draginfo.isType("spellmove") then
		local node = winLevel.getDatabaseNode();
		if node then
			local nodeSource = draginfo.getDatabaseNode();
			local nodeNew = SpellManager2.addSpell(nodeSource, node.getChild("..."), DB.getValue(node, "level"));
			if nodeNew then
				nodeSource.delete();
				winLevel.spells.setVisible(true);
				DB.setValue(window.getDatabaseNode().getChild("..."), "spellmode", "string", "standard");
			end
		end
		
		return true;

	-- Spell link with level information (i.e. class spell list)
	elseif draginfo.isType("spelldescwithlevel") then
		local node = winLevel.getDatabaseNode();
		if node then
			local nodeSource = draginfo.getDatabaseNode();
			local nodeNew = SpellManager2.addSpell(nodeSource, node.getChild("..."), DB.getValue(node, "level"));
			if nodeNew then
				winLevel.spells.setVisible(true);
				DB.setValue(window.getDatabaseNode().getChild("..."), "spellmode", "string", "standard");
			end
		end
		
		return true;
	
	-- Spell link with no level information
	elseif draginfo.isType("shortcut") then
		local sDropClass, sSource = draginfo.getShortcutData();

		if sDropClass == "spelldesc" or sDropClass == "spelldesc2" then
			local node = winLevel.getDatabaseNode();
			if node then
				local nodeSource = DB.findNode(sSource);
				local nodeNew = SpellManager2.addSpell(nodeSource, node.getChild("..."), DB.getValue(node, "level"));
				if nodeNew then
					winLevel.spells.setVisible(true);
					DB.setValue(window.getDatabaseNode().getChild("..."), "spellmode", "string", "standard");
				end
				
				return true;
			end
		end
	end
end
