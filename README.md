# Wizard Buff for World of Warcraft

Wizard Buff is a mage buff management addon for WoW Classic (TBC Anniversary). It provides a compact HUD with one-click buffing for armor, Intellect, Arcane Brilliance, emergency shields, and per-player grid cells — so you never miss a buff in dungeons or raids.

## Documentation

Type `/wbuff config` or right-click the drag handle to open the configuration panel.

`/wbuff` — [Slash commands](#slash-commands) · [Macros](#macros) · [Key Bindings](#key-bindings) · [Settings](#settings)

## Key Benefits

### Works out of the box

Wizard Buff detects your known spells, highest ranks, and reagent supply automatically. Install it, log in, and you're ready — no setup required.

### One-click smart buffing

- **Auto Buff** (left icon) — cascading priority: armor → self Intellect → next unbuffed group member → pets.
- **Group Buff** (middle icon) — Intellect or Arcane Brilliance on the next unbuffed member or pet; falls back to your friendly target if everyone is covered.
- **Self** (right icon) — Ice Barrier or Mana Shield on yourself when your HP drops below a configurable threshold.
- **Mouse wheel** on any icon button cycles between spell modes (e.g. lock to Frost Armor, force single-target Intellect, pick Ice Barrier vs Mana Shield).
- The addon picks the correct spell rank for each target's level, so you never waste mana on low-level members.

### Buff grid (Decursive-style micro-frames)

Per-player click-to-cast cells grouped by class. Each cell shows the player's initial colored by class, lights up when they need Intellect, dims when out of range, and goes grey when dead or offline. Grid column count is configurable.

### Don't waste time

- **Refresh guard** prevents re-casting buffs that still have significant duration remaining.
- **Reagent counter** shows your Arcane Powder supply on the HUD and minimap tooltip so you never run dry mid-raid.
- **Recently-buffed tracking** suppresses targets you just cast on, avoiding double-casts while the server catches up.
- Dead, offline, and out-of-range members are visually distinguished so you focus on targets you can actually buff.
- **Out-of-range feedback** — icon buttons desaturate and dim when the next target is too far, so you know to move closer before clicking.
- **Rich tooltips** — hover any icon button to see the queued spell, target name, status, and current mode.

### React faster

- **Glow alerts** — pulsing gold border on icons when a buff needs casting.
- **Sound alerts** — distinct sounds for self buffs vs group buffs (optional, with test buttons in settings).
- **Live timers** — countdown overlaid on buff icons, shifts orange when running low.

### Integration in any interface

- **Minimap icon** via LibDataBroker / LibDBIcon — left-click toggle, right-click settings, shift+click lock.
- **Drag handle** above the HUD for repositioning (auto-locks after 30 seconds).
- **Key Bindings** through the standard WoW Key Bindings menu.
- **Combat-aware** — fades during combat to avoid distraction, prevents taint, queues updates until combat ends.
- Fully adjustable scale, idle/hover opacity, and combat fade.

### Profiles

Full AceDB profile system: create, switch, copy, delete, reset to defaults, and import/export profiles as text strings to share settings between characters or with other players.

## Slash Commands

`/wbuff` or `/wizardbuff`:

| Command | Action |
|---------|--------|
| *(no argument)* | Enable / disable the addon |
| `config` | Open settings panel |
| `lock` | Lock / unlock HUD position |
| `grid` | Toggle the buff grid |
| `armor` | Toggle armor buffing |
| `int` | Toggle Intellect buffing |
| `brilliance` | Toggle Arcane Brilliance preference |
| `pets` | Toggle pet buffing |
| `bubble` | Toggle emergency shield |
| `report` | Print buff status to party/raid chat |
| `macro` | Show `/click` macro syntax |

## Macros

Bind these to keys or toolbar slots for one-press buffing:

```
/click WizardBuffAutoBuffButton
/click WizardBuffBrillianceButton
/click WizardBuffShieldButton
```

## Key Bindings

Open **Game Menu → Key Bindings → Addons → Wizard Buff** to bind:

- **Auto Buff** — armor, intellect, pets cascade
- **Group Buff** — Intellect / Arcane Brilliance on next target
- **Self** — Ice Barrier / Mana Shield

## Settings

Four tabs accessible via `/wbuff config` or right-clicking the drag handle:

**General** — core toggle, solo mode, lock, buff timers, glow, sound alerts, buff grid, grid columns, drag handle, minimap icon.

**Appearance** — HUD scale, idle/hover opacity, combat fade, position reset.

**Buffs** — armor type selection (Auto / Ice / Mage / Frost), emergency shield type and HP threshold, Intellect toggle, Arcane Brilliance preference, pet buffing, refresh guard duration.

**Profiles** — switch, create, copy, delete, reset, import/export.

## Install

Download from [CurseForge](https://www.curseforge.com/wow/addons/wizard-buff), or copy the `WizardBuff` folder into your `Interface\AddOns\` directory.

## Interface Version

`20505` — TBC Anniversary (2025/2026)

## Libraries

Bundled at build time via `.pkgmeta`:

Ace3 (AceAddon, AceConfig, AceConfigDialog, AceConsole, AceDB, AceDBOptions, AceEvent, AceGUI, AceLocale) · LibStub · CallbackHandler · LibDataBroker-1.1 · LibDBIcon-1.0

## Packaging

Automated via GitHub Actions. Pushing to `master` auto-tags the next patch version, which triggers [BigWigsMods/packager](https://github.com/BigWigsMods/packager) to build and release on CurseForge and GitHub. The `@project-version@` token in the `.toc` is replaced with the tag at build time.

## License

All Rights Reserved © kWAYTV

For suggestions, feature requests, or bug reports use the [CurseForge project page](https://www.curseforge.com/wow/addons/wizard-buff) or the GitHub issue tracker.
