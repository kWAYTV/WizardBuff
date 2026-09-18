local _, ns = ...

function ns.BuildGridPlayers()
    local out = {}
    for _, class in ipairs(ns.CLASS_ORDER) do
        local players = ns.roster[class]
        if players then
            for _, p in ipairs(players) do
                local rem
                if not p.needsInt then
                    rem = ns.GetBuffTimeRemaining(p.unit, ns.SpellName("ArcaneBrilliance"))
                       or ns.GetBuffTimeRemaining(p.unit, ns.SpellName("ArcaneIntellect"))
                end
                out[#out + 1] = {
                    name = p.name, unit = p.unit, class = class, needsInt = p.needsInt,
                    ownerName = p.ownerName, isDead = p.isDead, isOffline = p.isOffline,
                    hasStrongerBrill = p.hasStrongerBrill, buffRemaining = rem,
                }
            end
        end
    end
    return out
end
