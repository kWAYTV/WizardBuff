local _, ns = ...

function ns.CreateTimer(btn)
    local t = btn:CreateFontString(nil, "OVERLAY")
    t:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    t:SetPoint("BOTTOM", btn, "BOTTOM", 0, 1)
    t:SetTextColor(1, 1, 1, 0.95)
    t:SetShadowOffset(1, -1)
    t:SetText("")
    btn.timerText = t
end

local function formatTimer(sec)
    if sec >= 3600 then
        return string.format("%dh", math.floor(sec / 3600)), true
    elseif sec >= 60 then
        return string.format("%dm", math.ceil(sec / 60)), true
    else
        return string.format("%ds", math.floor(sec)), false
    end
end

function ns.RefreshTimerText(btn)
    if not btn or not btn.timerText then return end
    if not ns.db or not ns.db.showTimers then btn.timerText:SetText(""); return end
    local exp = btn._expiresAt
    if not exp then btn.timerText:SetText(""); return end
    local sec = exp - GetTime()
    if sec <= 0 then btn.timerText:SetText(""); return end
    local text, isLong = formatTimer(sec)
    btn.timerText:SetText(text)
    btn.timerText:SetTextColor(isLong and 1 or 1, isLong and 1 or 0.6, isLong and 1 or 0.3)
end

function ns.SetButtonTimer(btn, sec)
    if not btn then return end
    btn._expiresAt = (sec and sec > 0) and (GetTime() + sec) or nil
    ns.RefreshTimerText(btn)
end
