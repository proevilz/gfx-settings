# GFXSettings

Adjust twelve graphics settings in WoW Forever, including grass density, draw distance, weather, reflections and shadow edges. Type `/gfx` or `/graphicscontrols` to open GFX Settings. Drag the title to move the panel or press Escape to close it.

Sliders apply changes immediately. For a precise value, type it in the number field and press Enter. Hover over a slider for a description and its console variable name. A faint tick marks the game default when the client reports a value within the slider range.

**Refresh** reads the current settings and discards pending text edits. **Restore originals** returns settings to their values before your first change through the addon. These originals persist across reloads. Restore them before uninstalling if you want to undo your changes.

The client determines which values it supports. The panel disables unavailable settings and reports values the client rejects or clamps. Make changes outside combat. Game presets and raid graphics settings can override individual values.

## Installation

Extract both `GFXSettings` and `ForeverGraphics` from the ZIP. Place these folders inside your WoW Forever installation’s `_forever_/Interface/AddOns/` directory. Restart the game if the addon does not appear in the AddOns list.

Download the installable `GFXSettings-<version>.zip` from the [latest release](https://github.com/proevilz/gfx-settings/releases/latest). Keep the folder named `GFXSettings` when installing. GitHub's automatic source archives are not the installable addon ZIP.

Made by [@proevilz](https://x.com/proevilz). Click the handle in the panel to copy the profile URL.

## Development

Run `lua tests/gfx-settings.lua` from this repository root. The tests cover validation, saved originals, client clamping, panel initialization and the profile link; they do not replace in-game visual checks.

## Publishing

`main` is the development branch. Only pushes to `release` publish GitHub releases.

1. Finish and test changes on `main`.
2. Increase `## Version` in `GFXSettings.toc` to a new `major.minor.patch` version and commit it.
3. Merge `main` into `release` and push `release` (or merge a pull request targeting `release`).

The workflow runs the Lua tests, builds and verifies a ZIP with a top-level `GFXSettings` folder, then creates a `v<version>` tag and GitHub release at that exact commit. Existing releases are never overwritten: use a new TOC version for every release. Manual runs are allowed on `release` only. Return to `main` for further development.

No CurseForge upload is configured.

## 1.0.0

Initial public release. Includes twelve graphics controls, saved original settings, default-value markers and the author profile link.
