--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
local addSpell_old

---	This function copies the fully-formatted text into newly-created spells
local function addSpell_new(nodeSource, nodeSpellClass, nLevel, ...)
	-- Validate
	if not nodeSource or not nodeSpellClass or not nLevel then return end

	-- Get the new spell entry
	local nodeNewSpell = addSpell_old(nodeSource, nodeSpellClass, nLevel, ...)
	if not nodeNewSpell then return end

	-- Copy the formatted spell details over
	DB.setValue(nodeNewSpell, 'description_full', 'formattedtext', DB.getValue(nodeSource, 'description', '<p></p>'));

	return nodeNewSpell;
end

-- Function Overrides
function onInit()
	addSpell_old = SpellManager.addSpell;
	SpellManager.addSpell = addSpell_new;
end

function onClose() SpellManager.addSpell = addSpell_old; end
