local addonName, ns = ...
ns.addonName = addonName

local GetAddOnMetadata = _G.C_AddOns and _G.C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata

local GetSpellInfo = _G.GetSpellInfo or function(spellID)
    local info = _G.C_Spell and _G.C_Spell.GetSpellInfo(spellID)
    if not info then return nil end
    return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
end

ns.Compat = {
    GetAddOnMetadata = GetAddOnMetadata,
    GetSpellInfo     = GetSpellInfo,
}

local rawVersion = GetAddOnMetadata(addonName, "Version")
if not rawVersion or rawVersion:find("@") then
    ns.VERSION = "dev"
else
    ns.VERSION = "v" .. rawVersion
end

function ns.Print(msg)
    print("|cff9ab8d4Wizard Buff|r: " .. tostring(msg))
end

function ns.PrintError(msg)
    print("|cffff6666Wizard Buff|r: " .. tostring(msg))
end

_G.WizardBuffAddon = ns
