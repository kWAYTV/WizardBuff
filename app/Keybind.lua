local _, ns = ...

-- "Buff next" key binding: armor if it's down, else the next Intellect.
-- An off-screen button the binding clicks.

local button

function ns.createKeybind()
    button = CreateFrame("Button", "WizardBuffBuffButton", UIParent, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp")
    button:SetAttribute("useOnKeyDown", false)
    button:SetAttribute("type1", "spell")
    button:SetSize(1, 1)
    button:SetPoint("TOPRIGHT", UIParent, "TOPLEFT", -50, 50)
end

-- Out of combat only.
function ns.bindKeybind()
    local cast = ns.intellect.cast
    local spell, unit = cast.spell, cast.unit
    if ns.armor.needed() then spell, unit = ns.armor.choice(), "player" end
    ns.grid.set(button, "spell1", spell)
    ns.grid.set(button, "unit1", unit or "player")
end
