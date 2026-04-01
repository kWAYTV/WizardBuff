local _, ns = ...
ns = ns or _G.WizardBuffAddon
assert(ns, "WizardBuff: load WizardBuff.lua before Logic.lua")

local GetSpellInfo = ns.Compat and ns.Compat.GetSpellInfo or _G.GetSpellInfo

local SpellIDs = ns.SpellIDs
local SpellNames = ns.SpellNames
local ArmorBuffNames = ns.ArmorBuffNames
local ReagentIDs = ns.ReagentIDs
local CLASS_ORDER = ns.CLASS_ORDER
local REFRESH_THRESHOLD = ns.REFRESH_THRESHOLD

local db, roster

function ns.SetLogicContext(dbTable, rosterTable)
    db = dbTable
    roster = rosterTable
end

function ns.GetHighestRankSpell(spellList)
    if not spellList then
        return nil, nil
    end
    for i = #spellList, 1, -1 do
        local name = GetSpellInfo(spellList[i])
        if name and IsSpellKnown(spellList[i]) then
            return name, spellList[i]
        end
    end
    return nil, nil
end

local SPELL_MIN_TARGET_LEVEL = {
    [1459]  = 1,   -- AI R1
    [1460]  = 14,  -- AI R2
    [1461]  = 28,  -- AI R3
    [10156] = 42,  -- AI R4
    [10157] = 56,  -- AI R5
    [27126] = 70,  -- AI R6 (TBC)
    [23028] = 56,  -- AB R1
    [27127] = 70,  -- AB R2 (TBC)
}

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
            local minLvl = SPELL_MIN_TARGET_LEVEL[id] or 1
            if targetLevel >= minLvl then
                return getRankedSpellName(id, i), id
            end
        end
    end
    return nil, nil
end

local function HasReagent(itemID)
    local count = GetItemCount(itemID)
    return count and count > 0
end

function ns.HasArcanePowder()
    return HasReagent(ReagentIDs.ArcanePowder)
end

--- Remaining seconds on a named buff, or nil if missing / indefinite.
function ns.GetBuffTimeRemaining(unit, buffName)
    if not unit or not buffName or not UnitExists(unit) then
        return nil
    end
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime = UnitBuff(unit, i)
        if not name then
            break
        end
        if name == buffName then
            if not duration or duration == 0 then
                return nil
            end
            return math.max(0, expirationTime - GetTime())
        end
    end
    return nil
end

function ns.UnitHasBuff(unit, buffName)
    if not unit or not UnitExists(unit) then
        return false, nil
    end
    if not buffName then
        return false, nil
    end
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime, caster = UnitBuff(unit, i)
        if not name then
            break
        end
        if name == buffName then
            if not duration or duration == 0 then
                return true, caster
            end
            local remaining = expirationTime - GetTime()
            local floor = ns.db and ns.db.refreshFloorSec or 120
            if remaining > floor then
                return true, caster
            end
            if remaining > duration * REFRESH_THRESHOLD then
                return true, caster
            else
                return false, nil
            end
        end
    end
    return false, nil
end

function ns.HasAnyArmorBuff()
    for _, buffName in ipairs(ArmorBuffNames) do
        if buffName and ns.UnitHasBuff("player", buffName) then
            return true
        end
    end
    return false
end

function ns.GetSelfArmorRemaining()
    local best
    for _, buffName in ipairs(ArmorBuffNames) do
        if buffName then
            local rem = ns.GetBuffTimeRemaining("player", buffName)
            if rem then
                if not best or rem < best then best = rem end
            end
        end
    end
    return best
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
        if spell then
            return spell, id
        end
        spell, id = ns.GetHighestRankSpell(SpellIDs.MageArmor)
        if spell then
            return spell, id
        end
        return ns.GetHighestRankSpell(SpellIDs.FrostArmor)
    end
end

function ns.GetBubbleSpell()
    if not db.enableBubble then
        return nil, nil
    end
    local bubbleType = db.bubbleType or "auto"
    if bubbleType == "icebarrier" then
        return ns.GetHighestRankSpell(SpellIDs.IceBarrier)
    elseif bubbleType == "manashield" then
        return ns.GetHighestRankSpell(SpellIDs.ManaShield)
    elseif bubbleType == "none" then
        return nil, nil
    else
        local spell, id = ns.GetHighestRankSpell(SpellIDs.IceBarrier)
        if spell then
            return spell, id
        end
        return ns.GetHighestRankSpell(SpellIDs.ManaShield)
    end
end

function ns.NeedsBubble()
    if not db.enableBubble then
        return false
    end
    local max = UnitHealthMax("player")
    if not max or max <= 0 then
        return false
    end
    local healthPct = UnitHealth("player") / max * 100
    return healthPct < (db.bubbleThreshold or 50)
end

function ns.PlayerHasShieldBuff()
    for _, id in ipairs(SpellIDs.IceBarrier) do
        if IsSpellKnown(id) then
            local name = GetSpellInfo(id)
            if name and ns.UnitHasBuff("player", name) then
                return true
            end
        end
    end
    for _, id in ipairs(SpellIDs.ManaShield) do
        if IsSpellKnown(id) then
            local name = GetSpellInfo(id)
            if name and ns.UnitHasBuff("player", name) then
                return true
            end
        end
    end
    return false
end

function ns.HasStrongerBrilliance(unit)
    if not unit or not UnitExists(unit) then
        return false
    end
    local brillName = SpellNames.ArcaneBrilliance
    if not brillName then
        return false
    end
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime, caster = UnitBuff(unit, i)
        if not name then
            break
        end
        if name == brillName then
            if caster and not UnitIsUnit(caster, "player") then
                if not duration or duration == 0 then
                    return true
                end
                local remaining = expirationTime - GetTime()
                if remaining > duration * REFRESH_THRESHOLD then
                    return true
                end
            end
        end
    end
    return false
end

local function GetUnitClass(unit)
    if not unit or not UnitExists(unit) then
        return nil
    end
    local _, class = UnitClass(unit)
    return class
end

function ns.MakeBuffMacro(unit, spell)
    if unit == "player" or UnitIsUnit(unit, "player") then
        return "/cast [nocombat,@player] " .. spell
    else
        return "/cast [nocombat,@" .. unit .. "] " .. spell
    end
end

function ns.MakeSelfCastMacro(spell)
    return "/cast [@player] " .. spell
end

function ns.ScanRoster()
    wipe(roster)
    local intName = SpellNames.ArcaneIntellect
    local brillName = SpellNames.ArcaneBrilliance

    local function AddUnit(unit)
        if not UnitExists(unit) then
            return
        end
        if UnitIsDeadOrGhost(unit) then
            return
        end
        if not UnitIsConnected(unit) then
            return
        end
        local name = GetUnitName(unit, true)
        local class = GetUnitClass(unit)
        if not class or not name then
            return
        end
        local hasStrongerBrill = ns.HasStrongerBrilliance(unit)
        local hasInt = ns.UnitHasBuff(unit, intName)
        local hasBrill = ns.UnitHasBuff(unit, brillName)
        local needsInt = db.buffIntellect and not hasStrongerBrill and not hasInt and not hasBrill
        if not roster[class] then
            roster[class] = {}
        end
        table.insert(roster[class], {
            unit = unit,
            name = name,
            class = class,
            needsInt = needsInt,
            level = UnitLevel(unit),
            hasStrongerBrill = hasStrongerBrill,
        })
    end

    local function AddPet(petUnit, ownerName)
        if not db.buffPets then
            return
        end
        if not UnitExists(petUnit) then
            return
        end
        if UnitIsDeadOrGhost(petUnit) then
            return
        end
        local petName = GetUnitName(petUnit, false)
        if not petName then
            return
        end
        local hasStrongerBrill = ns.HasStrongerBrilliance(petUnit)
        local hasInt = ns.UnitHasBuff(petUnit, intName)
        local hasBrill = ns.UnitHasBuff(petUnit, brillName)
        local needsInt = db.buffIntellect and not hasStrongerBrill and not hasInt and not hasBrill
        if not roster["PET"] then
            roster["PET"] = {}
        end
        table.insert(roster["PET"], {
            unit = petUnit,
            name = petName,
            class = "PET",
            needsInt = needsInt,
            level = UnitLevel(petUnit),
            ownerName = ownerName,
            hasStrongerBrill = hasStrongerBrill,
        })
    end

    if IsInRaid() then
        for i = 1, 40 do
            AddUnit("raid" .. i)
            local ownerName = GetUnitName("raid" .. i, false)
            AddPet("raidpet" .. i, ownerName)
        end
    elseif IsInGroup() then
        AddUnit("player")
        AddPet("pet", UnitName("player"))
        for i = 1, 4 do
            AddUnit("party" .. i)
            local ownerName = GetUnitName("party" .. i, false)
            AddPet("partypet" .. i, ownerName)
        end
    elseif db.showWhenSolo then
        AddUnit("player")
        AddPet("pet", UnitName("player"))
    end
    return roster
end

function ns.SelfNeedsArmor()
    return db.buffArmor and not ns.HasAnyArmorBuff()
end

function ns.IsUnitInBuffRange(unit)
    if not unit or not UnitExists(unit) then
        return false
    end
    if UnitIsUnit(unit, "player") then
        return true
    end
    if not UnitIsConnected(unit) then
        return false
    end
    if not UnitIsVisible(unit) then
        return false
    end
    local intName = SpellNames.ArcaneIntellect
    if intName then
        local inRange = IsSpellInRange(intName, unit)
        if inRange == 1 then
            return true
        end
        if inRange == 0 then
            return false
        end
    end
    return CheckInteractDistance(unit, 2)
end

function ns.GetNextIntTarget(petsOnly)
    if not petsOnly then
        for _, class in ipairs(CLASS_ORDER) do
            if class ~= "PET" and roster[class] then
                for _, p in ipairs(roster[class]) do
                    if p.needsInt and UnitIsUnit(p.unit, "player") then
                        return p.unit, p.name
                    end
                end
            end
        end
    end
    for _, class in ipairs(CLASS_ORDER) do
        local isPet = (class == "PET")
        if (petsOnly and isPet) or (not petsOnly and not isPet) then
            if roster[class] then
                for _, p in ipairs(roster[class]) do
                    if p.needsInt and ns.IsUnitInBuffRange(p.unit) then
                        return p.unit, p.name
                    end
                end
            end
        end
    end
    return nil, nil
end

function ns.GetBuffReport()
    ns.ScanRoster()
    local total, buffed = 0, 0
    local needByClass = {}
    for _, class in ipairs(CLASS_ORDER) do
        if roster[class] then
            for _, p in ipairs(roster[class]) do
                total = total + 1
                if not p.needsInt then
                    buffed = buffed + 1
                else
                    if not needByClass[class] then needByClass[class] = {} end
                    table.insert(needByClass[class], p.name)
                end
            end
        end
    end
    if total == 0 then
        return "WizardBuff: No group members found"
    end
    if buffed == total then
        return "WizardBuff: " .. total .. "/" .. total .. " buffed -- all good!"
    end
    local parts = {}
    for _, class in ipairs(CLASS_ORDER) do
        if needByClass[class] then
            table.insert(parts, class .. "(" .. table.concat(needByClass[class], ", ") .. ")")
        end
    end
    return "WizardBuff: " .. buffed .. "/" .. total .. " buffed. Need: " .. table.concat(parts, ", ")
end