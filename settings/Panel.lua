local _, ns = ...

-- Esc > Options > AddOns > Wizard Buff

local category

local function resetPosition()
    if InCombatLockdown() then return ns.say("Not in combat.") end
    ns.db.pos = ns.defaultPosition()
    ns.grid.place()
end

local function build()
    local layout
    category, layout = Settings.RegisterVerticalLayoutCategory("Wizard Buff")

    local function setting(key, label)
        local s = Settings.RegisterAddOnSetting(category, "WIZARDBUFF_" .. key:upper(), key, ns.db,
            type(ns.db[key]), label, ns.db[key])
        s:SetValueChangedCallback(function()
            ns.lookAgain()
            ns.updateMinimapButton()
        end)
        return s
    end
    local function checkbox(key, label, tip)
        Settings.CreateCheckbox(category, setting(key, label), tip)
    end
    local function slider(key, label, tip, min, max, step, format)
        local options = Settings.CreateSliderOptions(min, max, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, format)
        Settings.CreateSlider(category, setting(key, label), options, tip)
    end
    local function dropdown(key, label, tip, choices)
        local function options()
            local container = Settings.CreateControlTextContainer()
            for _, choice in ipairs(choices) do container:Add(choice[1], choice[2]) end
            return container:GetData()
        end
        Settings.CreateDropdown(category, setting(key, label), options, tip)
    end
    local function whole(v) return tostring(math.floor(v + 0.5)) end
    local function percent(v) return math.floor(v * 100 + 0.5) .. "%" end

    checkbox("shown", "Show", "/wb does the same.")
    dropdown("layout", "Layout", "List: one line per person. Frames: small cells side by side.",
        { { "list", "List" }, { "frames", "Frames" } })
    checkbox("onlyNeeded", "Only when needed", "Hide while nobody needs a buff.")
    checkbox("hideResting", "Hide in cities", "Hide while resting.")
    checkbox("fade", "Fade when idle", "Dim while nobody needs a buff. Full again on mouseover.")
    slider("scale", "Size", nil, 0.5, 2, 0.05, percent)
    slider("remind", "Rebuff early (min)", "Ask for a rebuff this many minutes before it runs out. 0 = off.",
        0, 15, 1, whole)
    checkbox("brilliance", "Auto Brilliance", "The Buff next key casts Arcane Brilliance when enough people "
        .. "need Intellect.")
    slider("brillianceMin", "Brilliance at", "How many people must need it.", 2, 10, 1, whole)
    checkbox("readyCheck", "Ready check alert", "On a ready check, list who has no Intellect.")
    checkbox("sound", "Sound", "A sound when someone newly needs Intellect.")
    checkbox("minimap", "Minimap button", "Drag it along the minimap's rim.")
    layout:AddInitializer(CreateSettingsButtonInitializer("Position", "Reset", resetPosition,
        "Back to the middle of the screen. Alt-drag the title bar to move.", true))

    Settings.RegisterAddOnCategory(category)
end

function ns.buildSettings()
    local ok, err = pcall(build)
    if not ok then
        category = nil
        ns.say("Settings failed to load: " .. tostring(err))
    end
end

function ns.openSettings()
    if category then
        Settings.OpenToCategory(category:GetID())
    else
        ns.say("No settings screen. Try /wb help.")
    end
end
