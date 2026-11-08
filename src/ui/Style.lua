local _, ns = ...

-- Flat, dark look shared by every frame. No templates or libraries.

ns.UI = {}
local UI = ns.UI

UI.FONT = STANDARD_TEXT_FONT
UI.BG = { 0.06, 0.07, 0.09, 0.88 }
UI.EDGE = { 0, 0, 0, 1 }

function UI.Solid(parent, layer, c, sub)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub)
    t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    return t
end

-- Fills the frame and draws a 1px border around it.
function UI.Skin(frame, bg, edge)
    bg, edge = bg or UI.BG, edge or UI.EDGE
    local fill = UI.Solid(frame, "BACKGROUND", bg)
    fill:SetAllPoints()
    frame.skinFill = fill
    local edges = {}
    for i = 1, 4 do edges[i] = UI.Solid(frame, "BORDER", edge) end
    edges[1]:SetPoint("TOPLEFT"); edges[1]:SetPoint("TOPRIGHT"); edges[1]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT"); edges[2]:SetPoint("BOTTOMRIGHT"); edges[2]:SetHeight(1)
    edges[3]:SetPoint("TOPLEFT"); edges[3]:SetPoint("BOTTOMLEFT"); edges[3]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT"); edges[4]:SetPoint("BOTTOMRIGHT"); edges[4]:SetWidth(1)
    frame.skinEdges = edges
end

function UI.SetEdgeColor(frame, r, g, b, a)
    for _, e in ipairs(frame.skinEdges or {}) do e:SetColorTexture(r, g, b, a or 1) end
end

function UI.Text(parent, size, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFont(UI.FONT, size or 11, "OUTLINE")
    fs:SetShadowOffset(0, 0)
    fs:SetWordWrap(false)
    return fs
end

-- Pulsing gold border, built from four edge textures. Runs in combat
-- because textures are not protected.
function UI.AddGlow(frame, thickness)
    thickness = thickness or 2
    local holder = CreateFrame("Frame", nil, frame)
    holder:SetPoint("TOPLEFT", -thickness, thickness)
    holder:SetPoint("BOTTOMRIGHT", thickness, -thickness)
    holder:SetFrameLevel(frame:GetFrameLevel() + 3)
    local c = ns.COLORS.glow
    local e = {}
    for i = 1, 4 do
        e[i] = holder:CreateTexture(nil, "OVERLAY")
        e[i]:SetColorTexture(c[1], c[2], c[3], 1)
        e[i]:SetBlendMode("ADD")
    end
    e[1]:SetPoint("TOPLEFT"); e[1]:SetPoint("TOPRIGHT"); e[1]:SetHeight(thickness)
    e[2]:SetPoint("BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT"); e[2]:SetHeight(thickness)
    e[3]:SetPoint("TOPLEFT"); e[3]:SetPoint("BOTTOMLEFT"); e[3]:SetWidth(thickness)
    e[4]:SetPoint("TOPRIGHT"); e[4]:SetPoint("BOTTOMRIGHT"); e[4]:SetWidth(thickness)

    local anim = holder:CreateAnimationGroup()
    anim:SetLooping("BOUNCE")
    local fade = anim:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0.25)
    fade:SetDuration(0.6)
    fade:SetSmoothing("IN_OUT")
    holder:Hide()
    holder.anim = anim
    frame.glow = holder
end

function UI.SetGlow(frame, on)
    local g = frame.glow
    if not g then return end
    on = on and ns.db.glow
    if on and not g:IsShown() then
        g:Show(); g.anim:Play()
    elseif not on and g:IsShown() then
        g.anim:Stop(); g:Hide()
    end
end

-- Small flat button with a texture or a text label.
function UI.HeaderButton(parent, texture, label, size)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size or 16, size or 16)
    if texture then
        local t = b:CreateTexture(nil, "ARTWORK")
        t:SetAllPoints()
        t:SetTexture(texture)
        b.icon = t
    end
    if label then
        local fs = UI.Text(b, 10)
        fs:SetPoint("CENTER")
        fs:SetText(label)
        b.label = fs
        b:SetWidth(math.max(size or 16, fs:GetStringWidth() + 8))
    end
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.12)
    return b
end

function UI.ClassColor(class)
    if class == "PET" then return 0.55, 0.80, 0.55 end
    local c = (C_ClassColor and C_ClassColor.GetClassColor(class)) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
    if c then return c.r, c.g, c.b end
    return 0.7, 0.7, 0.7
end

-- Clicks on secure buttons fire on key down or key up depending on the
-- ActionButtonUseKeyDown CVar; register both and react to the one that casts.
function UI.RegisterSecureClicks(btn)
    btn:RegisterForClicks("AnyUp", "AnyDown")
end

function UI.IsCastingClick(down)
    local useDown = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")
    return (down and useDown) or (not down and not useDown)
end
