local _, ns = ...

-- Entry in the minimap's addon list (TOC: AddonCompartmentFunc*).

function WizardBuff_OnCompartmentClick(_, mouse)
    if not ns.isMage then return ns.say("Mages only.") end
    if mouse == "RightButton" then ns.toggleShown() else ns.openSettings() end
end

function WizardBuff_OnCompartmentEnter(_, owner)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:AddLine("Wizard Buff", 1, 1, 1)
    GameTooltip:AddLine("Left-click: settings", 0.6, 0.6, 0.6)
    GameTooltip:AddLine("Right-click: show / hide", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

function WizardBuff_OnCompartmentLeave()
    GameTooltip:Hide()
end
