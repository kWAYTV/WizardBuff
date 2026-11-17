local _, ns = ...

local grid = ns.grid

function grid.timeText(sec)
    if not sec then return "" end
    if sec >= 60 then return math.ceil(sec / 60) .. "m" end
    return math.max(0, math.floor(sec)) .. "s"
end

function grid.tip(owner, title, r, g, b)
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine(title, r or 1, g or 1, b or 1)
end

function grid.line(text, color)
    color = color or grid.GREY
    GameTooltip:AddLine(text, color[1], color[2], color[3], true)
end

-- "A, B, C, +2" from a list of names or member records.
function grid.names(list, limit)
    local out = {}
    for i = 1, math.min(#list, limit) do
        out[i] = type(list[i]) == "table" and list[i].name or list[i]
    end
    if #list > limit then out[#out + 1] = "+" .. (#list - limit) end
    return table.concat(out, ", ")
end
