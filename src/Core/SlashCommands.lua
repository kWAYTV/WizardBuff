local _, ns = ...

local COMMANDS = {
    ["toggle"] = function(db)
        db.enabled = not db.enabled
        ns.Print(db.enabled and "on" or "off")
        ns.ScheduleUpdate()
    end,
    ["config"] = function() ns.OpenConfig() end,
    ["options"] = function() ns.OpenConfig() end,
    ["settings"] = function() ns.OpenConfig() end,
    ["lock"] = function()
        ns.ToggleLock()
    end,
    ["grid"] = function(db)
        db.showClassRows = not db.showClassRows
        ns.Print("Buff grid " .. (db.showClassRows and "on" or "off"))
        ns.ScheduleUpdate()
    end,
    ["armor"] = function(db)
        db.buffArmor = not db.buffArmor
        ns.Print("Armor " .. (db.buffArmor and "on" or "off"))
        ns.ScheduleUpdate()
    end,
    ["bubble"] = function(db)
        db.enableBubble = not db.enableBubble
        ns.Print("Bubble " .. (db.enableBubble and "on" or "off"))
        ns.ScheduleUpdate()
    end,
    ["int"] = function(db)
        db.buffIntellect = not db.buffIntellect
        ns.Print("Intellect " .. (db.buffIntellect and "on" or "off"))
        ns.ScheduleUpdate()
    end,
    ["brilliance"] = function(db)
        db.useArcaneBrilliance = not db.useArcaneBrilliance
        ns.Print("Brilliance preference " .. (db.useArcaneBrilliance and "on" or "off"))
        ns.ScheduleUpdate()
    end,
    ["pets"] = function(db)
        db.buffPets = not db.buffPets
        ns.Print("Pets " .. (db.buffPets and "on" or "off"))
        ns.ScheduleUpdate()
    end,
    ["report"] = function()
        local report = ns.GetBuffReport()
        local channel = IsInRaid() and "RAID" or IsInGroup() and "PARTY" or nil
        if channel then
            SendChatMessage(report, channel)
        else
            ns.Print(report)
        end
    end,
    ["macro"] = function()
        ns.Print("Self buff macro: /click WizardBuffAutoBuffButton")
        ns.Print("Group buff macro: /click WizardBuffBrillianceButton")
        ns.Print("Shield macro: /click WizardBuffShieldButton")
    end,
}

COMMANDS["intellect"]  = COMMANDS["int"]
COMMANDS["rows"]       = COMMANDS["grid"]
COMMANDS["classrows"]  = COMMANDS["grid"]

function ns.addon:SlashHandler(input)
    local cmd = ((input or ""):lower()):match("^(%S*)") or ""
    local db = ns.db
    if not db then return end

    if cmd == "" then cmd = "toggle" end

    local handler = COMMANDS[cmd]
    if handler then
        handler(db)
    else
        ns.Print("/wbuff toggle | config | lock | grid | armor | bubble | int | brilliance | pets | report | macro")
    end
end
