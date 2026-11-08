local _, ns = ...

-- Mage buff spells, lowest rank first. Forever keeps vanilla-style ranks.
ns.SPELLS = {
    INTELLECT   = { 1459, 1460, 1461, 10156, 10157 },
    BRILLIANCE  = { 23028 },
    FROST_ARMOR = { 168, 7300, 7301 },
    ICE_ARMOR   = { 7302, 7320, 10219, 10220 },
    MAGE_ARMOR  = { 6117, 22782, 22783 },
    ICE_BARRIER = { 11426, 13031, 13032, 13033 },
    MANA_SHIELD = { 1463, 8494, 8495, 10191, 10192, 10193 },
    DAMPEN      = { 604, 8450, 8451, 10173, 10174 },
    AMPLIFY     = { 1008, 8455, 10169, 10170 },
}

-- Level each rank is learned. A rank can be cast on targets down to
-- ten levels below this.
ns.RANK_LEVEL = {
    [1459] = 1,  [1460] = 14, [1461] = 28, [10156] = 42, [10157] = 56,
    [23028] = 56,
    [604] = 12,  [8450] = 24, [8451] = 36, [10173] = 48, [10174] = 60,
    [1008] = 18, [8455] = 30, [10169] = 42, [10170] = 54,
}

ns.ARCANE_POWDER = 17020

ns.ICONS = {
    addon   = "Interface\\AddOns\\WizardBuff\\Media\\icon",
    unknown = "Interface\\Icons\\INV_Misc_QuestionMark",
}

local known = {}
local names = {}

function ns.RefreshKnownSpells()
    for key, ids in pairs(ns.SPELLS) do
        local list = {}
        for _, id in ipairs(ids) do
            if IsPlayerSpell(id) then list[#list + 1] = id end
        end
        -- Fallback in case Forever renumbered a spell: ask for it by name.
        if #list == 0 then
            local name = ns.SpellName(key)
            local info = name and C_Spell.GetSpellInfo(name)
            if info and info.spellID and IsPlayerSpell(info.spellID) then
                list[1] = info.spellID
            end
        end
        known[key] = list
    end
    if ns.ResetAuraMatchers then ns.ResetAuraMatchers() end
    ns.Fire("SPELLS_CHANGED")
end

function ns.SpellName(key)
    local name = names[key]
    if name then return name end
    local ids = ns.SPELLS[key]
    name = ids and C_Spell.GetSpellName(ids[1])
    if name then names[key] = name end
    return name
end

function ns.SpellIcon(id)
    return (id and C_Spell.GetSpellTexture(id)) or ns.ICONS.unknown
end

function ns.KnownIDs(key)
    return known[key] or {}
end

function ns.Knows(key)
    local list = known[key]
    return list ~= nil and #list > 0
end

function ns.Best(key)
    local list = known[key]
    return list and list[#list]
end

-- Highest known rank usable on a target of the given level.
function ns.BestForLevel(key, level)
    local list = known[key]
    if not list or #list == 0 then return nil end
    if not level or level <= 0 then return list[#list] end
    for i = #list, 1, -1 do
        local id = list[i]
        if level >= (ns.RANK_LEVEL[id] or 1) - 10 then return id end
    end
    return nil
end

function ns.PowderCount()
    return C_Item.GetItemCount(ns.ARCANE_POWDER) or 0
end

-- Armor to keep up, honoring the setting. "auto" picks Mage Armor in
-- instances and Ice Armor elsewhere, falling back to whatever is known.
function ns.ArmorKey()
    local choice = ns.db.armor
    if choice == "none" then return nil end
    if choice == "mage" then return ns.Knows("MAGE_ARMOR") and "MAGE_ARMOR" or nil end
    if choice == "ice" then return ns.Knows("ICE_ARMOR") and "ICE_ARMOR" or nil end
    if choice == "frost" then return ns.Knows("FROST_ARMOR") and "FROST_ARMOR" or nil end
    local inInstance = IsInInstance()
    local order = inInstance and { "MAGE_ARMOR", "ICE_ARMOR", "FROST_ARMOR" }
        or { "ICE_ARMOR", "MAGE_ARMOR", "FROST_ARMOR" }
    for _, key in ipairs(order) do
        if ns.Knows(key) then return key end
    end
end

function ns.ShieldKey()
    local choice = ns.db.shield
    if choice == "none" then return nil end
    if choice == "barrier" then return ns.Knows("ICE_BARRIER") and "ICE_BARRIER" or nil end
    if choice == "mana" then return ns.Knows("MANA_SHIELD") and "MANA_SHIELD" or nil end
    if ns.Knows("ICE_BARRIER") then return "ICE_BARRIER" end
    if ns.Knows("MANA_SHIELD") then return "MANA_SHIELD" end
end

-- Spell bound to a modifier click on a grid cell.
local CLICK_SPELLS = {
    dampen = "DAMPEN", amplify = "AMPLIFY",
    intellect = "INTELLECT", brilliance = "BRILLIANCE",
}

function ns.ClickSpellKey(choice)
    return CLICK_SPELLS[choice]
end
