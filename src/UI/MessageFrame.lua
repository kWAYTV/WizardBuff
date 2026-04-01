local _, ns = ...

local TEXT_LIFETIME = 4.0
local FADE_DURATION = 1.3
local FRAME_W      = 500
local FRAME_H      = 100

function ns.CreateMessageFrame()
    local mf = ns.mainFrame
    if not mf then return end

    local f = CreateFrame("MessageFrame", "WizardBuffMessageFrame", UIParent)
    f:SetSize(FRAME_W, FRAME_H)
    f:SetPoint("TOP", mf, "BOTTOM", 0, -4)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(50)
    f:SetInsertMode("TOP")

    f:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    f:SetShadowOffset(1, -1)

    f:SetFading(true)
    f:SetFadeDuration(FADE_DURATION)
    f:SetTimeVisible(TEXT_LIFETIME)

    f:Show()
    ns.msgFrame = f
end

function ns.ShowMessage(text, r, g, b)
    local f = ns.msgFrame
    if not f then return end
    f:AddMessage(text, r or 0.75, g or 0.82, b or 0.9)
end
