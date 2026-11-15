# Wizard Buff

Two icons for mages in **World of Warcraft: Forever**. One tells you who is missing Arcane Intellect, the other whether your armor is up. Click the icon to fix it.

No libraries, no settings screen. Install, log in on a mage, done.

## The two icons

**Intellect**

- A number in the corner is how many people near you are missing Intellect, and lines run around the icon while there is someone to buff.
- **Left-click** buffs the next person: you first, then your own group, then the rest of the raid. It picks the highest rank that works on their level (a rank lands on targets up to ten levels below the level you learned it at). When three or more people need it and you can cast Arcane Brilliance, it casts that instead; on Forever it covers the whole raid.
- **Right-click** always casts Arcane Brilliance.
- When everyone has it, the time until the first one runs out is shown under the icon. A click then refreshes that person.
- Any rank counts, as does Brilliance or another mage's Intellect.
- Skipped: warriors and rogues, pets, dead and offline players, and anyone out of range. The game reports no buffs for people it can't see, so they are listed in the tooltip as out of range instead of counted as missing.

**Armor**

- Lines run around it when no armor is up; otherwise the time left is shown under it.
- **Left-click** casts the armor you used last. **Right-click** switches to another armor you know.

Hover an icon to see names and what a click will do. **Alt-drag** an icon to move the pair.

## Key binding

**Options → Keybindings → AddOns → Wizard Buff → Cast the next buff that is needed**: armor if it's down, otherwise the next Intellect.

## Commands

| Command | Action |
|---|---|
| `/wb` | Show or hide |
| `/wb scale 1.2` | Resize |
| `/wb reset` | Back to the middle of the screen at normal size |
| `/wb debug` | Print what the game reports about buffs (include this in bug reports) |

`/wbuff` and `/wizardbuff` work too.

## In combat

Forever uses the modern client's addon rules:

- The game can hide buffs from addons during combat. When it does, the icons turn grey and keep their last reading until the fight ends. They never report a hidden buff as missing.
- The icons are also grey while you are dead or on a flight path.
- What a click casts is fixed when combat starts. The icons still work in a fight, on the target they had before it.

## Install

From [CurseForge](https://www.curseforge.com/wow/addons/wizard-buff), or copy the `WizardBuff` folder into `World of Warcraft\_forever_\Interface\AddOns\`.

## Development

- Interface `16001`. Everything is in `WizardBuff.lua`.
- Buffs are read with `C_UnitAuras.GetAuraDataBySpellName`, and only while `C_Secrets` says the spell is readable.
- Pushing to `master` auto-tags the next patch version, which triggers [BigWigsMods/packager](https://github.com/BigWigsMods/packager) to build and release.

## License

All Rights Reserved © kWAYTV
