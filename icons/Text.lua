local _, ns = ...

local icons = {}
ns.icons = icons

icons.RED = { 1, 0.3, 0.3 }
icons.GREEN = { 0.4, 0.9, 0.45 }
icons.ORANGE = { 1, 0.7, 0.25 }
icons.GREY = { 0.6, 0.6, 0.6 }

function icons.timeText(sec)
    if not sec then return "" end
    if sec >= 60 then return math.ceil(sec / 60) .. "m" end
    return math.max(0, math.floor(sec)) .. "s"
end

function icons.tip(owner, title)
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine(title, 1, 1, 1)
end

function icons.line(text, color)
    color = color or icons.GREY
    GameTooltip:AddLine(text, color[1], color[2], color[3], true)
end
