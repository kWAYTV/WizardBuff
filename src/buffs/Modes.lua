local _, ns = ...

function ns.BuildModeList(defs)
    local out = {}
    for _, d in ipairs(defs) do
        if not d.spellKey or ns.AnyRankKnown(d.spellKey) then
            out[#out + 1] = d
        end
    end
    return out
end

function ns.GetModeKey(modeVar, builder)
    local list = builder()
    local idx = (ns[modeVar] or 0) + 1
    if idx < 1 or idx > #list then return "auto" end
    return list[idx].key
end

local KEY_IDS = {
    FrostArmor = "FrostArmor", IceArmor = "IceArmor", MageArmor = "MageArmor",
    IceBarrier = "IceBarrier", ManaShield = "ManaShield",
    SelfInt = "ArcaneIntellect", int = "ArcaneIntellect",
    brill = "ArcaneBrilliance", ArcaneIntellect = "ArcaneIntellect",
    ArcaneBrilliance = "ArcaneBrilliance",
}

local MODE_TAG = {
    FrostArmor = "FA", IceArmor = "IA", MageArmor = "MA", SelfInt = "INT",
    int = "AI", brill = "AB", IceBarrier = "IB", ManaShield = "MS",
}

local ICON_ALIAS = {
    brill = "brill", int = "int", SelfInt = "int",
    IceBarrier = "iceBarrier", ManaShield = "manaShield",
    MageArmor = "mageArmor",
}

function ns.IconForModeKey(key)
    if not key or key == "auto" then return nil end
    local catalogKey = KEY_IDS[key]
    local ids = catalogKey and ns.SpellIDs[catalogKey]
    if ids then
        local _, sid = ns.GetHighestRankSpell(ids)
        if sid then
            local tex = ns.GetSpellTexture(sid)
            if tex then return tex end
        end
    end
    return ns.ICON_PATHS[ICON_ALIAS[key] or "frostArmor"]
end

function ns.CycleMode(modeVar, builder, delta)
    if InCombatLockdown() then return end
    local list = builder()
    if #list <= 1 then return end
    local cur = ns[modeVar] or 0
    cur = cur + (delta > 0 and 1 or -1)
    if cur >= #list then cur = 0 end
    if cur < 0 then cur = #list - 1 end
    ns[modeVar] = cur
    local entry = list[cur + 1]
    local btn = modeVar == "_selfMode" and ns.autoBuffButton
        or modeVar == "_groupMode" and ns.brillianceButton
        or ns.shieldButton
    if btn and btn.icon then
        local tex = ns.IconForModeKey(entry.key)
        if tex then btn.icon:SetTexture(tex) end
        if btn.modeTag then
            btn.modeTag:SetText(entry.key == "auto" and "" or (MODE_TAG[entry.key] or ""))
        end
    end
    ns.ShowMessage(entry.label, 0.75, 0.82, 0.9)
    ns.ScheduleUpdate(true)
end
