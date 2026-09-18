local _, ns = ...

function ns.BuildSelfSpellList()
    return ns.BuildModeList({
        { key = "auto",       label = "Auto" },
        { key = "FrostArmor", label = ns.SpellName("FrostArmor"), spellKey = "FrostArmor" },
        { key = "IceArmor",   label = ns.SpellName("IceArmor"),   spellKey = "IceArmor" },
        { key = "MageArmor",  label = ns.SpellName("MageArmor"),  spellKey = "MageArmor" },
        { key = "SelfInt",    label = ns.SpellName("ArcaneIntellect") and ("Self " .. ns.SpellName("ArcaneIntellect")),
                              spellKey = "ArcaneIntellect" },
    })
end

function ns.GetSelfModeKey()
    return ns.GetModeKey("_selfMode", ns.BuildSelfSpellList)
end
