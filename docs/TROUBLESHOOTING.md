# Troubleshooting (Linux / Proton)

## UE4SS is not loading at all

Symptom: no `ue4ss/UE4SS.log`, or the game starts unmodded.

Cause: Wine prefers its built-in `dwmapi` over the UE4SS proxy.

Fix (done by `tools/install.sh` when it can find the prefix):

```bash
WINEPREFIX="$HOME/.steam/steam/steamapps/compatdata/1374490/pfx" \
  wine reg add 'HKCU\Software\Wine\DllOverrides' /v dwmapi /d 'native,builtin' /f
```

Or add to the game's Steam launch options:

```
WINEDLLOVERRIDES="dwmapi.dll=n,b" %command%
```

## `main.dll` fails with `0x45a` / "DLL initialization failed"

This is the documented UPX issue: the normal RuneSchema package ships
UPX-compressed DLLs and Wine cannot load them.

`tools/install.sh` runs `tools/unpack-dlls.sh` automatically. Manually:

```bash
bash tools/unpack-dlls.sh \
  "/path/to/RSDragonwilds/RSDragonwilds/Binaries/Win64/ue4ss/Mods/RuneSchema/dlls"
```

Verify:

```bash
strings .../RuneSchema/dlls/main.dll | grep UPX   # should print nothing
```

## Helpy desktop launch failed (`redirected child path`)

Benign on Linux (the game path is a `Z:` drive mapping). Helpy is optional; the
data mods and Mod Menu adapter do not need the desktop app. It only affects the
optional desktop UI.

## Where the logs are

```
RSDragonwilds/Binaries/Win64/ue4ss/UE4SS.log
RSDragonwilds/Binaries/Win64/ue4ss/Mods/RuneSchema/RuneSchema.log
```

After a successful start, `RuneSchema.log` contains:

```
[summary] blueprints | loaded=8 | updated=8 | errors=0     <- storage
[summary] assets     | loaded=26 | updated=26 | errors=0   <- spell cooldowns
[summary] blueprints | loaded=1 | updated=1 | errors=0     <- build height
```

The players (carry weight) and raw (respawn/stability/placement) loaders run
when a world/player loads, so their summaries appear after you enter the world.

## A mod reports a rejected field

The field name changed in a game update. Open `docs/RESEARCH.md`, re-read the
asset with the dumper, update the JSONC, run `bash tools/sync-mods.sh`, restart.

## RuneSchema version / game update

Log header shows the game build (`++dominion+hotfix-...`) and RuneSchema version.
After a game update, re-run `bash tools/fetch-deps.sh` only if you intend to update
the loader; the data mods usually survive unless a row/class was renamed.
