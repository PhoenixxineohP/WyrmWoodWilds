# Research notes — Dragonwilds 5.6.1 (`++dominion+hotfix-CL-261625`)

Everything below was read from the installed game (Steam appid `1374490`) with
`retoc` + CUE4Parse and the community `.usmap` for 5.6.1. Paths are UE object
paths. "USD" = `UtilitySpellData` asset; "DA" = data asset; "DT" = DataTable.

## Toolchain

- Game containers: `RSDragonwilds/Content/Paks/RSDragonwilds-Windows.{pak,utoc,ucas}` (IoStore, indexed).
- Asset reader: CUE4Parse 1.2.2 against `GAME_UE5_6`, mappings `RSDragonwilds-5.6.1-201081` (Aug 2026).
  The current build is newer (Nov 2026), so a few DataTables deserialize with
  empty rows even though the row names are present in the asset. Those are noted.
- Config files are plain INI inside the `.pak` and can be read with the same
  reader, e.g. `RSDragonwilds/Config/DefaultBuildingSettings.ini`.

## 1. Spell cooldowns

Cooldowns are a top-level field on each spell's `UtilitySpellData` asset:

```
CooldownDuration (float, seconds)
```

Verified values (vanilla → WyrmWood default):

| Spell | Asset | Vanilla | Pack |
| --- | --- | ---: | ---: |
| Rocksplosion | `/Game/Gameplay/UtilityMagic/PerkSpells/Rocksplosion/USD_Rocksplosion` | 60 | **10** |
| Humidify | `.../Farming/Humidify/USD_Humidify` | 45 | 15 |
| Compost | `/Agility/Gameplay/UtilityMagic/PerkSpells/Farming/USD_Farming_Compost` | 45 | 15 |
| Rapid Growth | `.../RapidGrowth/USD_RapidGrowth` | 60 | 30 |
| Divine Rock | `.../DivineRock/USD_DivineRock` | 1800 | 300 |
| Home Teleport | `.../HomeTeleport/USD_HomeTeleport` | 900 | 300 |
| Spectral Arrows | `.../CorruptionArrows/USD_CorruptionArrows` | 300 | 120 |
| Enchant Weapon (4) | `.../EnchantWeapon/USD_EnchantWeapon_*` | 300 | 120 |
| Bark to Bones | `.../Treequipment/USD_Treequipment` | 300 | 120 |
| Fish Cyclone / Fishing Frenzy | `/Fishing/Gameplay/UtilityMagic/USD_*` | 300 | 120 |
| Internal Alchemy | `.../InternalAlchemy/USD_InternalAlchemy` | 210 | 120 |
| Cabbage Rain / Chef's Tools / Trunk Totem / Infernal Rod | `...` | 180 | 90 |
| Confuse | `.../Confuse/USD_Confuse` | 120 | 60 |
| Enfeeble / Recall | `...` | 75 | 45 |
| Magical Mending / Rapid Growth / Vengeance | `...` | 60 | 30 |
| Axtral Projection / Snare / Splinter / Surge / Tempest Shield / PhaseDash | `...` | 45 | 30 |
| Detect Ore (Alt) | `.../DetectOre/AlternativeRadar/USD_DetectOreAlt` | 30 | 15 |
| Summon Shelter | `.../SummonShelter/USD_SummonShelter` | 15 | 10 |

There is also a **native world setting** `Difficulty.Player.SpellCooldownScale`
(0–3×) exposed as *Spell Cooldown Scale* in Custom/Creative world settings
(`DA_DifficultySetting_SpellCooldownScale`). It multiplies our per-spell values;
keep it at 1.0 unless you want a second global knob.

## 2. Resource respawns

Component: `ResourceRespawnComponent` on each resource actor. It points at
`/Game/Gameplay/RespawnProfiles/DT_ResourceRespawnSettings` with a row handle.

Row struct `ResourceRespawnSettings`:

| Field | Type |
| --- | --- |
| `RespawnTime` | struct `ResourceRespawnTime` (`Days`/`Hours`/`Minutes`/`Seconds`, ints) |
| `bRequireMinimumDistanceToPlayers` | bool |
| `MinimumDistanceToPlayers` | float |
| `bRequireMinimumDistanceToBeds` | bool |
| `MinimumDistanceToBeds` | float |

Row names present in the build (read from the raw asset):

`ANIMAVENT_48H`, `FISH_NODE_24H`, `FISH_NODE_72H`, `FLORA_BERRY_72H`,
`FLORA_HERBS_48H`, `FLORA_HERBS_72H`, `FLORA_VEGETABLES_24H`,
`FLORA_VEGETABLES_72H`, `MINERAL_BOULDER_NOBED_24H`, `MINERAL_GROUND_12H`,
`MINERAL_GROUND_24H`, `MINERAL_MINENODE_48H`, `MINERAL_MINENODE_72H`,
`RUNEESSENCE_GROUND_24H`, `RUNEESSENCE_MINENODE_48H`, `SALVAGE_72H`,
`TREE_GROUND_12H`, `TREE_MATURE_NOBED_72H`, `TREE_ROOT_72H`,
`TREE_SAPLING_NOBED_24H`.

Fishing nodes (`/Fishing/.../FishingNodesV2/BP_FishingNodeV2_Rod_*`) and rune
essence nodes use these handles. Anima vents use `ANIMAVENT_48H`.

> The DataTable deserializes with empty rows against the Aug mappings, but the
> row-name blob is intact. RuneSchema's `raw` loader validates rows against live
> reflection at runtime, so the patch is written by row name.

## 3. Raids / world events

`/Game/Gameplay/Events/BP_WorldEventManager` holds `WorldEventDefinitions`
(base raids: `BP_BaseRaidEvent_BM_1/2`, `GF_1/2`, `FH_1`). Each definition lists
trigger subobjects:

- `AfterDurationWorldEventTrigger` — `DelayAtStart` (9–12 in-game days) and
  `Cooldown` (2 d 6 h – 4 d 12 h), scaled by
  `Difficulty.WorldEvents.MinorWorldEventFrequencyScale` /
  `MajorWorldEventFrequencyScale`.
- `PeriodicPercentageChanceWorldEventTrigger` — e.g. 5–10% per hour.
- `PlayersInBaseWorldEventTrigger` — `MaxRangeFromABedToBeConsideredInABase`
  3000–6000, `bRequirePlayersToNotBeInBase` on some events.

Native world settings already expose **Minor/Major World Event Frequency Scale**
(0–3×) for Custom/Creative worlds. `DA_DifficultySetting_*WorldEventFrequencyScale`
declares the slider (max 3.0) and `PresetDefaults` (Normal/Hard = 1.0).

The manager is saved as a placed actor (`WorldEventManager_UAID_...` in the world
save), so patching the Blueprint CDO is not guaranteed to affect existing saves.
Phase 2 options: (a) native world-setting slider, (b) Lua edit of the live
manager's trigger durations, (c) a cooked provider actor implementing
RuneSchema's `RuneSchemaEnemySpawnMultiplier`/world policies (needs UE).

## 4. Monster spawn rates (what the game exposes)

Global `[/Script/Dominion.DominionAISettings]` (file
`Config/DefaultDominionAISettings.ini`):

```
DynamicSpawnRaritySettings=((Legendary, (QuantityPerSquareMeter=0.000010,
  SpawnIntervalSeconds=1000.0, CreatureLimitPerPlayer=1)), ...)
```

Per-rarity `SpawnIntervalSeconds`, `CreatureLimitPerPlayer`,
`QuantityPerSquareMeter`; `LowAISpawnProbabilityMultiplier`,
`MaxAINearbyToApplyLowAISpawnProbabilityMultiplier`, tether ranges, etc.

Per-region spawn tables: `/Game/Gameplay/AI/AI_Spawn_Data_Tables/DT_AISpawnData_*`
(one per biome/zone). Spawn prevention around bases:
`/Game/Gameplay/AI/DT_AISpawnPreventionSettings` rows `CLOSE`, `MEDIUM`, `FAR`.

RuneSchema's experimental world-policy API adds:

- `RuneSchemaEnemySpawnMultiplier` (0 suppresses newly spawned hostile AI, 2 adds one)
- `RuneSchemaResourceRespawnMultiplier` (divides respawn duration)
- `RuneSchemaFarmProtection`, `RuneSchemaResourceYieldMultiplier`, `RuneSchemaAIPassivity`

Those require a **cooked Blueprint provider actor** (Unreal Engine), so they are
not usable from this Linux/CLI-only setup. The DataTable/INI equivalents above
are.

## 5. Carry capacity

Two independent levers:

1. **RuneSchema players loader** — `CarryWeightMultiplier` (0.1–100) or
   `MaxCarryWeight` (1–1,000,000), applied to the pawn's native attribute.
   This is what `WW_CarryWeight` uses (`10.0`).
2. **Native world setting** `Difficulty.Player.InventoryCarryCapacityScale`
   (0–3×), `DA_DifficultySetting_InventoryCarryCapacityScale`.

Per-item weight is `ItemData.Weight` (float) on each item asset; patching
individual items is data-only and planned.

## 6. Storage

`BP_Components_WorldItemInventory` on each container; field `MaxSlotCount`:

| Container | Class | Vanilla | Pack |
| --- | --- | ---: | ---: |
| Crate | `BP_BaseBuilding_Crate_C` | 16 | 48 (×3) |
| Small chest | `BP_BaseBuilding_Chest_Small_C` | 32 | 64 |
| Chest | `BP_BaseBuilding_Chest_C` | 48 | 96 |
| Iron chest | `BP_BaseBuilding_Chest_Iron_C` | 64 | 128 |
| Personal chest | `BP_BaseBuilding_PersonalChest_C` | 40 | 80 |
| Lumber storage | `BP_BaseBuilding_LumberStorage_C` | 48 | 96 |
| Ore storage | `BP_BaseBuilding_OreStorage_C` | 48 | 96 |
| Fishing rack | `BP_BaseBuilding_FishingRack_C` | 4 | 8 |

`bSupportsSortAndFillStacks` is already true on some; the pack enables it where
the component exists.

## 7. Building restrictions

### Stability

`/Game/Gameplay/BaseBuilding_New/DT_StabilityProfile`, row struct
`StabilityProfile`:

```
MaxStability, MinStability, VerticalLoss, HorizontalLoss   (floats)
```

Rows: `Prop`, `Stackable_Prop`, `Tier1_Foundation`, `Tier1_Beam`, `Tier1_Base`,
`Tier2_*`, `Tier3_*`, `FarmPlot`. Vanilla losses are 1.0 vertical and 1.0–2.5
horizontal per step; `FarmPlot` is 1.0/1.0 with Max 900 / Min 20.

Setting `VerticalLoss`/`HorizontalLoss` to `0` keeps pieces at max stability.
There is also a native **No Building Stability** toggle
(`DA_DifficultySetting_NoBuildingStability`) but it is `CustomAndCreative` and
`bCanBeChangedAfterWorldCreation: false`.

### Placement

`/Game/Gameplay/BaseBuilding_New/DT_PlacementProfile`, row struct
`PlacementProfile` (22 fields). Relevant fields:

- `bCanOnlyBePlacedOnGround`
- `bCanOnlyBePlacedOnDefinedSurface`
- `bCanOnlyBePlacedOnCertainPhysicalSurfaces` + `AcceptedPhysicalSurfaces`
- `bAllowOverlappingWithBuildingPieces`, `OverlapExceptionFilter`
- `bCanOnlyBeSnapped`, `bAllowUserHeightModification`, `bForcePlugRotation`

Rows: `BaseProfile`, `Ceiling`, `PropProfile`, `DoorWindowProfile`,
`FarmingPlotProfile`, `WellProfile`, `FloorPropNonOverlapProfile`,
`FloorPropProfile`, `FoundationProfile`, `RoofProfile`, `WallPropProfile`,
`WaterProfile`, …

The pack clears `bCanOnlyBePlacedOnGround` on `FarmingPlotProfile` so planters
can sit on built floors.

### Height

`BuildPlacementComponent` (default subobject on `BP_PlayerController`) has
`MaxHeightModifier` (float, not serialized in the CDO dump, so it is a C++
default). The pack sets it to 20000.

### Building into scenery

The remaining "red" cases are checked by `BuildValidationComponent` / native
placement traces, not by one exposed boolean. Options: relax more
`PlacementProfile` rows (`bCanOnlyBePlacedOnCertainPhysicalSurfaces`,
overlap filters) and test; deeper cases need Lua or a cooked provider.

## 8. Farming spell areas

`USD_Humidify` owns shape subobjects:

- `DominionShape_Box_0` → `Extents = (150, 150, 10)` (≈2 plots wide)
- `DominionShape_Capsule_0` → `Radius = 150`
- `SpellModule_RemoveCombinedContentAmount_0` → `AmountToRemove = 50` (water)

`USD_Farming_Compost`:

- `DominionShape_Sphere_0` → `Radius = 300`
- `SpellModule_RemoveCombinedContentAmount_1` → `AmountToRemove = 150` (compost)

Visualizer BP: `BP_SpellPlacementVisualizer_Humidify` has `CloudWidth = 300`,
`RainRadius = 150`.

RuneSchema's assets loader can patch a top-level field of a data asset and has a
special `$DominionSpheres` directive for `DominionShape_Sphere` subobjects
(so Compost radius is doable in JSON). Box/capsule extents and the cost modules
are nested subobjects without a JSON directive, so Humidify width + cost scaling
need a small **Lua companion** (`ue4ss/` folder inside the mod) in phase 2.

Farming config (`Config/DefaultFarmingSettings.ini`):
`WaterNeededForWatering=50`, `CompostNeededForFertilizing=50`,
`CyclePeriod=720`, compost tiers `FCD_Compost_1..3`, water tiers
`FWD_NoWater`/`DirtyWater`/`CleanWater`.

## 9. Runecrafting

Base recipe (`/Game/Gameplay/Items/Resources/Magic/RECIPE_Process_Altar_<Rune>_Rune`):

```
ItemsConsumed: 1x ITEM_Rune_Essence
ItemsCreated:  5x ITEM_Rune_<Type>
ChanceToProduceExtraItems: 0.05
MinProcessingTime/MaxProcessingTime: 10
```

`DA_RunecraftingDifficultyData_Normal`: `BonusReward = 68`,
`BonusRewardOverrideWithPerk = 68`, infusion timings.

`DA_RunecraftingData`: `XPMultiplierAutoCraft = 0.25`,
`RecipeDataToAutoCraftBonusMap` (per-rune perk → `BonusRewardWithPerk = 100`),
`RecipeDataToBonusXPMultiplier = 1.5`.

`PerkV2_Runecrafting_HighAttunementBonusRunes_<Rune>` gates the 100% bonus
("Air Efficiency", level 22 etc.). There are **no level curves** in data, so the
requested level-scaled 1:10 → 1:50 progression is a formula change and needs a
runtime hook (Lua) or cooked Blueprint. Phase 2.

## 10. Native world settings (Custom/Creative)

`/Game/Gameplay/DifficultySettings/` declares these player-adjustable settings:

- Spell Cooldown Scale (0–3×)
- Inventory Carry Capacity Scale (0–3×)
- Minor/Major World Event Frequency Scale (0–3×)
- No Building Stability (toggle)
- Building Material Cost Scale, Crafting Cost Scale, Processing Speed Scale
- XP Gain Scale, Player Damage/Health/Resistances/Stamina/Lifeward Scale
- Hunger/Thirst/Sustenance/Endurance drain, Friendly Fire, Keep Inventory,
  Teleportation Cost, All Recipes/Building Pieces/Skills unlocked

This means some requests are already native (but capped at 3× and, for world
settings, only on Custom/Creative worlds). The pack exists to go beyond those
caps and to reach per-asset values.

## Community landscape (as of Nov 2026)

- The standard Dragonwilds stack is **UE4SS 3.0.1** + **RuneSchema** + a mod
  manager; pak mods live in `Content/Paks/~mods`, data mods in
  `RuneSchema/mods/<Mod>`.
- Public repos confirm this layout: `gh0sted5456-us/RuneSchema`,
  `MichaelRyan2319/RSDragonwilds-UE4SS`, `relichunter4life/Dragonwilds-MO2`.
- RuneSchema ships worked examples for exactly the patterns used here: bigger
  inventory/chests (Blueprint component defaults), creature drops (DataTable
  rows), cooked item patches, and append/targeted array edits.
- Spawn/respawn work in the community is done through the game's DataTables and
  Blueprint defaults, not asset replacement; RuneSchema's spawn extensions add
  respawn duration and enemy-spawn multipliers for mod-authored spawns, and its
  experimental world policies extend that to native actors when a cooked provider
  is installed.

## Unknowns / verify in game

- Exact in-game-time ↔ real-time ratio for respawn rows.
- Whether `MaxHeightModifier` is centimetres or a multiplier.
- Whether patched CDOs of default subobjects affect the already-saved
  `BP_WorldEventManager` instance.
- Whether `FarmingPlotProfile` alone is enough for all planter variants.
- DataTable row deserialization in the current build (row names known, values
  not readable with the Aug mappings).
