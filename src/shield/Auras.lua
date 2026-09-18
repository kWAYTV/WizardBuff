local _, ns = ...

function ns.PlayerHasShieldBuff()
    local ib = ns.SpellName("IceBarrier")
    local ms = ns.SpellName("ManaShield")
    return (ib and ns.HasAura("player", ib)) or (ms and ns.HasAura("player", ms)) or false
end

function ns.GetShieldRemaining()
    local ib = ns.SpellName("IceBarrier")
    local ms = ns.SpellName("ManaShield")
    local a = ib and ns.GetBuffTimeRemaining("player", ib)
    local b = ms and ns.GetBuffTimeRemaining("player", ms)
    if a and b then return math.min(a, b) end
    return a or b
end
