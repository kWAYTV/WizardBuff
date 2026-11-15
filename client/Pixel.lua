local _, ns = ...

-- UI units are not screen pixels. A border sized "1" lands between pixels
-- and comes out thick on one side, blurry on the other. Everything drawn
-- here is sized in whole pixels instead.

local pixel = {}
ns.pixel = pixel

-- One screen pixel, in the frame's units.
function pixel.size(frame)
    local _, height = GetPhysicalScreenSize()
    local scale = frame:GetEffectiveScale()
    if not height or height <= 0 or not scale or scale <= 0 then return 1 end
    return 768 / height / scale
end

function pixel.sharp(texture)
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)
end
