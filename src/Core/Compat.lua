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
    local text = tostring(msg)
    print("|cff9ab8d4Wizard Buff|r: " .. text)
    if ns.ShowMessage then ns.ShowMessage(text) end
end

function ns.PrintError(msg)
    local text = tostring(msg)
    print("|cffff6666Wizard Buff|r: " .. text)
    if ns.ShowMessage then ns.ShowMessage(text, 1, 0.4, 0.4) end
end

_G.WizardBuffAddon = ns
