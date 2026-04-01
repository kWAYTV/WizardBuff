local _, ns = ...

local SpellNames = ns.SpellNames
local playerGUID

local TRACKED = {}
local lastClickAt = 0
local CLICK_WINDOW = 0.4

local function initTracked()
    for _, name in pairs(SpellNames) do
        if name then TRACKED[name] = true end
    end
end

function ns.InitCastFeedback()
    playerGUID = UnitGUID("player")
    initTracked()
end

function ns.MarkCastAttempt()
    lastClickAt = GetTime()
end

function ns.OnUIErrorMessage(_, msg)
    if (GetTime() - lastClickAt) > CLICK_WINDOW then return end
    lastClickAt = 0
    ns.ShowMessage(msg, 1, 0.5, 0.3)
end

function ns.OnCombatLogEvent()
    if not playerGUID then return end

    local _, sub, _, srcGUID, _, _, _, _, destName, _, _,
          _, spellName, _, failedType = CombatLogGetCurrentEventInfo()

    if srcGUID ~= playerGUID then return end
    if not TRACKED[spellName] then return end

    if sub == "SPELL_CAST_FAILED" then
        ns.ShowMessage(spellName .. " — " .. (failedType or "Failed"), 1, 0.5, 0.3)
    elseif sub == "SPELL_CAST_SUCCESS" and destName then
        ns.ShowMessage(spellName .. " → " .. destName, 0.4, 0.9, 0.4)
    end
end
