local name, ns = ...

ns.name = name

local _, class = UnitClass("player")
ns.isMage = class == "MAGE"

ns.version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(name, "Version") or "?"

function ns.say(...)
    print("|cff69ccf0Wizard Buff|r:", ...)
end

BINDING_HEADER_WIZARDBUFF = "Wizard Buff"
_G["BINDING_NAME_CLICK WizardBuffBuffButton:LeftButton"] = "Buff next"
