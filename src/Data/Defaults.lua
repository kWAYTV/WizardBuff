local _, ns = ...

ns.REFRESH_THRESHOLD = 0.33

ns.defaults = {
    enabled            = true,
    showWhenSolo       = true,
    locked             = false,
    hideHudInCombat    = true,
    hudAlphaIdle       = 0.42,
    hudAlphaHover      = 0.95,
    hudScale           = 1.0,
    showHudNeedCount   = true,
    showTimers         = true,
    showGlow           = true,
    showSound          = false,
    showClassRows      = true,
    gridColumns        = 5,
    buffArmor          = true,
    armorType          = "auto",
    enableBubble       = true,
    bubbleType         = "auto",
    bubbleThreshold    = 50,
    buffIntellect      = true,
    useArcaneBrilliance = true,
    buffPets           = true,
    showDragHandle     = true,
    refreshFloorSec    = 120,
    keybind            = "",
    hudPos             = nil,
    minimap            = { hide = false },
    migratedFromMagePower = false,
}

ns.CLASS_ORDER = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "SHAMAN", "MAGE", "WARLOCK", "DRUID", "PET",
}

ns.CLASS_COLORS = {
    WARRIOR = { 0.78, 0.61, 0.43 },
    PALADIN = { 0.96, 0.55, 0.73 },
    HUNTER  = { 0.67, 0.83, 0.45 },
    ROGUE   = { 1.0,  0.96, 0.41 },
    PRIEST  = { 1.0,  1.0,  1.0  },
    SHAMAN  = { 0.0,  0.44, 0.87 },
    MAGE    = { 0.41, 0.80, 0.94 },
    WARLOCK = { 0.58, 0.51, 0.79 },
    DRUID   = { 1.0,  0.49, 0.04 },
    PET     = { 0.5,  0.8,  0.5  },
}
