# Wizard Buff

Lightweight mage buff HUD for WoW Classic (TBC Anniversary). One-click buffing for armor, Intellect, Arcane Brilliance, and emergency shields.

## Features

- **Auto Buff** (left icon) — cascading priority: armor → self Intellect → group → pets → shield
- **Group Buff** (right icon) — Intellect / Brilliance on next unbuffed member or pet; falls back to friendly target
- **Buff grid** — per-player/pet cells grouped by class, click any to buff (Decursive-style micro-frames)
- **Live timers** — countdown overlaid on icons, shifts orange when low
- **Glow alerts** — pulsing gold border when a buff needs casting
- **Sound alerts** — distinct sounds for self vs group (optional)
- **Combat-aware** — fades in combat, skips warnings when dead, prevents taint
- **Minimap icon** — LibDataBroker / LibDBIcon
- **Keybinds** — standard Key Bindings menu
- **Profiles** — AceDB with import/export
- **Drag handle** — small corner button above the HUD, glows on hover (Alt+drag to move, right-click config, shift+click lock)

## Install

From [CurseForge](https://www.curseforge.com/wow/addons/wizard-buff), or copy `WizardBuff` into `Interface\AddOns\`.

## Commands

`/wbuff` or `/wizardbuff`:

| Command | Action |
|---------|--------|
| `toggle` | Enable / disable |
| `config` | Open settings |
| `lock` | Lock / unlock position |
| `grid` | Toggle buff grid |
| `armor` | Toggle armor |
| `int` | Toggle Intellect |
| `brilliance` | Toggle Brilliance preference |
| `pets` | Toggle pet buffing |
| `bubble` | Toggle emergency shield |
| `report` | Buff status to chat |
| `macro` | Show `/click` syntax |

## Macros

```
/click WizardBuffAutoBuffButton
/click WizardBuffBrillianceButton
```

## Settings

`/wbuff config` or right-click the drag handle.

**General** — toggles, grid, timers, glow, sound, minimap icon
**Appearance** — scale, opacity, combat fade, position reset
**Buffs** — armor type, Intellect, Brilliance, pets, shield threshold, refresh guard
**Profiles** — switch, copy, delete, import/export

## Packaging

Automated via GitHub Actions:

1. Push to `master` → auto-tags next patch version
2. Tag triggers [BigWigsMods/packager](https://github.com/BigWigsMods/packager) → Release on CurseForge + GitHub

`@project-version@` in `.toc` is replaced with the tag at build time.

## Libraries

Fetched at build time via `.pkgmeta`:

Ace3 (AceAddon, AceConfig, AceConfigDialog, AceConsole, AceDB, AceDBOptions, AceEvent, AceGUI, AceLocale) · LibStub · CallbackHandler · LibDataBroker-1.1 · LibDBIcon-1.0

## Interface

`20505` — TBC Anniversary (2025/2026)

## License

All Rights Reserved © kWAYTV
