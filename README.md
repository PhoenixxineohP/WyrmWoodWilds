# WyrmWoodWilds

A modular, toggleable QoL mod pack for **RuneScape: Dragonwilds** (UE 5.6.1),
built on [RuneSchema](https://github.com/gh0sted5456-us/RuneSchema) + UE4SS.

Every feature is its own RuneSchema mod folder, so it can be turned on or off
independently from `runeschema.txt` (or later from in-game Mod Menu controls)
without shipping cooked Unreal assets.

## What is in the pack (v0.1)

| Feature | Mod folder | Status |
| --- | --- | --- |
| Carry capacity x10 (400 → 4000) | `WW_CarryWeight` | ready |
| Larger storage containers | `WW_Storage` | ready |
| Spell cooldown tuning (Rocksplosion → 10s, long spells shortened) | `WW_SpellCooldowns` | ready |
| Faster fishing node respawns | `WW_RespawnFishing` | ready |
| Faster rune essence respawns | `WW_RespawnRuneEssence` | ready |
| Faster anima vent (mana) respawns | `WW_RespawnAnimaVents` | ready |
| Faster mineral node respawns | `WW_RespawnMinerals` | optional, off by default |
| Relaxed building stability | `WW_BuildingStability` | ready |
| Farm plots off the ground (build them on floors) | `WW_BuildPlacement` | ready |
| Higher build height | `WW_BuildHeight` | experimental |
| Raid pacing / raid pause | — | researched, phase 2 |
| Wider Humidify / Compost area | — | researched, phase 2 (needs Lua) |
| Level-scaled runecrafting yields | — | researched, phase 2 (needs runtime hook) |
| Per-item weight overrides | — | planned (data-only) |

See [`docs/RESEARCH.md`](docs/RESEARCH.md) for the exact assets, rows and values
this is based on, and [`docs/PLAN.md`](docs/PLAN.md) for the roadmap.

## Requirements

- RuneScape: Dragonwilds (Steam, UE 5.6.1)
- **UE4SS** `v3.0.1-1217` packaged for Dragonwilds
- **RuneSchema** `0.9.0.1` preview (2026-11-17)

Both are fetched by `tools/fetch-deps.sh` and installed by `tools/install.sh`.

> This repo lives on a `noexec` mount, so run the scripts with `bash tools/...`.
Nothing is vendored in this repo.

## Install

```bash
bash tools/fetch-deps.sh
GAME_DIR="/path/to/steamapps/common/RSDragonwilds" bash tools/install.sh
```

Default game path is the one on this machine:
`/media/Games/SteamLibrary/steamapps/common/RSDragonwilds`.

The installer:

1. backs up `dwmapi.dll`, `ue4ss/` and `RuneSchema/` into
   `<game>/.wyrmwood-backups/<timestamp>/`,
2. installs UE4SS into `RSDragonwilds/Binaries/Win64`,
3. installs RuneSchema into `.../ue4ss/Mods/RuneSchema`,
4. copies every `WW_*` mod into `.../RuneSchema/mods`,
5. writes `runeschema.txt` from [`features.conf`](features.conf).

Uninstall: remove `dwmapi.dll` and `ue4ss/` from `Binaries/Win64`, or restore
the backup folder created by the installer.

## Toggles

```bash
bash tools/toggle.sh list
bash tools/toggle.sh WW_Storage off
bash tools/toggle.sh WW_BuildingStability on
```

Toggles are written to `features.conf` and to the installed
`RuneSchema/mods/runeschema.txt`; restart the game after changing them.
Live numeric controls (sliders in game) are planned via RuneSchema's Mod Menu
integration once the data-only mods are verified.

## Safety

- Back up your world before testing (`Saved/SaveGames/*.sav`).
- Storage changes: move items out of extra slots before disabling or shrinking.
- World-affecting mods (stability, placement, raids) change shared world state;
  test on a copy first.
- This is a fan project. Not affiliated with Jagex.

## Credits

- RuneSchema by the RSDW Modding Community (MIT)
- UE4SS by the UE4SS team (MIT)
- Dragonwilds UE4SS packaging by MichaelRyan2319
