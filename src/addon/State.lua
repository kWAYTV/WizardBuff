local _, ns = ...

BINDING_HEADER_WIZARDBUFF = "Wizard Buff"
_G["BINDING_NAME_CLICK WizardBuffAutoBuffButton:LeftButton"]   = "Auto Buff (armor, intellect, pets)"
_G["BINDING_NAME_CLICK WizardBuffBrillianceButton:LeftButton"] = "Group Buff (Int / Brilliance)"
_G["BINDING_NAME_CLICK WizardBuffShieldButton:LeftButton"]     = "Self (Ice Barrier / Mana Shield)"

ns.db               = nil
ns.isMage           = false
ns.roster           = {}
ns.mainFrame        = nil
ns.gridCells        = {}
ns.autoBuffButton   = nil
ns.brillianceButton = nil
ns.shieldButton     = nil
ns._hudMouseOver    = false
ns._selfMode        = 0
ns._groupMode       = 0
ns._shieldMode      = 0
ns._recentlyBuffed  = {}
