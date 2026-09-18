local _, ns = ...

function ns.CreateMessageFrame()
    if not ns.mainFrame then return end
    local f = CreateFrame("MessageFrame", "WizardBuffMessageFrame", UIParent)
    f:SetSize(420, 80)
    f:SetPoint("TOP", ns.mainFrame, "BOTTOM", 0, -6)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(50)
    f:SetInsertMode("TOP")
    f:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    f:SetShadowOffset(1, -1)
    f:SetFading(true)
    f:SetFadeDuration(1.3)
    f:SetTimeVisible(4)
    f:Show()
    ns.msgFrame = f
end

function ns.ShowMessage(text, r, g, b)
    if ns.msgFrame then
        ns.msgFrame:AddMessage(text, r or 0.75, g or 0.82, b or 0.9)
    end
end
