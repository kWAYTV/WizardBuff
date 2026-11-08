local _, ns = ...

-- Turns the roster and your own auras into a plan: what each bar slot
-- shows and casts, and what the keybind ("smart") button casts next.
--
-- plan.armor  { key, spell, need, left, dur }
-- plan.int    { spell, unit, guid, target, outOfRange, count, topUp }
-- plan.brill  { spell, unit, powder, count, ready }
-- plan.shield { spell, key, low }
-- plan.next   { spell, unit, guid, label, target, isInt }   (smart button)

ns.plan = {}

local function rebuffSeconds()
    return (ns.db.rebuffMinutes or 5) * 60
end

-- Does this member need Intellect right now?
function ns.MemberNeeds(rec)
    if rec.dead or rec.offline or rec.int == "unknown" then return false end
    if rec.int == "no" then return true end
    local left = ns.IntRemaining(rec)
    return left ~= nil and left < rebuffSeconds()
end

-- Last armor reading; kept through combat.
local armorState = { key = nil, expires = 0, duration = 0 }

local function readSelf()
    local key, exp, dur = ns.ReadArmor()
    if key ~= "unknown" then
        armorState.key, armorState.expires, armorState.duration = key, exp or 0, dur or 0
    end
end

-- Our own armor cast landed: trust it until the next reading.
function ns.PredictArmor(key, duration)
    armorState.key = key
    armorState.duration = duration or 1800
    armorState.expires = GetTime() + armorState.duration
end

local function armorPlan()
    local want = ns.ArmorKey()
    if not want then return nil end
    local have = armorState.key
    local p = { key = want, spell = ns.Best(want) }
    if have and (ns.db.armor == "auto" or have == want) then
        p.key = have
        p.spell = ns.Best(have) or p.spell
        p.left = ns.Remaining(armorState.expires)
        p.dur = armorState.duration
        p.need = p.left ~= nil and p.left < rebuffSeconds()
    else
        p.need = true
    end
    return p
end

function ns.ArmorRemaining()
    return armorState.key and ns.Remaining(armorState.expires)
end

local function pick(list)
    for _, rec in ipairs(list) do
        if rec.inRange then return rec end
    end
    return list[1]
end

function ns.BuildPlan()
    readSelf()
    local plan = ns.plan
    wipe(plan)

    local mine, needMine, needAll, inRangeNeed = {}, {}, 0, 0
    for _, rec in ipairs(ns.members) do
        rec.mine = ns.IsMine(rec)
        rec.needs = ns.MemberNeeds(rec)
        if rec.needs then
            needAll = needAll + 1
            if rec.mine then
                needMine[#needMine + 1] = rec
                if rec.inRange then inRangeNeed = inRangeNeed + 1 end
            end
        end
        if rec.mine then mine[#mine + 1] = rec end
    end
    plan.needMine, plan.needAll = #needMine, needAll

    -- Intellect target: yourself, then players, then pets.
    local selfNeed, players, pets = nil, {}, {}
    for _, rec in ipairs(needMine) do
        if rec.isMe then selfNeed = rec
        elseif rec.isPet then pets[#pets + 1] = rec
        else players[#players + 1] = rec end
    end
    local target = selfNeed or pick(players) or pick(pets)

    if ns.Knows("INTELLECT") then
        local p = { count = #needMine }
        local t = target
        if not t then
            -- Nobody needs it: a click tops up whoever has the least time left.
            local best, bestLeft
            for _, rec in ipairs(mine) do
                local left = ns.IntRemaining(rec)
                if rec.inRange and not rec.dead and not rec.offline and left and (not bestLeft or left < bestLeft) then
                    best, bestLeft = rec, left
                end
            end
            t = best
            p.topUp = true
        end
        if t then
            p.spell = ns.BestForLevel("INTELLECT", t.level)
            p.unit, p.guid = t.unit, t.guid
            p.target = t.isMe and "you" or t.name
            p.outOfRange = not t.inRange
        end
        plan.int = p
    end

    plan.powder = ns.PowderCount()
    if ns.Knows("BRILLIANCE") then
        local any = target or pick(mine) or ns.byGuid[UnitGUID("player")]
        plan.brill = {
            spell = ns.Best("BRILLIANCE"),
            unit = any and any.unit or "player",
            powder = plan.powder,
            count = inRangeNeed,
            ready = ns.db.useBrilliance and plan.powder > 0 and inRangeNeed >= (ns.db.brillianceMin or 3),
        }
    end

    plan.armor = armorPlan()

    local shield = ns.ShieldKey()
    if shield then
        plan.shield = { spell = ns.Best(shield), key = shield, low = ns.ShieldIsLow() }
    end

    -- The smart button: armor, then Brilliance when worth it, then Intellect.
    local a, b, i = plan.armor, plan.brill, plan.int
    if a and a.need and a.spell then
        plan.next = { spell = a.spell, unit = "player", label = ns.SpellName(a.key), target = "you" }
    elseif b and b.ready and target and (target.level or 0) >= 46 then
        plan.next = { spell = b.spell, unit = b.unit, label = ns.SpellName("BRILLIANCE"), target = "group" }
    elseif i and not i.topUp and i.spell then
        plan.next = {
            spell = i.spell, unit = i.unit, guid = i.guid, isInt = true,
            label = C_Spell.GetSpellName(i.spell), target = i.target, outOfRange = i.outOfRange,
        }
    end

    return plan
end

function ns.ShieldIsLow()
    local hp = ns.PlayerHealthPercent()
    return hp ~= nil and hp < (ns.db.shieldHealth or 60)
end
