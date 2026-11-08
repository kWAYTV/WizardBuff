# Wizard Buff

A mage buff helper for **World of Warcraft: Forever**. One button keeps your armor and the group's Intellect up. A click-to-cast grid shows who needs what, and raid groups are split between mages automatically, the way PallyPower does it for paladins.

No libraries, no setup: install, log in on a mage, and it works.

## The HUD

```
┌ Wizard Buff ─────────── 3 need  12 powder  🔒 Mages ⚙ ┐
│ [Buff] [Shield]  Arcane Intellect > Thrall            │
│                  Your groups: 1, 3, 5                 │
│ 1 [Thral][Jaina][Uther][Sylva][Garro]                 │
│ 2 [Rexxa][Cairn][Varia][Magni][Tyran]                 │
│ P [Imp  ][Wolf ]                                      │
└───────────────────────────────────────────────────────┘
```

- **Buff**: casts the next thing you need, in this order: your armor, your own Intellect, the next player in your groups, then pets. When enough people need it (3 by default) and you carry Arcane Powder, it casts Arcane Brilliance instead. Right-click it to cast Brilliance directly.
- **Shield**: Ice Barrier or Mana Shield on yourself. Glows when your health drops below the alert threshold.
- **Grid**: one cell per group member, one row per raid group.
  - Bright cell with a gold pulse: needs Intellect and is yours to buff.
  - Faded: out of range, or covered by another mage.
  - Grey: dead or offline.
  - The thin bar along the bottom shows how much buff time is left and turns orange when it's time to rebuff.
- **Clicks on a cell**: left = Arcane Intellect (picks the right rank for the target's level), right = Arcane Brilliance, Shift = Dampen Magic, Ctrl = Amplify Magic. You can change Shift and Ctrl in settings.
- **Header**: drag to move, lock icon, **Mages** (raid assignments), gear (settings). It also shows how many of your people need Intellect and your Arcane Powder count.

Hover anything for a tooltip that says exactly what a click will do.

## Working with other mages

Every mage running Wizard Buff finds the others automatically. Raid groups are split evenly between them, the same way on every client, so nobody double-buffs. Your grid highlights only your groups, and your Buff button only targets them.

Open **Mages** in the header (or `/wbuff mages`) to change the split. Click a box to give that group to that mage, or click **Auto split** to go back to even. Changes reach every mage with the addon. Mages without the addon show up too, so you can hand a group to someone who buffs by hand.

## How Forever's addon rules affect it

Forever runs the modern client with Midnight's addon restrictions:

- **Buffs on other players can't be read in combat.** The grid keeps the last reading and counts down from it. Your own casts update it right away, and everything is re-read the moment combat ends.
- **Clicks still work in combat.** Grid cells and buttons are set up out of combat and stay clickable during a fight. The Buff button keeps its last target until combat ends.
- **Addon messages pause during boss encounters.** Assignment changes are queued and sent afterwards.

## Commands

`/wbuff` or `/wizardbuff`

| Command | Action |
|---|---|
| *(none)* | Show or hide the HUD |
| `config` | Open settings |
| `lock` | Lock or unlock the HUD |
| `mages` | Raid assignments |
| `report` | Post who is missing Intellect to group chat |
| `reset` | Move the HUD back to the center |

## Key bindings and macros

**Options → Keybindings → AddOns → Wizard Buff**: *Buff next target*, *Arcane Brilliance*, *Shield*.

Or macros:

```
/click WizardBuffBuffButton LeftButton
/click WizardBuffBuffButton RightButton
/click WizardBuffShieldButton LeftButton
```

## Settings

**Esc → Options → AddOns → Wizard Buff**, the gear icon, or right-click the header or minimap button.

- **General**: show the HUD, show when solo, lock, include pets.
- **Buffs**: armor (Auto picks Mage Armor in instances and Ice Armor elsewhere), Brilliance on/off and how many people must need it, rebuff window, shield spell and health alert.
- **Grid clicks**: Shift and Ctrl spells.
- **Look**: rows or columns, cell size, scale, opacity, combat opacity.
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
