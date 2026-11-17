local _, ns = ...

-- The "frames" layout: small bordered cells side by side, one row per raid
-- group, the armor cell on the left.

local grid = ns.grid
local frames = { WIDTH = 76, HEIGHT = 20, GAP = 1 }
grid.styles = { frames = frames }

function frames.fitCell(b)
    local px = grid.px
    for _, edge in ipairs(b.edges) do edge:Show() end
    grid.fitEdges(b.edges, px)

    b.bar:ClearAllPoints()
    b.bar:SetPoint("BOTTOMLEFT", px, px)
    b.bar:SetHeight(2 * px)
    b.mark:ClearAllPoints()
    b.mark:SetPoint("RIGHT", -4 * px, 0)
    b.mark:SetSize(5 * px, 5 * px)

    b.label:ClearAllPoints()
    b.label:SetPoint("LEFT", 4 * px, px)
    b.label:SetPoint("RIGHT", -11 * px, px)
    b.side:ClearAllPoints()
    b.side:SetPoint("RIGHT", -4 * px, px)
end

function frames.paint(b, look, label, r, g, bl, side, fraction)
    b.back:SetColorTexture(look.back[1], look.back[2], look.back[3], look.back[4])
    for _, edge in ipairs(b.edges) do
        edge:SetColorTexture(look.edge[1], look.edge[2], look.edge[3], 1)
    end
    b.label:SetText(label or "")
    b.label:SetTextColor(r, g, bl, look.text)
    b.side:SetText(side or "")
    b.side:SetTextColor(1, 1, 1, look.text)

    -- The red block only where there's no text in its place.
    local mark = look.mark and not look.bar and not side
    if mark then b.mark:SetColorTexture(look.mark[1], look.mark[2], look.mark[3], 1) end
    b.mark:SetShown(mark and true or false)

    local width = b:GetWidth()
    if look.bar and fraction and fraction > 0 and width and width > 0 then
        b.bar:SetColorTexture(look.bar[1], look.bar[2], look.bar[3], 1)
        b.bar:SetWidth(math.max(grid.px, (width - 2 * grid.px) * math.min(1, fraction)))
        b.bar:Show()
    else
        b.bar:Hide()
    end
end

-- first: the armor cell (may be nil). rows: member cells, a list per row.
-- Returns the cells it placed and the overall size.
function frames.layout(first, rows)
    local stepX, stepY = grid.width + grid.gap, grid.height + grid.gap
    local placed, indent = {}, 0
    if first then
        grid.put(first, 0, 0)
        placed[first] = true
        indent = stepX
    end
    local widest = 0
    for r, row in ipairs(rows) do
        for c, cell in ipairs(row) do
            grid.put(cell, indent + (c - 1) * stepX, (r - 1) * stepY)
            placed[cell] = true
        end
        widest = math.max(widest, #row)
    end
    local width = math.max(grid.width, indent + widest * stepX - grid.gap)
    return placed, width, math.max(grid.height, #rows * stepY - grid.gap)
end
