local _, ns = ...

function ns.GetBuffReport()
    ns.ScanRoster()
    local total, buffed, needByClass = 0, 0, {}
    for _, class in ipairs(ns.CLASS_ORDER) do
        if ns.roster[class] then
            for _, p in ipairs(ns.roster[class]) do
                total = total + 1
                if not p.needsInt then
                    buffed = buffed + 1
                else
                    needByClass[class] = needByClass[class] or {}
                    needByClass[class][#needByClass[class] + 1] = p.name
                end
            end
        end
    end
    if total == 0 then return "WizardBuff: No group members found" end
    if buffed == total then return "WizardBuff: " .. total .. "/" .. total .. " buffed -- all good!" end
    local parts = {}
    for _, class in ipairs(ns.CLASS_ORDER) do
        if needByClass[class] then
            parts[#parts + 1] = class .. "(" .. table.concat(needByClass[class], ", ") .. ")"
        end
    end
    return "WizardBuff: " .. buffed .. "/" .. total .. " buffed. Need: " .. table.concat(parts, ", ")
end
