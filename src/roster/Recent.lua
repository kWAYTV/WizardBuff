local _, ns = ...

ns.RECENTLY_BUFFED_SEC = 4

function ns.MarkRecentlyBuffed(unit)
    ns._recentlyBuffed[unit] = GetTime()
end

function ns.IsRecentlyBuffed(unit)
    local t = ns._recentlyBuffed[unit]
    return t and (GetTime() - t) < ns.RECENTLY_BUFFED_SEC
end
