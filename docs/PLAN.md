# Implementation plan

## Design rules

1. **One feature = one RuneSchema mod folder.** Every folder is independently
   toggled in `runeschema.txt` (and later via Mod Menu).
2. **Data-only first.** Prefer patching reflected fields / DataTable rows over
   pak overrides. No cooked assets, no UE install, survives game updates better.
3. **No global side effects when avoidable.** Patch specific spells, rows and
   classes; avoid shared base classes (e.g. don't touch
   `BP_Components_WorldItemInventory` globally).
4. **Test on a copied world.** World-affecting mods (stability, placement,
   raids) get a backup first.

## Phase 1 — data-only pack (current)

| # | Mod | Mechanism | Acceptance test |
| --- | --- | --- | --- |
| 1 | `WW_CarryWeight` | players loader, `CarryWeightMultiplier: 10` | HUD limit shows ~4000; can carry 10× before overburden |
| 2 | `WW_Storage` | blueprint loader, `BP_Components_WorldItemInventory.MaxSlotCount` | New and existing crates/chests open with new slot counts; sorting works |
| 3 | `WW_SpellCooldowns` | assets loader, `UtilitySpellData.CooldownDuration` | Rocksplosion ready in 10s; listed spells match table |
| 4 | `WW_RespawnFishing` | raw loader, `DT_ResourceRespawnSettings` rows | Depleted fishing node returns within target hours |
| 5 | `WW_RespawnRuneEssence` | raw loader, same table | Ground/minenode essence returns faster |
| 6 | `WW_RespawnAnimaVents` | raw loader, same table | `ANIMAVENT_48H` vent returns faster |
| 7 | `WW_RespawnMinerals` (off) | raw loader, same table | Optional mineral tuning |
| 8 | `WW_BuildingStability` | raw loader, `DT_StabilityProfile` losses → 0, tiered MaxStability | High/overhanging pieces place and stay green; no collapse |
| 8b | `WW_BuildingDurability` | blueprint loader, per-piece `HealthComponent.MaxHealth` (T1 x3, T2 x4, T3 x7, T4 x10) | Wall HP matches the tier table in-game |
| 9 | `WW_BuildPlacement` | raw loader, `DT_PlacementProfile.FarmingPlotProfile.bCanOnlyBePlacedOnGround=false` | Planter places on a built floor |
| 10 | `WW_BuildHeight` | blueprint loader, `BP_PlayerController.BuildPlacementComponent.MaxHeightModifier` | Can raise build height well above vanilla |

Test order: 1 → 2 → 3 → 4/5/6 → 8 → 9 → 10. Restart between groups; read
`ue4ss/RuneSchema.log` and `ue4ss/UE4SS.log` after each.

## Phase 2 — runtime behaviour (small Lua companion)

Each item ships as `ue4ss/<Package>/Scripts/main.lua` inside its RuneSchema mod,
so it is still one toggle.

| Feature | Hook | Notes |
| --- | --- | --- |
| Humidify width 4 plots | load `/Game/.../USD_Humidify`, set `DominionShape_Box_0.Extents` to (300,300,10), capsule radius 300, optionally water cost 100 | Nested subobject, no JSON directive |
| Compost area + cost | JSON `$DominionSpheres` radius; cost module needs Lua if scaling | Keep compost-per-plot ratio |
| Raid pacing / pause | find live `BP_WorldEventManager`, extend raid `Cooldown` triggers or zero `PeriodicPercentageChance` | Alternative: native frequency slider |
| Monster spawn rates | patch `DominionAISettings` (INI override) or per-region `DT_AISpawnData_*` rows | Test in a fresh session |
| Level-scaled runecrafting | hook rune craft result, grant extra runes by level/attunement | Highest complexity; needs live function discovery |
| Per-item weights | assets loader `ItemData.Weight` per item | Data-only, no Lua |

## Phase 3 — Mod Menu toggles

Once the data mods are stable, add `modmenu.json` schemas so numeric values
(e.g. cooldown seconds, respawn hours, carry multiplier) are adjustable in game
through Mod Menu / Helpy, with restart hints where required. The per-feature
`runeschema.txt` toggles remain the source of truth for load/no-load.

## Open decisions

- Storage: is the *Crate* the "basic ugly" container to triple, or the Small
  Chest? Current pack triples the Crate (16→48) and doubles the rest.
- Cooldowns: current table is a suggestion. Rocksplosion=10s is fixed; other
  spells can be tuned per-spell.
- Respawn targets are in **in-game hours**; exact real-time ratio is TBD.
- Stability: fully zero decay vs. soft decay (0.1/step). Current pack uses zero.
- Raids: prefer native frequency slider (0–3×) or a mod-side pause toggle?

## Risks

- `MaxHeightModifier` semantics unknown (cm vs multiplier); test incrementally.
- DataTable patch may silently reject nested `RespawnTime` fields; diagnostics
  in `RuneSchema.log` will show rejected fields.
- Changing CDOs of default subobjects (world event triggers) may not affect
  already-saved world actors.
- Storage shrink/disable can hide items in extra slots; migrate items first.
- Game updates can rename rows/classes; `docs/RESEARCH.md` is the map to re-check.
