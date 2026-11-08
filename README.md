# Wizard Buff

A mage buff helper for **World of Warcraft: Forever**. One button keeps your armor and the group's Intellect up. A click-to-cast grid shows who needs what, and raid groups are split between mages automatically, the way PallyPower does it for paladins.

No libraries, no setup: install, log in on a mage, and it works.

## The icon bar

```
 [Armor] [Int] [Brill] [Shield]
   52m  3 need   12     ready
 ┌──────────────────────────────────┐
 │ ▓▓▓▓Thrall ▓▓▓Jaina ░░Uther      │   ← group grid (in a group)
 └──────────────────────────────────┘
   Your groups: 1 3 5 · mages          ← raids only
```

- **Armor**: your armor, with a sweep showing the time left. Glows when it's missing or about to expire.
- **Intellect**: casts on the next person in your groups who needs it (you first, then players, then pets). The caption says how many need it. Right-click casts Arcane Brilliance.
- **Brilliance**: glows when enough people in range need Intellect (3 by default) and you carry Arcane Powder. The number on it is your powder count.
- **Shield**: Ice Barrier or Mana Shield. Shows its cooldown and glows when your health is low.
- **Grid**: one cell per group member. The class-coloured fill is the Intellect time left; an empty dark-red cell needs a buff. Faded cells are out of range or covered by another mage. Left-click = Intellect (right rank for their level), right-click = Brilliance, Shift = Dampen Magic, Ctrl = Amplify Magic (changeable).

Hover anything for a tooltip. To move it, unlock (`/wbuff lock` or settings), drag the highlighted box, then right-click it to lock.

## Working with other mages

Every mage running Wizard Buff finds the others automatically. Raid groups are split evenly between them, the same way on every client, so nobody double-buffs. Your grid highlights only your groups, and the Intellect icon only targets them.

Click **Your groups** under the grid (or `/wbuff mages`) to change the split. Click a box to give that group to that mage, or click **Auto split** to go back to even. Changes reach every mage with the addon. Mages without the addon show up too, so you can hand a group to someone who buffs by hand.

## How Forever's addon rules affect it

Forever runs the modern client with Midnight's addon restrictions:

- **Buffs on other players can't be read in combat.** The grid keeps the last reading and counts down from it. Your own casts update it right away, and everything is re-read the moment combat ends.
- **Clicks still work in combat.** Grid cells and icons are set up out of combat and stay clickable during a fight. They keep their last target until combat ends.
- Out of combat, buffs are re-read every second.
- **Addon messages pause during boss encounters.** Assignment changes are queued and sent afterwards.

## Commands

`/wbuff` or `/wizardbuff`

| Command | Action |
|---|---|
| *(none)* | Show or hide |
| `config` | Open settings |
| `lock` | Unlock to move, lock again |
| `mages` | Raid assignments |
| `report` | Post who is missing Intellect to group chat |
| `reset` | Move it back to the default spot |
| `debug` | Print what the game reports about buffs (include this in bug reports) |

## Key bindings and macros

**Options → Keybindings → AddOns → Wizard Buff**: *Cast whatever is needed next* (armor, then Brilliance when worth it, then Intellect), *Arcane Intellect*, *Arcane Brilliance*, *Armor*, *Shield*.

Or macros:

```
/click WizardBuffBuffButton LeftButton
/click WizardBuffIntButton LeftButton
/click WizardBuffBrillButton LeftButton
/click WizardBuffArmorButton LeftButton
/click WizardBuffShieldButton LeftButton
```

## Settings

**Esc → Options → AddOns → Wizard Buff**, `/wbuff config`, or right-click the minimap button.

- **General**: show, show when solo, lock, include pets.
- **Buffs**: armor (Auto picks Mage Armor in instances and Ice Armor elsewhere), Brilliance on/off and how many people must need it, rebuff window, shield spell and health alert.
- **Grid clicks**: Shift and Ctrl spells.
- **Look**: icon size, rows or columns, cell size, scale, opacity, combat opacity.
- **Alerts**: glow, sound, ready-check reminder.
- **Coordination**: share work with other mages, minimap button.

Wizard Buff also appears in the minimap addon compartment.

## Install

From [CurseForge](https://www.curseforge.com/wow/addons/wizard-buff), or copy the `WizardBuff` folder into `World of Warcraft\_forever_\Interface\AddOns\`.

## Development

- Interface `16001` (WoW Forever). No embedded libraries.
- Source layout: `src/core` (events, settings storage, update loop, slash), `src/spells` (spell catalog, aura reads), `src/roster`, `src/sync` (mage coordination), `src/buffs` (what to cast next), `src/ui`.
- Pushing to `master` auto-tags the next patch version, which triggers [BigWigsMods/packager](https://github.com/BigWigsMods/packager) to build and release.

## License

All Rights Reserved © kWAYTV
