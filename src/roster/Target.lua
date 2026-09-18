local _, ns = ...

function ns.IsUnitInBuffRange(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsUnit(unit, "player") then return true end
    if not UnitIsConnected(unit) or not UnitIsVisible(unit) then return false end
    local intName = ns.SpellName("ArcaneIntellect")
    if intName then
        local inRange = ns.IsSpellInRange(intName, unit)
        if inRange == 1 then return true end
        if inRange == 0 then return false end
    end
    return CheckInteractDistance and CheckInteractDistance(unit, 2) or false
end

function ns.GetNextIntTarget(petsOnly)
    local roster = ns.roster

    if not petsOnly then
        for _, class in ipairs(ns.CLASS_ORDER) do
            if class ~= "PET" and roster[class] then
                for _, p in ipairs(roster[class]) do
                    if p.needsInt and UnitIsUnit(p.unit, "player") then
                        return p.unit, p.name, false
                    end
                end
            end
        end
    end

    local function scan(inRangeOnly)
        for _, class in ipairs(ns.CLASS_ORDER) do
            local isPet = class == "PET"
            if (petsOnly and isPet) or (not petsOnly and not isPet) then
                if roster[class] then
                    for _, p in ipairs(roster[class]) do
                        if p.needsInt then
                            if not inRangeOnly or ns.IsUnitInBuffRange(p.unit) then
                                return p.unit, p.name, not ns.IsUnitInBuffRange(p.unit)
                            end
                        end
                    end
                end
            end
        end
    end

    local u, n, oor = scan(true)
    if u then return u, n, oor end
    u, n, oor = scan(false)
    if u then return u, n, true end
    return nil, nil, false
end

function ns.CountNeedingInt()
    local n = 0
    for _, class in ipairs(ns.CLASS_ORDER) do
        local pl = ns.roster[class]
        if pl then
            for _, p in ipairs(pl) do
                if p.needsInt then n = n + 1 end
            end
        end
    end
    return n
end
