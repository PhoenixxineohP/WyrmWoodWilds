# Testing checklist

Testing happens in the real game. Close Dragonwilds before installing or
toggling mods; RuneSchema reads everything at startup.

## 0. Before the first launch

1. Back up the world:
   ```bash
   SAVE="$HOME/.steam/steam/steamapps/compatdata/1374490/pfx/drive_c/users/steamuser/AppData/Local/RSDragonwilds/Saved/SaveGames"
   cp -a "$SAVE/Elzwylds.sav" "$SAVE/Elzwylds.sav.wyrmwood-backup"
   ```
   (On this machine the save is also at the path under
   `/media/Games/SteamLibrary/steamapps/compatdata/1374490/...`.)
2. `python3 tools/validate.py`
3. `bash tools/install.sh`
4. Start the game through Steam and wait for the main menu.
5. Check the logs:
   - `RSDragonwilds/Binaries/Win64/ue4ss/UE4SS.log` — UE4SS injected, RuneSchema loaded.
   - `.../ue4ss/Mods/RuneSchema/RuneSchema.log` — each `WW_*` mod applied, no rejected fields.

If RuneSchema reports a rejected field or missing class, the mod stays off and
the rest of the pack is unaffected. Fix the field name in the repo, re-sync,
restart.

## 1. Carry weight

- Open the inventory; the weight limit should read about 4000.
- Fill past the old 400 limit; movement should not slow until ~4000.

If the HUD still shows 400, another player rule is overriding it (the last
matching rule wins) — move `WW_CarryWeight` later in load order.

## 2. Storage

- Place a fresh crate/small chest/chest/iron chest.
- Check slot count and that sorting/fill-stacks works.
- Check an existing container in the world (its component default may have been
  serialized; report if it does not change).
- Move items out of extra slots before disabling this mod.

## 3. Spell cooldowns

- Rocksplosion: cooldown should be 10 s.
- Humidify/Compost: 15 s.
- Check a long spell (Divine Rock 300 s, Home Teleport 300 s).

If all spells are off by the same factor, the world setting
`Spell Cooldown Scale` is not 1.0.

## 4–7. Resource respawns

- Harvest a fishing node, a rune essence ground node, and an anima vent.
- Note the in-game time when they return. The pack targets 6–12 in-game hours
  for the tuned rows.
- Nodes may also require distance from players/beds; move away and return.

If nothing changed, check the log for the row name and for a rejected
`RespawnTime` field (the row struct may be nested differently in a future build).

## 8. Building stability

- Build a tall/overhanging test structure; pieces should stay fully supported.
- Build a wall flush into a cliff; upper pieces should place.
- Confirm demolition/repair still work.

If the game becomes unstable, set the losses to 0.1 instead of 0.0 in
`WW_BuildingStability/raw/10-stability.jsonc`.

## 9. Farm plots on floors

- Build a floor/second storey, place a planter on it.
- Check that planters still refuse mid-air placement.
- Test the Umbral variant if you have it (`FarmingPlotProfileUmbral...` may need
  its own row — check the log).

## 10. Build height

- Try placing a piece well above the vanilla limit.
- If placement behaves strangely (e.g. pieces snap to the sky), lower
  `MaxHeightModifier` in `WW_BuildHeight/blueprints/10-height.jsonc` and note the
  value that works.

## Rollback

- Disable one feature: `./tools/toggle.sh WW_BuildHeight off` + restart.
- Disable everything: set all lines in `features.conf` to `off` and
  `./tools/sync-mods.sh`.
- Remove the loader: delete `dwmapi.dll` and `ue4ss/` from
  `Binaries/Win64`, or restore `.wyrmwood-backups/<timestamp>/`.
- Restore the world from the save backup if needed.
