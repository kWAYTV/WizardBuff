local _, ns = ...

local SpellIDs = ns.SpellIDs

function ns.UpdateButtons()
    local db             = ns.db
    local mainFrame      = ns.mainFrame
    local autoBuffButton = ns.autoBuffButton
    local brillianceButton = ns.brillianceButton
    local shieldButton   = ns.shieldButton

    if not mainFrame or not ns.isMage or not db.enabled then
        if mainFrame then mainFrame:Hide() end
        return
    end
    if InCombatLockdown() then
        ns.ApplyHudFade()
        return
    end
    if UnitIsDeadOrGhost("player") then
        if mainFrame then mainFrame:Show() end
        ns.ApplyHudFade()
        return
    end

    ns.ScanRoster()

    local armorSpell        = ns.GetArmorSpell()
    local intSpell, intSid  = ns.GetHighestRankSpell(SpellIDs.ArcaneIntellect)
    local hasPowder         = ns.HasArcanePowder()
    local brillSpell, brillSid
    if hasPowder then
        brillSpell, brillSid = ns.GetHighestRankSpell(SpellIDs.ArcaneBrilliance)
    end
    local intToUse = (brillSpell and db.useArcaneBrilliance) and brillSpell or intSpell

    local nextIntUnit,    nextIntName,    nextIntOOR    = ns.GetNextIntTarget(false)
    local nextIntPetUnit, nextIntPetName, nextIntPetOOR = ns.GetNextIntTarget(true)

    local ctx = {
        armorSpell     = armorSpell,
        bubbleSpell    = ns.GetBubbleSpell(),
        intToUse       = intToUse,
        intSid         = intSid,
        brillSid       = brillSid,
        brillSpell     = brillSpell,
        nextIntUnit    = nextIntUnit,
        nextIntName    = nextIntName,
        nextIntOOR     = nextIntOOR,
        nextIntPetUnit = nextIntPetUnit,
        nextIntPetName = nextIntPetName,
        nextIntPetOOR  = nextIntPetOOR,
    }

    local autoSpec  = ns.ResolveAutoSpec(ctx)
    local groupSpec = ns.ResolveGroupSpec(ctx)

    ns.ApplyButtonSpec(autoBuffButton, autoSpec)
    if brillianceButton then
        ns.ApplyButtonSpec(brillianceButton, groupSpec)
        brillianceButton:Show()
    end

    if shieldButton then
        local hasAnyShield = ns.AnyShieldKnown and ns.AnyShieldKnown()
        if hasAnyShield and db.enableBubble then
            local shieldSpec = ns.ResolveShieldSpec()
            ns.ApplyButtonSpec(shieldButton, shieldSpec)
            shieldButton:Show()
        else
            shieldButton:Hide()
        end
    end

    ns.UpdateSoundReminder(autoSpec.soundKind, groupSpec.needsAction)

    local needN       = ns.CountNeedingInt()
    local gridPlayers = ns.BuildGridPlayers()
    local allOOR      = needN > 0 and nextIntOOR and nextIntPetOOR
    ns.LayoutGrid(gridPlayers, intToUse, needN, allOOR)
end
