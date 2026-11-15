local _, ns = ...

-- One icon: a secure button that casts on click. Square, cropped texture,
-- one-pixel black border, timer under it, count in the corner.

local icons = ns.icons
local SOON = 300  -- seconds left at which the timer turns yellow

function icons.button(name)
    local frame = icons.frame
    local b = CreateFrame("Button", name, frame, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    b.edges = {}
    for i = 1, 4 do
        local edge = b:CreateTexture(nil, "OVERLAY", nil, 7)
        edge:SetColorTexture(0, 0, 0, 1)
        ns.pixel.sharp(edge)
        b.edges[i] = edge
    end

    local hover = b:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.12)

    -- On a child frame so text and glow draw over the border.
    local top = CreateFrame("Frame", nil, b)
    top:SetAllPoints()
    b.text = top:CreateFontString(nil, "OVERLAY")
    b.text:SetPoint("TOP", b, "BOTTOM", 0, -2)
    b.count = top:CreateFontString(nil, "OVERLAY")
    b.count:SetPoint("BOTTOMRIGHT", -1, 2)
    b.glow = icons.glow(top)

    -- Alt-drag moves the pair; an Alt-click casts nothing.
    b:SetAttribute("alt-type1", "")
    b:SetAttribute("alt-type2", "")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function()
        if IsAltKeyDown() and not InCombatLockdown() then frame:StartMoving() end
    end)
    b:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        icons.savePosition()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    icons.all[#icons.all + 1] = b
    return b
end

function icons.fitBorder(b, px)
    local top, bottom, left, right = b.edges[1], b.edges[2], b.edges[3], b.edges[4]
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(px)
    bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(px)
    left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(px)
    right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(px)
    b.glow:SetPoint("TOPLEFT", b, "TOPLEFT", -px, px)
    b.glow:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", px, -px)
end

-- need: glowing. idle: greyed out. count: number in the corner. left: timer.
function icons.paint(b, spell, need, idle, count, left)
    b.icon:SetTexture(spell and C_Spell.GetSpellTexture(spell) or 134400)
    b.icon:SetDesaturated(idle and true or false)
    local shade = idle and 0.6 or 1
    b.icon:SetVertexColor(shade, shade, shade)
    b.count:SetText(count or "")
    b.text:SetText(ns.db.timers and icons.timeText(left) or "")
    if left and left < SOON then b.text:SetTextColor(1, 0.8, 0.2) else b.text:SetTextColor(1, 1, 1) end
    b.glow:SetShown((need and not idle) and true or false)
end

-- Secure attributes: only written when they change, out of combat only.
function icons.set(b, key, value)
    if b:GetAttribute(key) ~= value then b:SetAttribute(key, value) end
end
