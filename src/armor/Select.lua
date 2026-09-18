local _, ns = ...

function ns.GetArmorSpell()
    local armorType = (ns.db and ns.db.armorType) or "auto"
    local ids = ns.SpellIDs
    if armorType == "frost" then return ns.GetHighestRankSpell(ids.FrostArmor) end
    if armorType == "ice"   then return ns.GetHighestRankSpell(ids.IceArmor) end
    if armorType == "mage"  then return ns.GetHighestRankSpell(ids.MageArmor) end
    local spell, id = ns.GetHighestRankSpell(ids.IceArmor)
    if spell then return spell, id end
    spell, id = ns.GetHighestRankSpell(ids.MageArmor)
    if spell then return spell, id end
    return ns.GetHighestRankSpell(ids.FrostArmor)
end

function ns.GetArmorSpellKey()
    local armorType = (ns.db and ns.db.armorType) or "auto"
    if armorType == "frost" then return "FrostArmor" end
    if armorType == "ice"   then return "IceArmor" end
    if armorType == "mage"  then return "MageArmor" end
    if ns.GetHighestRankSpell(ns.SpellIDs.IceArmor)   then return "IceArmor" end
    if ns.GetHighestRankSpell(ns.SpellIDs.MageArmor)  then return "MageArmor" end
    if ns.GetHighestRankSpell(ns.SpellIDs.FrostArmor) then return "FrostArmor" end
end
