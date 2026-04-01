local _, ns = ...

---------------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------------
ns.ICON_SIZE    = 24
ns.ICON_PAD     = 2
ns.ICON_GAP     = 2

ns.GRID_CELL_W  = 20
ns.GRID_CELL_H  = 20
ns.GRID_BORDER  = 2
ns.GRID_GAP     = 2
ns.GRID_PER_ROW = 5

ns.UI_FRAME_W = ns.ICON_PAD + ns.ICON_SIZE * 3 + ns.ICON_GAP * 2 + ns.ICON_PAD
ns.UI_BAR_H   = ns.ICON_PAD + ns.ICON_SIZE + ns.ICON_PAD

ns.HANDLE_SIZE = 20

---------------------------------------------------------------------------
-- Glow
---------------------------------------------------------------------------
ns.GLOW_R     = 1
ns.GLOW_G     = 0.82
ns.GLOW_B     = 0.3
ns.GLOW_THICK = 2

---------------------------------------------------------------------------
-- Sound
---------------------------------------------------------------------------
ns.SOUND_SELF     = "Sound\\Interface\\AlarmClockWarning3.ogg"
ns.SOUND_GROUP    = "Sound\\Interface\\iQuestUpdate.ogg"
ns.SOUND_INTERVAL = 15

---------------------------------------------------------------------------
-- Lock
---------------------------------------------------------------------------
ns.AUTO_LOCK_SEC = 30

---------------------------------------------------------------------------
-- Icons (texture paths)
---------------------------------------------------------------------------
ns.ICON_PATHS = {
    addon      = "Interface\\AddOns\\WizardBuff\\Media\\icon",
    frostArmor = "Interface\\Icons\\Spell_Frost_FrostArmor02",
    iceArmor   = "Interface\\Icons\\Spell_Frost_FrostArmor02",
    mageArmor  = "Interface\\Icons\\Spell_MageArmor",
    int        = "Interface\\Icons\\Spell_Holy_ArcaneIntellect",
    brill      = "Interface\\Icons\\Spell_Holy_ArcaneIntellect",
    iceBarrier = "Interface\\Icons\\Spell_Ice_Lament",
    manaShield = "Interface\\Icons\\Spell_Shadow_DetectLesserInvisibility",
    notLearned = "Interface\\Icons\\INV_Misc_QuestionMark",
}

---------------------------------------------------------------------------
-- Bindings
---------------------------------------------------------------------------
BINDING_HEADER_WIZARDBUFF = "Wizard Buff"
_G["BINDING_NAME_CLICK WizardBuffAutoBuffButton:LeftButton"]   = "Auto Buff (armor, intellect, pets)"
_G["BINDING_NAME_CLICK WizardBuffBrillianceButton:LeftButton"] = "Group Buff (Int / Brilliance)"
_G["BINDING_NAME_CLICK WizardBuffShieldButton:LeftButton"]     = "Self (Ice Barrier / Mana Shield)"

---------------------------------------------------------------------------
-- Runtime state slots
---------------------------------------------------------------------------
ns.db              = nil
ns.isMage          = false
ns.roster          = {}
ns.mainFrame       = nil
ns.gridCells       = {}
ns.autoBuffButton  = nil
ns.brillianceButton = nil
ns.shieldButton    = nil
ns._hudMouseOver   = false
ns._selfMode       = 0
ns._groupMode      = 0
ns._shieldMode     = 0
