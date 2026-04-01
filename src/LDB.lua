local _, ns = ...
ns = ns or _G.WizardBuffAddon
assert(ns, "WizardBuff: load WizardBuff.lua before LDB.lua")

function WizardBuff_RegisterLDB(addon)
    local LDB       = LibStub("LibDataBroker-1.1")
    local LibDBIcon = LibStub("LibDBIcon-1.0")
    local LibQTip   = LibStub("LibQTip-1.0", true)

    local tooltip

    local function releaseTooltip()
        if tooltip then
            LibQTip:Release(tooltip)
            tooltip = nil
        end
    end

    local function onEnter(frame)
        if not LibQTip then
            GameTooltip:SetOwner(frame, "ANCHOR_NONE")
            GameTooltip:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
            GameTooltip:AddLine("Wizard Buff", 1, 1, 1)
            GameTooltip:AddLine("Left-click: toggle  |  Right-click: settings", 0.65, 0.65, 0.65, true)
            GameTooltip:Show()
            return
        end

        releaseTooltip()
        tooltip = LibQTip:Acquire("WizardBuffLDB", 2, "LEFT", "RIGHT")
        tooltip:SmartAnchorTo(frame)
        tooltip:SetAutoHideDelay(0.15, frame)

        tooltip:AddHeader("|cff8eb4d4Wizard Buff|r |cff666666v" .. ns.VERSION .. "|r")
        tooltip:AddSeparator()

        local d = ns.db
        if d then
            local status = d.enabled and "|cff66dd66On|r" or "|cffff5555Off|r"
            tooltip:AddLine("Status", status)

            if ns.isMage and ns.roster then
                local need = 0
                for _, class in ipairs(ns.CLASS_ORDER) do
                    local pl = ns.roster[class]
                    if pl then
                        for _, p in ipairs(pl) do
                            if p.needsInt then need = need + 1 end
                        end
                    end
                end
                if need > 0 then
                    tooltip:AddLine("Need Int", "|cffff7777" .. need .. "|r")
                else
                    tooltip:AddLine("Need Int", "|cff66dd660|r")
                end
            end

            local powder = ns.HasArcanePowder and ns.HasArcanePowder()
            if powder ~= nil then
                tooltip:AddLine("Arcane Powder", powder and "|cff66dd66Yes|r" or "|cffff5555No|r")
            end
        end

        tooltip:AddSeparator()
        tooltip:AddLine("|cffccccccLeft-click|r", "|cff888888toggle on/off|r")
        tooltip:AddLine("|cffccccccRight-click|r", "|cff888888open settings|r")
        tooltip:AddLine("|cffccccccShift + click|r", "|cff888888lock / unlock|r")

        tooltip:Show()
    end

    local function onLeave(frame)
        if not LibQTip then
            GameTooltip:Hide()
        end
    end

    local dataObj = LDB:NewDataObject("WizardBuff", {
        type  = "launcher",
        label = "Wizard Buff",
        icon  = "Interface\\Icons\\Spell_Holy_MagicalSentry",

        OnClick = function(_, button)
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    local d = ns.db
                    if d then
                        d.locked = not d.locked
                        print("|cff8eb4d4Wizard Buff|r: " .. (d.locked and "locked" or "unlocked"))
                    end
                else
                    local d = ns.db
                    if d then
                        d.enabled = not d.enabled
                        print("|cff8eb4d4Wizard Buff|r: " .. (d.enabled and "on" or "off"))
                        if ns.ScheduleUpdate then ns.ScheduleUpdate() end
                    end
                end
            elseif button == "RightButton" then
                if ns.OpenConfig then ns.OpenConfig() end
            end
            releaseTooltip()
        end,

        OnEnter = onEnter,
        OnLeave = onLeave,
    })

    LibDBIcon:Register("WizardBuff", dataObj, addon.db.profile.minimap)
end
