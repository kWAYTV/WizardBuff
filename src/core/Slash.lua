local _, ns = ...

local function report()
    local total, buffed, missing = 0, 0, {}
    for _, rec in ipairs(ns.members) do
        if not rec.isPet then
            total = total + 1
            if rec.int == "yes" then
                buffed = buffed + 1
            elseif rec.int == "no" and not rec.dead and not rec.offline then
                missing[rec.group] = missing[rec.group] or {}
                table.insert(missing[rec.group], rec.name)
            end
        end
    end
    if total == 0 then ns.Print("Nobody to report on."); return end
    local text = string.format("Intellect: %d/%d buffed", buffed, total)
    local parts = {}
    for g = 1, 8 do
        if missing[g] then parts[#parts + 1] = "G" .. g .. " " .. table.concat(missing[g], ", ") end
    end
    if #parts > 0 then text = text .. ". Missing: " .. table.concat(parts, "; ") end
    if #text > 250 then text = text:sub(1, 247) .. "..." end
    local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT"
        or (IsInRaid() and "RAID") or (IsInGroup() and "PARTY")
    if channel then
        local sendChat = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
        sendChat(text, channel)
    else
        ns.Print(text)
    end
end

function ns.PrintHelp()
    ns.Print("Commands:")
    print("  /wbuff - show or hide the HUD")
    print("  /wbuff config - open settings")
    print("  /wbuff lock - lock or unlock the HUD")
    print("  /wbuff mages - raid assignments between mages")
    print("  /wbuff report - post who is missing Intellect to group chat")
    print("  /wbuff reset - move the HUD back to the center")
end

local COMMANDS = {
    [""]     = function() ns.ToggleEnabled() end,
    config   = function() ns.OpenSettings() end,
    options  = function() ns.OpenSettings() end,
    lock     = function() ns.ToggleLock() end,
    mages    = function() ns.ToggleAssign() end,
    assign   = function() ns.ToggleAssign() end,
    report   = report,
    reset    = function()
        ns.db.pos = nil
        if InCombatLockdown() then ns.Print("Leave combat first."); return end
        ns.RestorePosition()
        ns.Print("HUD moved to the center.")
    end,
    help     = function() ns.PrintHelp() end,
}

SLASH_WIZARDBUFF1 = "/wbuff"
SLASH_WIZARDBUFF2 = "/wizardbuff"
SlashCmdList.WIZARDBUFF = function(input)
    if not ns.isMage then ns.Print("Wizard Buff is for mages."); return end
    local cmd = strtrim((input or ""):lower()):match("^(%S*)") or ""
    local fn = COMMANDS[cmd] or COMMANDS.help
    fn()
end
