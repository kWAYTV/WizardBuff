local _, ns = ...

-- One cell: a secure button that casts on click. It carries every part
-- either layout uses (background, label, right-hand text, timer line, mark,
-- border); the layout decides where they go and which show.
--
-- Clicks fire on release ("AnyUp" with useOnKeyDown off), and every cast
-- attribute carries its button number (type1, spell1...): an unnumbered
-- "type" would answer every mouse button.

local grid = ns.grid

function grid.cell(name)
    local b = CreateFrame("Button", name, grid.frame, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp")
    b:SetAttribute("useOnKeyDown", false)
    b:Hide()

    b.back = b:CreateTexture(nil, "BACKGROUND")
    b.back:SetAllPoints()
    b.bar = b:CreateTexture(nil, "ARTWORK")
    b.mark = b:CreateTexture(nil, "ARTWORK")

    -- A stock font until the first fit, so text set before it doesn't error.
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.label:SetJustifyH("LEFT")
    b.label:SetWordWrap(false)
    b.side = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.side:SetJustifyH("RIGHT")

    b.edges = {}
    for i = 1, 4 do
        local edge = b:CreateTexture(nil, "OVERLAY", nil, 7)
        ns.pixel.sharp(edge)
        b.edges[i] = edge
    end

    local hover = b:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.12)

    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    grid.all[#grid.all + 1] = b
    return b
end

-- Four strips along the inside edges of a frame, one pixel thick.
function grid.fitEdges(edges, px)
    local top, bottom, left, right = edges[1], edges[2], edges[3], edges[4]
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(px)
    bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(px)
    left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(px)
    right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(px)
end

-- state: a key of grid.LOOK. side: right-hand text. fraction: time left, 0-1.
function grid.paint(b, state, label, r, g, bl, side, fraction)
    b.state = state
    if not grid.style then return end  -- not fitted yet (logged in mid-combat)
    grid.style.paint(b, grid.LOOK[state], label, r, g, bl, side, fraction)
end

-- Secure attributes: written only when they change, out of combat only.
function grid.set(b, key, value)
    if b:GetAttribute(key) ~= value then b:SetAttribute(key, value) end
end
