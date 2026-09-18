local _, ns = ...

ns.ICON_SIZE    = 28
ns.ICON_PAD     = 0
ns.ICON_GAP     = 2
ns.GRIP_W       = 8
ns.STATUS_W     = 36

ns.GRID_CELL_W  = 20
ns.GRID_CELL_H  = 20
ns.GRID_BORDER  = 1
ns.GRID_GAP     = 1
ns.GRID_PER_ROW = 5

ns.HANDLE_H      = 0
ns.AUTO_LOCK_SEC = 30

ns.GLOW_R, ns.GLOW_G, ns.GLOW_B = 1, 0.82, 0.3
ns.GLOW_THICK = 2

ns.SOUND_SELF     = "Sound\\Interface\\AlarmClockWarning3.ogg"
ns.SOUND_GROUP    = "Sound\\Interface\\iQuestUpdate.ogg"
ns.SOUND_INTERVAL = 15

ns.REFRESH_THRESHOLD = 0.33

ns.STATUS_COLORS = {
    good    = { 0.4,  1,    0.4  },
    warning = { 1,    0.65, 0.3  },
    bad     = { 1,    0.4,  0.4  },
    oor     = { 1,    0.5,  0.2  },
    neutral = { 0.6,  0.6,  0.6  },
}

function ns.SetSolidColor(tex, r, g, b, a)
    if tex.SetColorTexture then
        tex:SetColorTexture(r, g, b, a)
    else
        tex:SetTexture(r, g, b, a)
    end
end

function ns.CropIcon(tex)
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
end

function ns.ApplyHudScale()
    if ns.mainFrame then
        ns.mainFrame:SetScale((ns.db and ns.db.hudScale) or 1)
    end
end

function ns.ApplyHudFade()
    local d, mf = ns.db, ns.mainFrame
    if not mf or not d or not mf:IsShown() then return end
    local a = d.hudAlphaHover or 1
    if not ns._hudMouseOver then
        a = d.hudAlphaIdle or 0.75
        if d.hideHudInCombat and InCombatLockdown() then
            a = math.min(a, 0.12)
        end
    end
    mf:SetAlpha(a)
end

function ns.ScheduleHudLeaveCheck(mf)
    C_Timer.After(0.08, function()
        if mf and mf:IsMouseOver() then return end
        ns._hudMouseOver = false
        ns.ApplyHudFade()
    end)
end
