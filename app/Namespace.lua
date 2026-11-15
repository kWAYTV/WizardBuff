local name, ns = ...

ns.name = name

local _, class = UnitClass("player")
ns.isMage = class == "MAGE"

function ns.say(...)
    print("|cff69ccf0Wizard Buff|r:", ...)
end

BINDING_HEADER_WIZARDBUFF = "Wizard Buff"
_G["BINDING_NAME_CLICK WizardBuffBuffButton:LeftButton"] = "Buff next"
