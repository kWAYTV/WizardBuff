local _, ns = ...

function ns.BuildShieldSpellList()
    return ns.BuildModeList({
        { key = "auto",       label = "Auto" },
        { key = "IceBarrier", label = ns.SpellName("IceBarrier"), spellKey = "IceBarrier" },
        { key = "ManaShield", label = ns.SpellName("ManaShield"), spellKey = "ManaShield" },
    })
end

function ns.GetShieldModeKey()
    return ns.GetModeKey("_shieldMode", ns.BuildShieldSpellList)
end

function ns.AnyShieldKnown()
    return #ns.BuildShieldSpellList() > 1
end
