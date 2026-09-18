local _, ns = ...

local autoLockTimer

local function cancelAutoLock()
    if autoLockTimer then autoLockTimer:Cancel(); autoLockTimer = nil end
end

local function scheduleAutoLock()
    cancelAutoLock()
    autoLockTimer = C_Timer.NewTimer(ns.AUTO_LOCK_SEC, function()
        autoLockTimer = nil
        if ns.db and not ns.db.locked then
            ns.db.locked = true
            ns.Print("Auto-locked after " .. ns.AUTO_LOCK_SEC .. "s")
        end
    end)
end

ns.CancelAutoLock = cancelAutoLock
ns.ScheduleAutoLock = scheduleAutoLock

function ns.ToggleLock()
    local db = ns.db
    if not db then return end
    db.locked = not db.locked
    if db.locked then
        cancelAutoLock()
        ns.Print("Locked")
    else
        scheduleAutoLock()
        ns.Print("Unlocked (auto-locks in " .. ns.AUTO_LOCK_SEC .. "s)")
    end
end

function ns.CreateHandle()
    local mf = ns.mainFrame
    local h = CreateFrame("Button", "WizardBuffHandle", mf)
    ns.handle = h
    h:SetSize(ns.GRIP_W, ns.ICON_SIZE)
    h:SetPoint("TOPLEFT", mf, "TOPLEFT", 0, 0)
    h:SetFrameLevel(mf:GetFrameLevel() + 5)
    h:EnableMouse(true)
    h:RegisterForClicks("AnyUp")

    for i = 1, 3 do
        local dot = h:CreateTexture(nil, "ARTWORK")
        ns.SetSolidColor(dot, 0.55, 0.55, 0.58, 0.7)
        dot:SetSize(2, 2)
        dot:SetPoint("CENTER", h, "CENTER", 0, 5 - (i - 1) * 5)
    end

    local need = mf:CreateFontString(nil, "OVERLAY")
    need:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    need:SetJustifyH("LEFT")
    need:SetTextColor(0.7, 0.7, 0.7)
    need:SetText("")
    mf.needLine = need

    local function tip(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Wizard Buff", 0.6, 0.8, 1)
        if ns.db and ns.db.locked then
            GameTooltip:AddLine("Shift+click · unlock to move", 0.55, 0.55, 0.55)
        else
            GameTooltip:AddLine("Alt+drag · move", 0.55, 0.55, 0.55)
            GameTooltip:AddLine("Shift+click · lock", 0.55, 0.55, 0.55)
        end
        GameTooltip:AddLine("Right-click · config", 0.55, 0.55, 0.55)
        GameTooltip:Show()
    end

    h:SetScript("OnEnter", function(self)
        ns._hudMouseOver = true
        ns.ApplyHudFade()
        tip(self)
    end)
    h:SetScript("OnLeave", function()
        GameTooltip:Hide()
        ns.ScheduleHudLeaveCheck(mf)
    end)
    h:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and IsAltKeyDown()
            and not InCombatLockdown()
            and not (ns.db and ns.db.locked) then
            h._isMoving = true
            cancelAutoLock()
            mf:StartMoving()
        end
    end)
    h:SetScript("OnMouseUp", function(_, button)
        if h._isMoving then
            mf:StopMovingOrSizing()
            h._isMoving = false
            if ns.db then
                local point, _, relPoint, x, y = mf:GetPoint(1)
                ns.db.hudPos = { point = point, relPoint = relPoint, x = x, y = y }
            end
            if ns.db and not ns.db.locked then scheduleAutoLock() end
            return
        end
        if IsShiftKeyDown() then
            ns.ToggleLock()
            tip(h)
        elseif button == "RightButton" then
            if ns.OpenConfig then ns.OpenConfig() end
        end
    end)
    h:SetScript("OnHide", function()
        if h._isMoving then mf:StopMovingOrSizing(); h._isMoving = false end
    end)
end

function ns.UpdateHandleVisibility()
    if not ns.handle then return end
    if ns.db and ns.db.showDragHandle == false then
        ns.handle:Hide()
    else
        ns.handle:Show()
    end
end
