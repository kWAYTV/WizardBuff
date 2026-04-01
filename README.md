# Wizard Buff

Mage group-buff HUD for Intellect, armor, and shields (Ice Barrier / Mana Shield).

## Install

- Copy the `WizardBuff` folder into `World of Warcraft\_<flavor>_\Interface\AddOns\`.
- **Do not** add `Bindings.xml` to the `.toc` (the client loads it automatically).

## Development / packaging

- `.pkgmeta` defines external libraries for the CurseForge/WoWUp packager.
- If you clone without vendored `Libs/`, run your packager or copy the `Libs/` tree from another Ace3 addon (e.g. Decursive).

## Slash

- `/wb` and `/wizardbuff` — `toggle`, `config`, `lock`, `rows`, `armor`, `bubble`, `int`, `brilliance`, `pets`.

## Saved variables

- `WizardBuffDB` (AceDB profiles).
- Optional one-time migration from legacy `MagePowerDB` on first load.

## Interface version

- `20505` (Anniversary). Bump `## Interface` in `WizardBuff.toc` when targeting a different client.
