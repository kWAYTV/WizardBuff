local _, ns = ...

function ns.GetBubbleSpell()
    if not ns.db or not ns.db.enableBubble then return nil, nil end
    local bubbleType = ns.db.bubbleType or "auto"
    if bubbleType == "icebarrier" then return ns.GetHighestRankSpell(ns.SpellIDs.IceBarrier) end
    if bubbleType == "manashield" then return ns.GetHighestRankSpell(ns.SpellIDs.ManaShield) end
    if bubbleType == "none" then return nil, nil end
    local spell, id = ns.GetHighestRankSpell(ns.SpellIDs.IceBarrier)
    if spell then return spell, id end
    return ns.GetHighestRankSpell(ns.SpellIDs.ManaShield)
end

function ns.NeedsBubble()
    if not ns.db or not ns.db.enableBubble then return false end
    local max = UnitHealthMax("player")
    if not max or max <= 0 then return false end
    return (UnitHealth("player") / max * 100) < (ns.db.bubbleThreshold or 50)
end
