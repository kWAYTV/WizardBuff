local _, ns = ...

local GetSpellInfo = ns.Compat.GetSpellInfo

ns.SpellIDs = {
    FrostArmor      = { 168, 7300, 7301 },
    IceArmor        = { 7302, 7320, 10219, 10220 },
    MageArmor       = { 6117, 22782, 22783 },
    IceBarrier      = { 11426, 13031, 13032, 13033 },
    ManaShield      = { 1463, 8494, 8495, 10191, 10192, 10193 },
    ArcaneIntellect = { 1459, 1460, 1461, 10156, 10157, 27126 },
    ArcaneBrilliance = { 23028, 27127 },
}

ns.SpellNames = {
    FrostArmor      = GetSpellInfo(168),
    IceArmor        = GetSpellInfo(7302),
    MageArmor       = GetSpellInfo(6117),
    IceBarrier      = GetSpellInfo(11426),
    ManaShield      = GetSpellInfo(1463),
    ArcaneIntellect = GetSpellInfo(1459),
    ArcaneBrilliance = GetSpellInfo(23028),
}

ns.ArmorBuffNames = {
    GetSpellInfo(168),
    GetSpellInfo(7302),
    GetSpellInfo(6117),
}

ns.ReagentIDs = {
    ArcanePowder = 17020,
}

ns.SPELL_MIN_TARGET_LEVEL = {
    [1459]  = 1,   -- AI R1
    [1460]  = 14,  -- AI R2
    [1461]  = 28,  -- AI R3
    [10156] = 42,  -- AI R4
    [10157] = 56,  -- AI R5
    [27126] = 70,  -- AI R6 (TBC)
    [23028] = 56,  -- AB R1
    [27127] = 70,  -- AB R2 (TBC)
}
