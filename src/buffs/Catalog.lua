local _, ns = ...

-- Mage buffs this addon manages. Highest rank last.

ns.SpellIDs = {
    FrostArmor       = { 168, 7300, 7301 },
    IceArmor         = { 7302, 7320, 10219, 10220, 27124 },
    MageArmor        = { 6117, 22782, 22783, 27125 },
    IceBarrier       = { 11426, 13031, 13032, 13033, 27134, 33405 },
    ManaShield       = { 1463, 8494, 8495, 10191, 10192, 10193, 27131 },
    ArcaneIntellect  = { 1459, 1460, 1461, 10156, 10157, 27126 },
    ArcaneBrilliance = { 23028, 27127 },
}

ns.SPELL_MIN_TARGET_LEVEL = {
    [1459]  = 1,
    [1460]  = 14,
    [1461]  = 28,
    [10156] = 42,
    [10157] = 56,
    [27126] = 70,
    [23028] = 56,
    [27127] = 70,
}

ns.ReagentIDs = {
    ArcanePowder = 17020,
}

ns.ICON_PATHS = {
    addon      = "Interface\\AddOns\\WizardBuff\\Media\\icon",
    frostArmor = "Interface\\Icons\\Spell_Frost_FrostArmor02",
    iceArmor   = "Interface\\Icons\\Spell_Frost_FrostArmor02",
    mageArmor  = "Interface\\Icons\\Spell_MageArmor",
    int        = "Interface\\Icons\\Spell_Holy_ArcaneIntellect",
    brill      = "Interface\\Icons\\Spell_Holy_ArcaneIntellect",
    iceBarrier = "Interface\\Icons\\Spell_Ice_Lament",
    manaShield = "Interface\\Icons\\Spell_Shadow_DetectLesserInvisibility",
    notLearned = "Interface\\Icons\\INV_Misc_QuestionMark",
}

ns.SPELL_FALLBACK = {
    FrostArmor = ns.ICON_PATHS.frostArmor,
    IceArmor = ns.ICON_PATHS.iceArmor,
    MageArmor = ns.ICON_PATHS.mageArmor,
    ArcaneIntellect = ns.ICON_PATHS.int,
    ArcaneBrilliance = ns.ICON_PATHS.brill,
    IceBarrier = ns.ICON_PATHS.iceBarrier,
    ManaShield = ns.ICON_PATHS.manaShield,
}

local nameCache = {}

function ns.SpellName(key)
    local cached = nameCache[key]
    if cached then return cached end
    local ids = ns.SpellIDs[key]
    local name = ids and ns.GetSpellName(ids[1]) or nil
    if name then nameCache[key] = name end
    return name
end

function ns.SpellIcon(spellId, fallback)
    return (spellId and ns.GetSpellTexture(spellId)) or fallback
end

function ns.HasArcanePowder()
    return ns.GetItemCount(ns.ReagentIDs.ArcanePowder) > 0
end

function ns.GetArcanePowderCount()
    return ns.GetItemCount(ns.ReagentIDs.ArcanePowder)
end

function ns.PowderColorHex(n)
    if n > 5 then return "88aaff" end
    if n > 0 then return "ffcc44" end
    return "ff5555"
end
