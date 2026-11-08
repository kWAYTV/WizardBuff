local _, ns = ...

-- Turns the roster and self auras into a plan: what the Buff and Shield
-- buttons cast next, and which grid cells need attention.

ns.plan = {}

local function rebuffSeconds()
    return (ns.db.rebuffMinutes or 5) * 60
end

-- Does this member need Intellect from us right now?
function ns.MemberNeeds(rec)
    if rec.dead or rec.offline or rec.int == "unknown" then return false end
    if rec.int == "no" then return true end
    local left = ns.IntRemaining(rec)
    return left ~= nil and left < rebuffSeconds()
end

local armorState = { key = nil, expires = 0 }

local function readSelf()
    local key, exp = ns.ReadArmor()
    if key ~= "unknown" then
        armorState.key, armorState.expires = key, exp or 0
    end
end

local function armorNeed()
    local want = ns.ArmorKey()
    if not want then return nil end
    local have = armorState.key
    if not have then return want end
    -- Respect a manual pick in settings; on "auto" any armor is fine.
    if ns.db.armor ~= "auto" and have ~= want then return want end
    local left = ns.Remaining(armorState.expires)
    if left and left < rebuffSeconds() then return have end
    return nil
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
    plan.powder = ns.PowderCount()

    -- Order: our own armor, our own Intellect, players, then pets.
    local selfNeed, players, pets = nil, {}, {}
    for _, rec in ipairs(needMine) do
        if rec.isMe then selfNeed = rec
        elseif rec.isPet then pets[#pets + 1] = rec
        else players[#players + 1] = rec end
    end

    local armor = armorNeed()
    local useBrill = ns.db.useBrilliance and ns.Knows("BRILLIANCE") and plan.powder > 0
        and inRangeNeed >= (ns.db.brillianceMin or 3)

    local target = selfNeed or pick(players) or pick(pets)

    if armor then
        plan.buff = { spell = ns.Best(armor), unit = "player", label = ns.SpellName(armor), target = "you" }
    elseif target then
        local spell
        if useBrill and (target.level or 0) >= 46 then
            spell = ns.Best("BRILLIANCE")
            plan.brilliance = true
        else
            spell = ns.BestForLevel("INTELLECT", target.level)
        end
        if spell then
            plan.buff = {
                spell = spell, unit = target.unit, guid = target.guid,
                label = C_Spell.GetSpellName(spell), target = target.isMe and "you" or target.name,
                outOfRange = not target.inRange, isInt = true,
            }
        end
    end

    -- Right-click on the Buff button: Brilliance on the best target.
    if ns.Knows("BRILLIANCE") then
        local any = target or pick(mine) or ns.byGuid[UnitGUID("player")]
        plan.brillUnit = any and any.unit or "player"
    end

    local shield = ns.ShieldKey()
    if shield then
        local hp = ns.PlayerHealthPercent()
        plan.shield = {
            spell = ns.Best(shield), label = ns.SpellName(shield),
            low = hp ~= nil and hp < (ns.db.shieldHealth or 60),
        }
    end

    return plan
end

-- Cheap in-combat update for the shield glow.
function ns.ShieldIsLow()
    local hp = ns.PlayerHealthPercent()
    return hp ~= nil and hp < (ns.db.shieldHealth or 60)
end
