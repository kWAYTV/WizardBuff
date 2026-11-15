local _, ns = ...

-- Three armors, one up at a time, 30 minutes each. Ranks lowest first.

local armor = {}
ns.armor = armor

armor.lines = {
    { ids = { 168, 7300, 7301 }, nameIDs = { 168 } },            -- Frost Armor
    { ids = { 7302, 7320, 10219, 10220 }, nameIDs = { 7302 } },  -- Ice Armor
    { ids = { 6117, 22782, 22783 }, nameIDs = { 6117 } },        -- Mage Armor
}

-- Tried in this order when you haven't used one yet.
armor.fallback = { 2, 1, 3 }

local NO_LEVELS = {}

function armor.rank(line)
    return ns.spellbook.best(armor.lines[line].ids, nil, NO_LEVELS)
end
