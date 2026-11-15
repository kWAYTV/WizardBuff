local _, ns = ...

-- Short bright lines running around an icon: the "pixel glow" WeakAuras and
-- Hekili use. Shown while a cast is needed.

local LINES, LAP = 8, 4  -- lines, seconds per lap

-- One stretch of the outline, from a to b on a single side. The outline is
-- measured clockwise from the top left corner.
local function stretch(glow, texture, a, b, w, h, thick)
    if b - a < 0.01 then return texture:Hide() end
    texture:ClearAllPoints()
    if a < w then
        texture:SetPoint("TOPLEFT", glow, "TOPLEFT", a, 0)
        texture:SetSize(b - a, thick)
    elseif a < w + h then
        texture:SetPoint("TOPRIGHT", glow, "TOPRIGHT", 0, w - a)
        texture:SetSize(thick, b - a)
    elseif a < 2 * w + h then
        texture:SetPoint("BOTTOMRIGHT", glow, "BOTTOMRIGHT", w + h - a, 0)
        texture:SetSize(b - a, thick)
    else
        texture:SetPoint("BOTTOMLEFT", glow, "BOTTOMLEFT", 0, a - 2 * w - h)
        texture:SetSize(thick, b - a)
    end
    texture:Show()
end

local function animate(glow, elapsed)
    glow.at = (glow.at + elapsed / LAP) % 1
    local w, h = glow:GetSize()
    local thick = 2 * ns.pixel.size(glow)
    local around = 2 * (w + h)
    local length = around / (LINES * 2)
    for i = 1, LINES do
        local a = ((i - 1) / LINES + glow.at) % 1 * around
        local b = a + length
        local corner = (a < w and w) or (a < w + h and w + h) or (a < 2 * w + h and 2 * w + h) or around
        stretch(glow, glow.parts[2 * i - 1], a, math.min(b, corner), w, h, thick)
        if b > corner then
            -- Bends round the corner: the rest goes on the next side.
            local from = corner % around
            stretch(glow, glow.parts[2 * i], from, from + b - corner, w, h, thick)
        else
            glow.parts[2 * i]:Hide()
        end
    end
end

function ns.icons.glow(parent)
    local glow = CreateFrame("Frame", nil, parent)
    glow:Hide()
    glow.parts, glow.at = {}, 0
    for i = 1, LINES * 2 do
        local texture = glow:CreateTexture(nil, "OVERLAY")
        texture:SetColorTexture(1, 0.85, 0.3, 1)
        ns.pixel.sharp(texture)
        glow.parts[i] = texture
    end
    glow:SetScript("OnUpdate", animate)
    return glow
end
