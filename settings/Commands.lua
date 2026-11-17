local _, ns = ...

-- /wb

function ns.toggleShown()
    ns.db.shown = not ns.db.shown
    ns.say(ns.db.shown and "Shown." or "Hidden. /wb to show.")
    ns.lookAgain()
end

local function reset()
    if InCombatLockdown() then return ns.say("Not in combat.") end
    ns.db.pos = ns.defaultPosition()
    ns.db.scale, ns.db.shown = 1, true
    ns.grid.place()
    ns.lookAgain()
end

local function scale(arg)
    local n = tonumber(arg)
    if not n then return ns.say("Like this: /wb scale 1.2") end
    ns.db.scale = math.min(2, math.max(0.5, n))
    ns.lookAgain()
end

local COMMANDS = {
    [""] = ns.toggleShown,
    config = function() ns.openSettings() end,
    reset = reset,
    scale = scale,
    debug = function() ns.debug() end,
}
COMMANDS.options, COMMANDS.settings = COMMANDS.config, COMMANDS.config

SLASH_WIZARDBUFF1, SLASH_WIZARDBUFF2, SLASH_WIZARDBUFF3 = "/wb", "/wbuff", "/wizardbuff"
SlashCmdList.WIZARDBUFF = function(msg)
    if not ns.isMage then return ns.say("Mages only.") end
    local cmd, arg = strsplit(" ", strlower(strtrim(msg or "")), 2)
    local run = COMMANDS[cmd]
    if run then return run(arg) end
    ns.say("/wb (show / hide), /wb config, /wb scale 1.2, /wb reset, /wb debug")
end
