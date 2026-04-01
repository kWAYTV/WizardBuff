local _, ns = ...

local SpellNames = ns.SpellNames
local playerGUID

local TRACKED = {}

local function initTracked()
    for _, name in pairs(SpellNames) do
        if name then TRACKED[name] = true end
    end
end

function ns.InitCastFeedback()
    playerGUID = UnitGUID("player")
    initTracked()
end

function ns.OnCombatLogEvent()
    if not playerGUID then return end

    local _, sub, _, srcGUID, _, _, _, _, destName, _, _,
          _, spellName, _, failedType = CombatLogGetCurrentEventInfo()

    if srcGUID ~= playerGUID then return end
    if not TRACKED[spellName] then return end

    if sub == "SPELL_CAST_FAILED" then
        local reason = failedType or "Failed"
        ns.ShowMessage(spellName .. " — " .. reason, 1, 0.5, 0.3)
    elseif sub == "SPELL_CAST_SUCCESS" and destName then
        ns.ShowMessage(spellName .. " → " .. destName, 0.4, 0.9, 0.4)
    end
end
