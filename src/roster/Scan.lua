local _, ns = ...

function ns.ScanRoster()
    local roster, db = ns.roster, ns.db
    wipe(roster)
    local intName   = ns.SpellName("ArcaneIntellect")
    local brillName = ns.SpellName("ArcaneBrilliance")

    local function addUnit(unit)
        if not UnitExists(unit) then return end
        local name = GetUnitName(unit, true)
        local _, class = UnitClass(unit)
        if not class or not name then return end
        local isDead    = UnitIsDeadOrGhost(unit)
        local isOffline = not UnitIsConnected(unit)
        local stronger  = ns.HasStrongerBrilliance(unit)
        local hasInt    = ns.UnitHasBuff(unit, intName)
        local hasBrill  = ns.UnitHasBuff(unit, brillName)
        local needsInt  = db.buffIntellect
            and not isDead and not isOffline
            and not stronger and not hasInt and not hasBrill
            and not ns.IsRecentlyBuffed(unit)
        roster[class] = roster[class] or {}
        roster[class][#roster[class] + 1] = {
            unit = unit, name = name, class = class, needsInt = needsInt,
            level = UnitLevel(unit), hasStrongerBrill = stronger,
            isDead = isDead, isOffline = isOffline,
        }
    end

    local function addPet(petUnit, ownerName)
        if not db.buffPets or not UnitExists(petUnit) then return end
        if UnitIsDeadOrGhost(petUnit) then return end
        local petName = GetUnitName(petUnit, false)
        if not petName then return end
        local stronger = ns.HasStrongerBrilliance(petUnit)
        local needsInt = db.buffIntellect
            and not stronger
            and not ns.UnitHasBuff(petUnit, intName)
            and not ns.UnitHasBuff(petUnit, brillName)
            and not ns.IsRecentlyBuffed(petUnit)
        roster.PET = roster.PET or {}
        roster.PET[#roster.PET + 1] = {
            unit = petUnit, name = petName, class = "PET", needsInt = needsInt,
            level = UnitLevel(petUnit), ownerName = ownerName, hasStrongerBrill = stronger,
        }
    end

    if IsInRaid() then
        for i = 1, 40 do
            addUnit("raid" .. i)
            addPet("raidpet" .. i, GetUnitName("raid" .. i, false))
        end
    elseif IsInGroup() then
        addUnit("player")
        addPet("pet", UnitName("player"))
        for i = 1, 4 do
            addUnit("party" .. i)
            addPet("partypet" .. i, GetUnitName("party" .. i, false))
        end
    elseif db.showWhenSolo then
        addUnit("player")
        addPet("pet", UnitName("player"))
    end
    return roster
end
