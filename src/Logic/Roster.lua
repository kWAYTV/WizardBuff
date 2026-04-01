local _, ns = ...

local SpellNames  = ns.SpellNames
local CLASS_ORDER = ns.CLASS_ORDER

local RECENTLY_BUFFED_SEC = 4

---------------------------------------------------------------------------
-- Recently-buffed tracking (single owner)
---------------------------------------------------------------------------
ns._recentlyBuffed = {}

function ns.MarkRecentlyBuffed(unit)
    ns._recentlyBuffed[unit] = GetTime()
end

function ns.IsRecentlyBuffed(unit)
    local t = ns._recentlyBuffed[unit]
    return t and (GetTime() - t) < RECENTLY_BUFFED_SEC
end

---------------------------------------------------------------------------
-- Roster scanning
---------------------------------------------------------------------------
local function GetUnitClass(unit)
    if not unit or not UnitExists(unit) then return nil end
    local _, class = UnitClass(unit)
    return class
end

function ns.ScanRoster()
    local roster = ns.roster
    local db     = ns.db
    wipe(roster)

    local intName   = SpellNames.ArcaneIntellect
    local brillName = SpellNames.ArcaneBrilliance

    local function AddUnit(unit)
        if not UnitExists(unit) then return end
        if UnitIsDeadOrGhost(unit) then return end
        if not UnitIsConnected(unit) then return end
        local name  = GetUnitName(unit, true)
        local class = GetUnitClass(unit)
        if not class or not name then return end
        local hasStrongerBrill = ns.HasStrongerBrilliance(unit)
        local hasInt  = ns.UnitHasBuff(unit, intName)
        local hasBrill = ns.UnitHasBuff(unit, brillName)
        local needsInt = db.buffIntellect
            and not hasStrongerBrill and not hasInt and not hasBrill
            and not ns.IsRecentlyBuffed(unit)
        if not roster[class] then roster[class] = {} end
        table.insert(roster[class], {
            unit   = unit,
            name   = name,
            class  = class,
            needsInt = needsInt,
            level  = UnitLevel(unit),
            hasStrongerBrill = hasStrongerBrill,
        })
    end

    local function AddPet(petUnit, ownerName)
        if not db.buffPets then return end
        if not UnitExists(petUnit) then return end
        if UnitIsDeadOrGhost(petUnit) then return end
        local petName = GetUnitName(petUnit, false)
        if not petName then return end
        local hasStrongerBrill = ns.HasStrongerBrilliance(petUnit)
        local hasInt  = ns.UnitHasBuff(petUnit, intName)
        local hasBrill = ns.UnitHasBuff(petUnit, brillName)
        local needsInt = db.buffIntellect
            and not hasStrongerBrill and not hasInt and not hasBrill
            and not ns.IsRecentlyBuffed(petUnit)
        if not roster["PET"] then roster["PET"] = {} end
        table.insert(roster["PET"], {
            unit   = petUnit,
            name   = petName,
            class  = "PET",
            needsInt = needsInt,
            level  = UnitLevel(petUnit),
            ownerName = ownerName,
            hasStrongerBrill = hasStrongerBrill,
        })
    end

    if IsInRaid() then
        for i = 1, 40 do
            AddUnit("raid" .. i)
            AddPet("raidpet" .. i, GetUnitName("raid" .. i, false))
        end
    elseif IsInGroup() then
        AddUnit("player")
        AddPet("pet", UnitName("player"))
        for i = 1, 4 do
            AddUnit("party" .. i)
            AddPet("partypet" .. i, GetUnitName("party" .. i, false))
        end
    elseif db.showWhenSolo then
        AddUnit("player")
        AddPet("pet", UnitName("player"))
    end
    return roster
end

---------------------------------------------------------------------------
-- Target selection
---------------------------------------------------------------------------
function ns.IsUnitInBuffRange(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsUnit(unit, "player") then return true end
    if not UnitIsConnected(unit) then return false end
    if not UnitIsVisible(unit) then return false end
    local intName = SpellNames.ArcaneIntellect
    if intName then
        local inRange = IsSpellInRange(intName, unit)
        if inRange == 1 then return true end
        if inRange == 0 then return false end
    end
    return CheckInteractDistance(unit, 2)
end

function ns.GetNextIntTarget(petsOnly)
    local roster = ns.roster
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

---------------------------------------------------------------------------
-- Roster aggregates
---------------------------------------------------------------------------
function ns.CountNeedingInt()
    local roster = ns.roster
    local n = 0
    for _, class in ipairs(CLASS_ORDER) do
        local pl = roster[class]
        if pl then
            for _, p in ipairs(pl) do
                if p.needsInt then n = n + 1 end
            end
        end
    end
    return n
end

function ns.GetBuffReport()
    ns.ScanRoster()
    local roster = ns.roster
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
    if total == 0 then return "WizardBuff: No group members found" end
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
