local _, ns = ...

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
                local need = ns.CountNeedingInt()
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

    local dataObj = LDB:NewDataObject("WizardBuff", {
        type  = "launcher",
        label = "Wizard Buff",
        icon  = ns.ICON_PATHS.int,

        OnClick = function(_, button)
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    ns.ToggleLock()
                else
                    local d = ns.db
                    if d then
                        d.enabled = not d.enabled
                        ns.Print(d.enabled and "on" or "off")
                        ns.ScheduleUpdate()
                    end
                end
            elseif button == "RightButton" then
                ns.OpenConfig()
            end
        end,

        OnEnter = onEnter,
        OnLeave = function() GameTooltip:Hide() end,
    })

    LibDBIcon:Register("WizardBuff", dataObj, addon.db.profile.minimap)
end
