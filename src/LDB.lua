local _, ns = ...
ns = ns or _G.WizardBuffAddon
assert(ns, "WizardBuff: load WizardBuff.lua before LDB.lua")

function ns.RegisterLDB(addon)
    local LDB       = LibStub("LibDataBroker-1.1")
    local LibDBIcon = LibStub("LibDBIcon-1.0")

    local function onEnter(frame)
        GameTooltip:SetOwner(frame, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
        GameTooltip:AddLine("Wizard Buff |cff666666v" .. ns.VERSION .. "|r", 1, 1, 1)

        local d = ns.db
        if d then
            local status = d.enabled and "|cff66dd66On|r" or "|cffff5555Off|r"
            GameTooltip:AddLine("Status: " .. status, 1, 1, 1)

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
                    GameTooltip:AddLine("Need Int: |cffff7777" .. need .. "|r", 1, 1, 1)
                end
            end

            local powder = ns.HasArcanePowder and ns.HasArcanePowder()
            if powder ~= nil then
                GameTooltip:AddLine("Arcane Powder: " .. (powder and "|cff66dd66Yes|r" or "|cffff5555No|r"), 1, 1, 1)
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: toggle  |  Right-click: settings", 0.65, 0.65, 0.65, true)
        GameTooltip:AddLine("Shift+click: lock/unlock", 0.65, 0.65, 0.65, true)
        GameTooltip:Show()
    end

    local function onLeave(frame)
        GameTooltip:Hide()
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
                        ns.Print(d.locked and "locked" or "unlocked")
                    end
                else
                    local d = ns.db
                    if d then
                        d.enabled = not d.enabled
                        ns.Print(d.enabled and "on" or "off")
                        if ns.ScheduleUpdate then ns.ScheduleUpdate() end
                    end
                end
            elseif button == "RightButton" then
                if ns.OpenConfig then ns.OpenConfig() end
            end
        end,

        OnEnter = onEnter,
        OnLeave = onLeave,
    })

    LibDBIcon:Register("WizardBuff", dataObj, addon.db.profile.minimap)
end
