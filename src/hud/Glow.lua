local _, ns = ...

function ns.CreateGlow(btn)
    local edges = {}
    for i = 1, 4 do
        local e = btn:CreateTexture(nil, "OVERLAY", nil, 2)
        e:SetColorTexture(ns.GLOW_R, ns.GLOW_G, ns.GLOW_B, 1)
        e:SetBlendMode("ADD")
        e:SetAlpha(0)
        e:Hide()
        edges[i] = e
    end
    local top, bot, left, right = edges[1], edges[2], edges[3], edges[4]
    top:SetPoint("TOPLEFT", btn, -ns.GLOW_THICK, ns.GLOW_THICK)
    top:SetPoint("TOPRIGHT", btn, ns.GLOW_THICK, ns.GLOW_THICK)
    top:SetHeight(ns.GLOW_THICK)
    bot:SetPoint("BOTTOMLEFT", btn, -ns.GLOW_THICK, -ns.GLOW_THICK)
    bot:SetPoint("BOTTOMRIGHT", btn, ns.GLOW_THICK, -ns.GLOW_THICK)
    bot:SetHeight(ns.GLOW_THICK)
    left:SetPoint("TOPLEFT", top, "BOTTOMLEFT")
    left:SetPoint("BOTTOMLEFT", bot, "TOPLEFT")
    left:SetWidth(ns.GLOW_THICK)
    right:SetPoint("TOPRIGHT", top, "BOTTOMRIGHT")
    right:SetPoint("BOTTOMRIGHT", bot, "TOPRIGHT")
    right:SetWidth(ns.GLOW_THICK)
    btn.glowEdges = edges
    btn._glowPhase, btn._glowing = 0, false
end

function ns.InitGlowTicker()
    if ns._glowFrame then return end
    local f = CreateFrame("Frame")
    f._glowButtons = {}
    f:SetScript("OnUpdate", function(self, elapsed)
        for _, btn in ipairs(self._glowButtons) do
            if btn._glowing and btn.glowEdges then
                btn._glowPhase = (btn._glowPhase or 0) + elapsed * 2.5
                local a = 0.5 + 0.5 * (0.5 + 0.5 * math.sin(btn._glowPhase))
                for _, e in ipairs(btn.glowEdges) do e:SetAlpha(a) end
            end
        end
    end)
    f:Hide()
    ns._glowFrame = f
end

function ns.RegisterGlowButton(btn)
    ns.InitGlowTicker()
    ns._glowFrame._glowButtons[#ns._glowFrame._glowButtons + 1] = btn
end

function ns.SetButtonGlow(btn, on)
    if not btn or not btn.glowEdges then return end
    if not ns.db or not ns.db.showGlow then on = false end
    btn._glowing = on
    if on then
        for _, e in ipairs(btn.glowEdges) do e:Show() end
        if ns._glowFrame then ns._glowFrame:Show() end
    else
        for _, e in ipairs(btn.glowEdges) do e:SetAlpha(0); e:Hide() end
        btn._glowPhase = 0
    end
end
