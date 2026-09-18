local _, ns = ...

function ns.CreateMainFrame()
    local mf = CreateFrame("Frame", "WizardBuffFrame", UIParent)
    ns.mainFrame = mf
    mf:SetSize(ns.GRIP_W + ns.ICON_SIZE * 2 + ns.ICON_GAP + ns.STATUS_W, ns.ICON_SIZE)

    local pos = ns.db and ns.db.hudPos
    if pos and pos.point and pos.relPoint and pos.x and pos.y then
        mf:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        mf:SetPoint("CENTER", 0, 200)
    end

    mf:SetMovable(true)
    mf:EnableMouse(false)
    mf:SetClampedToScreen(true)
    mf:SetFrameStrata("HIGH")
    mf:SetFrameLevel(20)
    mf:SetScript("OnEnter", function()
        ns._hudMouseOver = true
        ns.ApplyHudFade()
    end)
    mf:SetScript("OnLeave", function() ns.ScheduleHudLeaveCheck(mf) end)

    local timerElapsed = 0
    mf:SetScript("OnUpdate", function(_, dt)
        timerElapsed = timerElapsed + dt
        if timerElapsed < 1 then return end
        timerElapsed = 0
        if ns.autoBuffButton then ns.RefreshTimerText(ns.autoBuffButton) end
        if ns.brillianceButton then ns.RefreshTimerText(ns.brillianceButton) end
    end)

    ns.ApplyHudScale()
    mf:Show()
end

function ns.CreateHUD()
    ns.CreateMainFrame()
    ns.CreateMessageFrame()
    ns.CreateHandle()
    ns.UpdateHandleVisibility()
    ns.CreateAutoBuffButton()
    ns.CreateBrillianceButton()
    ns.CreateShieldButton()
    ns.PlaceHudIcons(ns.mainFrame, ns.GRIP_W)
    ns.ApplyHudFade()
    ns.ApplyHudScale()
    ns.mainFrame:Show()
end
