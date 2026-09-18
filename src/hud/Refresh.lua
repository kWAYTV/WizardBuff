local _, ns = ...

function ns.RefreshHUD()
    local db, mf = ns.db, ns.mainFrame
    if not mf or not ns.isMage or not db or not db.enabled then
        if mf then mf:Hide() end
        return
    end
    if InCombatLockdown() then
        ns.ApplyHudFade()
        return
    end

    ns.ScanRoster()

    local armorSpell = ns.GetArmorSpell()
    local _, intSid = ns.GetHighestRankSpell(ns.SpellIDs.ArcaneIntellect)
    local brillSpell, brillSid
    if ns.HasArcanePowder() then
        brillSpell, brillSid = ns.GetHighestRankSpell(ns.SpellIDs.ArcaneBrilliance)
    end

    local ctx = {
        armorSpell     = armorSpell,
        preferBrill    = brillSpell and db.useArcaneBrilliance and true or false,
        intSid         = intSid,
        brillSid       = brillSid,
        brillSpell     = brillSpell,
        nextIntUnit    = nil,
        nextIntName    = nil,
        nextIntOOR     = false,
        nextIntPetUnit = nil,
        nextIntPetName = nil,
        nextIntPetOOR  = false,
    }
    ctx.nextIntUnit,    ctx.nextIntName,    ctx.nextIntOOR    = ns.GetNextIntTarget(false)
    ctx.nextIntPetUnit, ctx.nextIntPetName, ctx.nextIntPetOOR = ns.GetNextIntTarget(true)

    local autoSpec  = ns.ResolveAutoSpec(ctx)
    local groupSpec = ns.ResolveGroupSpec(ctx)

    ns.ApplyButtonSpec(ns.autoBuffButton, autoSpec)
    if ns.brillianceButton then
        ns.ApplyButtonSpec(ns.brillianceButton, groupSpec)
        ns.brillianceButton:Show()
    end
    if ns.shieldButton then
        if ns.AnyShieldKnown() and db.enableBubble then
            ns.ApplyButtonSpec(ns.shieldButton, ns.ResolveShieldSpec())
            ns.shieldButton:Show()
        else
            ns.shieldButton:Hide()
        end
    end

    ns.UpdateSoundReminder(autoSpec.soundKind, groupSpec.needsAction)

    local needN = ns.CountNeedingInt()
    ns.LayoutGrid(ns.BuildGridPlayers(), ctx.preferBrill, needN,
        needN > 0 and ctx.nextIntOOR and ctx.nextIntPetOOR)
end
