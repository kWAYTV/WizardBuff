local _, ns = ...

local GetSpellInfo      = ns.Compat.GetSpellInfo
local SpellIDs          = ns.SpellIDs
local SpellNames        = ns.SpellNames
local ArmorBuffNames    = ns.ArmorBuffNames
local REFRESH_THRESHOLD = ns.REFRESH_THRESHOLD

--- Remaining seconds on a named buff, or nil if missing / indefinite.
function ns.GetBuffTimeRemaining(unit, buffName)
    if not unit or not buffName or not UnitExists(unit) then
        return nil
    end
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime = UnitBuff(unit, i)
        if not name then break end
        if name == buffName then
            if not duration or duration == 0 then return nil end
            return math.max(0, expirationTime - GetTime())
        end
    end
    return nil
end

--- Does the unit carry `buffName` with enough remaining time?
function ns.UnitHasBuff(unit, buffName)
    if not unit or not UnitExists(unit) then return false, nil end
    if not buffName then return false, nil end
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime, caster = UnitBuff(unit, i)
        if not name then break end
        if name == buffName then
            if not duration or duration == 0 then return true, caster end
            local remaining = expirationTime - GetTime()
            local floor = ns.db and ns.db.refreshFloorSec or 120
            if remaining > floor then return true, caster end
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
            if rem and (not best or rem < best) then best = rem end
        end
    end
    return best
end

function ns.PlayerHasShieldBuff()
    local function checkList(list)
        for _, id in ipairs(list) do
            if IsSpellKnown(id) then
                local name = GetSpellInfo(id)
                if name and ns.UnitHasBuff("player", name) then return true end
            end
        end
    end
    return checkList(SpellIDs.IceBarrier) or checkList(SpellIDs.ManaShield) or false
end

function ns.HasStrongerBrilliance(unit)
    if not unit or not UnitExists(unit) then return false end
    local brillName = SpellNames.ArcaneBrilliance
    if not brillName then return false end
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime, caster = UnitBuff(unit, i)
        if not name then break end
        if name == brillName then
            if caster and not UnitIsUnit(caster, "player") then
                if not duration or duration == 0 then return true end
                local remaining = expirationTime - GetTime()
                if remaining > duration * REFRESH_THRESHOLD then return true end
            end
        end
    end
    return false
end

function ns.SelfNeedsArmor()
    return ns.db.buffArmor and not ns.HasAnyArmorBuff()
end
