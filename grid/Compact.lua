local _, ns = ...

-- The "compact" layout: Decursive-style squares, no text. The fill is the
-- buff state, the strip along the bottom the class colour. One row per raid
-- group, the armor square on the left. Hover a square for the name.

local grid = ns.grid
local compact = { WIDTH = 16, HEIGHT = 16, GAP = 2 }
grid.styles.compact = compact

function compact.fitCell(b)
    local px = grid.px
    for _, edge in ipairs(b.edges) do
        edge:SetColorTexture(0, 0, 0, 1)
        edge:Show()
    end
    grid.fitEdges(b.edges, px)
    b.mark:Hide()

    -- The timer line becomes the class strip.
    b.bar:ClearAllPoints()
    b.bar:SetPoint("BOTTOMLEFT", px, px)
    b.bar:SetPoint("BOTTOMRIGHT", -px, px)
    b.bar:SetHeight(3 * px)
    b.bar:Show()
end

function compact.paint(b, look, _, r, g, bl)
    b.back:SetColorTexture(look.fill[1], look.fill[2], look.fill[3], look.fill[4])
    b.bar:SetColorTexture(r, g, bl, look.text)
    b.label:SetText("")
    b.side:SetText("")
end

compact.layout = grid.styles.frames.layout
