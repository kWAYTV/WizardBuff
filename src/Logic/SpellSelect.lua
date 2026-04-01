local _, ns = ...

local GetSpellInfo       = ns.Compat.GetSpellInfo
local SpellIDs           = ns.SpellIDs
local SPELL_MIN_TARGET   = ns.SPELL_MIN_TARGET_LEVEL
local ReagentIDs         = ns.ReagentIDs

function ns.GetHighestRankSpell(spellList)
    if not spellList then return nil, nil end
    for i = #spellList, 1, -1 do
        local name = GetSpellInfo(spellList[i])
        if name and IsSpellKnown(spellList[i]) then
            return name, spellList[i]
        end
    end
    return nil, nil
end

local function getRankedSpellName(id, rankIndex)
    local name = GetSpellInfo(id)
    if not name then return nil end
    if GetSpellSubtext then
        local subtext = GetSpellSubtext(id)
        if subtext and subtext ~= "" then
            return name .. "(" .. subtext .. ")"
        end
    end
    if rankIndex then
        return name .. "(Rank " .. rankIndex .. ")"
    end
    return name
end

function ns.GetBestRankForUnit(unit, spellList)
    if not spellList then return nil, nil end
    local targetLevel
    if unit and UnitExists(unit) then
        targetLevel = UnitLevel(unit)
    end
    if not targetLevel or targetLevel < 1 then
        return ns.GetHighestRankSpell(spellList)
    end
    for i = #spellList, 1, -1 do
        local id = spellList[i]
        local name = GetSpellInfo(id)
        if name and IsSpellKnown(id) then
            local minLvl = SPELL_MIN_TARGET[id] or 1
            if targetLevel >= minLvl then
                return getRankedSpellName(id, i), id
            end
        end
    end
    return nil, nil
end

---------------------------------------------------------------------------
-- Reagent helpers
---------------------------------------------------------------------------
local function HasReagent(itemID)
    local count = GetItemCount(itemID)
    return count and count > 0
end

function ns.HasArcanePowder()
    return HasReagent(ReagentIDs.ArcanePowder)
end

function ns.GetArcanePowderCount()
    return GetItemCount(ReagentIDs.ArcanePowder) or 0
end

function ns.PowderColorHex(n)
    if n > 5  then return "88aaff" end
    if n > 0  then return "ffcc44" end
    return "ff5555"
end

---------------------------------------------------------------------------
-- Armor / bubble spell resolution (reads ns.db via SetLogicContext)
---------------------------------------------------------------------------
local db

function ns.SetLogicContext(dbTable)
    db = dbTable
end

function ns.GetArmorSpell()
    local armorType = db.armorType or "auto"
    if armorType == "frost" then
        return ns.GetHighestRankSpell(SpellIDs.FrostArmor)
    elseif armorType == "ice" then
        return ns.GetHighestRankSpell(SpellIDs.IceArmor)
    elseif armorType == "mage" then
        return ns.GetHighestRankSpell(SpellIDs.MageArmor)
    else
        local spell, id = ns.GetHighestRankSpell(SpellIDs.IceArmor)
        if spell then return spell, id end
        spell, id = ns.GetHighestRankSpell(SpellIDs.MageArmor)
        if spell then return spell, id end
        return ns.GetHighestRankSpell(SpellIDs.FrostArmor)
    end
end

function ns.GetArmorSpellKey()
    local armorType = db.armorType or "auto"
    if armorType == "frost" then return "FrostArmor"
    elseif armorType == "ice" then return "IceArmor"
    elseif armorType == "mage" then return "MageArmor"
    else
        if ns.GetHighestRankSpell(SpellIDs.IceArmor)  then return "IceArmor" end
        if ns.GetHighestRankSpell(SpellIDs.MageArmor)  then return "MageArmor" end
        if ns.GetHighestRankSpell(SpellIDs.FrostArmor) then return "FrostArmor" end
    end
    return nil
end

function ns.GetBubbleSpell()
    if not db.enableBubble then return nil, nil end
    local bubbleType = db.bubbleType or "auto"
    if bubbleType == "icebarrier" then
        return ns.GetHighestRankSpell(SpellIDs.IceBarrier)
    elseif bubbleType == "manashield" then
        return ns.GetHighestRankSpell(SpellIDs.ManaShield)
    elseif bubbleType == "none" then
        return nil, nil
    else
        local spell, id = ns.GetHighestRankSpell(SpellIDs.IceBarrier)
        if spell then return spell, id end
        return ns.GetHighestRankSpell(SpellIDs.ManaShield)
    end
end

function ns.NeedsBubble()
    if not db.enableBubble then return false end
    local max = UnitHealthMax("player")
    if not max or max <= 0 then return false end
    local healthPct = UnitHealth("player") / max * 100
    return healthPct < (db.bubbleThreshold or 50)
end
