local _, ns = ...

function ns.BuildGroupModeList()
    return ns.BuildModeList({
        { key = "auto",  label = "Auto" },
        { key = "int",   label = "Intellect",  spellKey = "ArcaneIntellect" },
        { key = "brill", label = "Brilliance", spellKey = "ArcaneBrilliance" },
    })
end

function ns.GetGroupModeKey()
    return ns.GetModeKey("_groupMode", ns.BuildGroupModeList)
end
