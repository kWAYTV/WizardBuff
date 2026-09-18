local addonName, ns = ...
ns.addonName = addonName

-- TBC Anniversary (20506) uses a modern client. Prefer C_* when present.

local C_Spell     = _G.C_Spell
local C_SpellBook = _G.C_SpellBook
local C_UnitAuras = _G.C_UnitAuras
local C_Item      = _G.C_Item
local C_AddOns    = _G.C_AddOns

local function addonMetadata(name, key)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(name, key)
    end
    return _G.GetAddOnMetadata and _G.GetAddOnMetadata(name, key)
end

function ns.GetSpellInfo(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if type(info) == "table" then
            return info.name, info.rank, info.iconID or info.icon, info.castTime,
                info.minRange, info.maxRange, info.spellID
        end
    end
    if _G.GetSpellInfo then
        return _G.GetSpellInfo(spellID)
    end
end

function ns.GetSpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then
        local name = C_Spell.GetSpellName(spellID)
        if name then return name end
    end
    return ns.GetSpellInfo(spellID)
end

function ns.GetSpellTexture(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        local tex = C_Spell.GetSpellTexture(spellID)
        if tex then return tex end
    end
    if _G.GetSpellTexture then
        local tex = _G.GetSpellTexture(spellID)
        if tex then return tex end
    end
    local _, _, icon = ns.GetSpellInfo(spellID)
    return icon
end

function ns.GetSpellSubtext(spellID)
    if C_Spell and C_Spell.GetSpellSubtext then
        local sub = C_Spell.GetSpellSubtext(spellID)
        if sub and sub ~= "" then return sub end
    end
    if _G.GetSpellSubtext then
        local sub = _G.GetSpellSubtext(spellID)
        if sub and sub ~= "" then return sub end
    end
    local _, rank = ns.GetSpellInfo(spellID)
    if rank and rank ~= "" then return rank end
end

function ns.IsSpellKnown(spellID)
    if not spellID then return false end
    if _G.IsPlayerSpell and _G.IsPlayerSpell(spellID) then return true end
    if _G.IsSpellKnown and _G.IsSpellKnown(spellID) then return true end
    if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellID) then
        return true
    end
    return false
end

function ns.IsSpellInRange(spell, unit)
    if not spell or not unit then return nil end
    if C_Spell and C_Spell.IsSpellInRange then
        local r = C_Spell.IsSpellInRange(spell, unit)
        if r == true then return 1 end
        if r == false then return 0 end
        return nil
    end
    if _G.IsSpellInRange then
        return _G.IsSpellInRange(spell, unit)
    end
end

function ns.GetItemCount(itemID)
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemID) or 0
    end
    if _G.GetItemCount then
        return _G.GetItemCount(itemID) or 0
    end
    return 0
end

function ns.GetBuffAt(unit, index)
    if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
        local a = C_UnitAuras.GetBuffDataByIndex(unit, index)
        if not a then return nil end
        return a.name, a.duration, a.expirationTime, a.sourceUnit
    end
    if not _G.UnitBuff then return nil end
    local name, a, b, c, d, e, f, g = _G.UnitBuff(unit, index)
    if not name then return nil end
    if type(f) == "number" and f > 10000 then
        return name, e, f, g
    end
    return name, d, e, f
end

function ns.Trim(s)
    if not s then return "" end
    return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

function ns.LoadLua(str)
    local loader = _G.loadstring or _G.load
    if not loader then return nil, "loadstring missing" end
    return loader(str)
end

local rawVersion = addonMetadata(addonName, "Version")
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
