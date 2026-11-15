local _, ns = ...

-- "Buff next" key binding: armor if it's down, else the next Intellect.
-- An off-screen button the binding clicks.

local button

function ns.createKeybind()
    button = CreateFrame("Button", "WizardBuffBuffButton", UIParent, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetSize(1, 1)
    button:SetPoint("TOPRIGHT", UIParent, "TOPLEFT", -50, 50)
end

-- Out of combat only.
function ns.bindKeybind()
    local cast = ns.intellect.cast
    local spell, unit
    if ns.armor.needed() then
        spell, unit = ns.armor.choice(), "player"
    elseif not cast.topUp then
        spell, unit = cast.spell, cast.unit
    end
    ns.icons.set(button, "type", "spell")
    ns.icons.set(button, "spell", spell)
    ns.icons.set(button, "unit", unit or "player")
end
