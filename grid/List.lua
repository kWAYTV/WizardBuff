local _, ns = ...

-- The "list" layout: a dark panel with a title bar, one line per person,
-- name on the left and time left on the right.

local grid = ns.grid
local list = { WIDTH = 140, HEIGHT = 15, GAP = 0, plate = true }
grid.styles.list = list

function list.fitCell(b)
    local px = grid.px
    for _, edge in ipairs(b.edges) do edge:Hide() end
    b.bar:Hide()

    -- The mark is a strip down the left side.
    b.mark:ClearAllPoints()
    b.mark:SetPoint("TOPLEFT")
    b.mark:SetPoint("BOTTOMLEFT")
    b.mark:SetWidth(2 * px)

    b.side:ClearAllPoints()
    b.side:SetPoint("RIGHT", -5 * px, 0)
    b.label:ClearAllPoints()
    b.label:SetPoint("LEFT", 6 * px, 0)
    b.label:SetPoint("RIGHT", -44 * px, 0)
end

function list.paint(b, look, label, r, g, bl, side)
    b.back:SetColorTexture(look.row[1], look.row[2], look.row[3], look.row[4])
    b.label:SetText(label or "")
    b.label:SetTextColor(r, g, bl, look.text)
    b.side:SetText(side or look.word or "")
    b.side:SetTextColor(look.side[1], look.side[2], look.side[3], 1)
    if look.mark then b.mark:SetColorTexture(look.mark[1], look.mark[2], look.mark[3], 1) end
    b.mark:SetShown(look.mark and true or false)
end

-- Everything in one column under the title bar: armor first, then members.
function list.layout(first, rows)
    local placed, y = {}, grid.height + grid.px  -- below the title bar
    local function add(cell)
        grid.put(cell, grid.px, y)
        placed[cell] = true
        y = y + grid.height
    end
    if first then add(first) end
    for _, row in ipairs(rows) do
        for _, cell in ipairs(row) do add(cell) end
    end
    return placed, grid.width + 2 * grid.px, y + grid.px
end
