local _, ns = ...

local TEXT_LIFETIME = 4.0
local FADE_DURATION = 1.3
local FRAME_W      = 400
local FRAME_H      = 80

function ns.CreateMessageFrame()
    local mf = ns.mainFrame
    if not mf then return end

    local f = CreateFrame("MessageFrame", "WizardBuffMessageFrame", UIParent)
    f:SetSize(FRAME_W, FRAME_H)
    f:SetPoint("TOP", mf, "BOTTOM", 0, -4)
    f:SetFrameStrata("DIALOG")
    f:SetInsertMode("TOP")

    f:SetFontObject(GameFontNormalSmall)
    f:SetJustifyH("CENTER")

    f:SetFading(true)
    f:SetFadeDuration(FADE_DURATION)
    f:SetTimeVisible(TEXT_LIFETIME)

    ns.msgFrame = f
end

function ns.ShowMessage(text, r, g, b)
    local f = ns.msgFrame
    if not f then return end
    f:AddMessage(text, r or 0.75, g or 0.82, b or 0.9)
end
