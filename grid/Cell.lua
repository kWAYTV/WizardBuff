local _, ns = ...

-- One cell: a secure button that casts on click. Dark background, a label
-- on the left, optional text on the right, a thin timer line along the
-- bottom, a one-pixel border.
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
    b.bar:SetPoint("BOTTOMLEFT")
    b.bar:Hide()

    b.mark = b:CreateTexture(nil, "ARTWORK")
    b.mark:SetColorTexture(0.85, 0.21, 0.21, 1)
    b.mark:Hide()

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

-- Sizes the insides for the current pixel size. The cell's own size is set
-- by the layout. Out of combat only.
function grid.fitCell(b)
    local px, font = grid.px, grid.font
    local top, bottom, left, right = b.edges[1], b.edges[2], b.edges[3], b.edges[4]
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(px)
    bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(px)
    left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(px)
    right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(px)

    b.bar:SetPoint("BOTTOMLEFT", px, px)
    b.bar:SetHeight(2 * px)
    b.mark:SetSize(5 * px, 5 * px)
    b.mark:SetPoint("RIGHT", -4 * px, 0)

    b.label:SetFont(font, grid.fontSize, "OUTLINE")
    b.label:SetPoint("LEFT", 4 * px, px)
    b.label:SetPoint("RIGHT", -11 * px, px)
    b.side:SetFont(font, grid.fontSize, "OUTLINE")
    b.side:SetPoint("RIGHT", -4 * px, px)
end

-- look: an entry of grid.LOOK. fraction: how full the timer line is (0-1).
function grid.paint(b, look, label, r, g, bl, side, fraction)
    b.back:SetColorTexture(look.back[1], look.back[2], look.back[3], look.back[4])
    for _, edge in ipairs(b.edges) do
        edge:SetColorTexture(look.edge[1], look.edge[2], look.edge[3], 1)
    end
    b.label:SetText(label or "")
    b.label:SetTextColor(r, g, bl, look.text)
    b.side:SetText(side or "")
    b.side:SetTextColor(1, 1, 1, look.text)
    b.mark:SetShown(look.mark and not side and true or false)

    local width = b:GetWidth()
    if look.bar and fraction and fraction > 0 and width and width > 0 then
        b.bar:SetColorTexture(look.bar[1], look.bar[2], look.bar[3], 1)
        b.bar:SetWidth(math.max(grid.px, (width - 2 * grid.px) * math.min(1, fraction)))
        b.bar:Show()
    else
        b.bar:Hide()
    end
end

-- Secure attributes: written only when they change, out of combat only.
function grid.set(b, key, value)
    if b:GetAttribute(key) ~= value then b:SetAttribute(key, value) end
end
