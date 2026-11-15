local _, ns = ...

-- Arcane Intellect on Forever: lasts an hour, five ranks.
-- Arcane Brilliance (56) buffs the whole raid, not one party.

local intellect = {}
ns.intellect = intellect

intellect.ranks = { 1459, 1460, 1461, 10156, 10157 }
intellect.brilliance = 23028
intellect.learnedAt = { [1459] = 1, [1460] = 14, [1461] = 28, [10156] = 42, [10157] = 56 }
intellect.brillianceLevel = 46  -- lowest level Brilliance lands on

-- Any rank, Brilliance, or another caster's Intellect: they share two names.
intellect.family = {
    ids = { 1459, 1460, 1461, 10156, 10157, 23028 },
    nameIDs = { 1459, 23028 },
}

-- Classes with mana. The rest get nothing out of it.
intellect.wants = {
    DRUID = true, HUNTER = true, MAGE = true, PALADIN = true,
    PRIEST = true, SHAMAN = true, WARLOCK = true,
}

function intellect.rank(level)
    return ns.spellbook.best(intellect.ranks, level, intellect.learnedAt)
end
