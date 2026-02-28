# Pokédex Roadmap

## Phase 1: Tab Bar + Moves Database ✓

Restructure the app from a single split view into a tab bar with multiple sections.

**Status: Complete**

### What was built

- **UITabBarController** with two tabs: Pokédex and Moves, each containing its own UISplitViewController
- **Moves tab**: searchable master list (MoveListVC) with type badge, damage class, power/accuracy/PP columns + detail view (MoveDetailVC) with effect text, stats, battle effects, and "Learned By" Pokémon list with mini sprites
- **Pokémon detail**: added Moves card section showing moves grouped by learn method (Level-Up, TM/HM, Egg, Tutor) with type badges and stats columns
- **Data pipeline**: fetch.php downloads all ~937 moves (handles non-sequential IDs: 1-919 + 10001-10018) and move-damage-class data; process.php generates `moves/index.plist` and individual `moves/{id}.plist` files
- **New files**: Move.h/.m, MoveCell.h/.m, MoveListVC.h/.m, MoveDetailVC.h/.m
- **Modified**: main.m (tab bar), DataManager (move queries), PokemonDetailVC (moves card), fetch.php, process.php

---

## Phase 2: Filters and Search Improvements ✓

**Status: Complete**

### What was built

- **Filter popover** (FilterPopoverVC) presented from nav bar button on both tabs via UIPopoverController
  - Sort segmented control: Number / Name / Stat Total (Pokémon) or Number / Name / Power (Moves)
  - Type grid: 18 type buttons with colored backgrounds, tap to toggle, selected = full alpha + white border
  - Generation grid: Gen I–IX toggle buttons
  - Category toggles: Legendary / Mythical / Baby (Pokémon) or Physical / Special / Status (Moves)
  - Reset + Apply bottom bar; works on a copy of FilterState (cancel = no changes)
- **FilterState model** (NSCopying) holding selectedTypes, selectedGenerations, selectedCategories, sortBy
- **Enhanced DataManager** with `searchPokemonWithQuery:types:generations:categories:sortBy:` and `searchMovesWithQuery:types:generations:damageClasses:sortBy:` — filter logic is AND between groups, OR within groups
- **Pokédex number search**: typing "025" or "25" finds Pikachu (prefix match on raw and zero-padded formats)
- **Filter button badge**: shows "Filter (N)" when N filters are active
- **Data pipeline**: `process.php` enriched Pokémon index with `generation`, `stat_total`, `is_legendary`, `is_mythical`, `is_baby`; Moves index with `generation`
- **New files**: FilterState.h/.m, FilterPopoverVC.h/.m
- **Modified**: DataManager.h/.m, PokemonListVC.h/.m, MoveListVC.h/.m, process.php

### Performance fixes

- **Shared sprite cache** (NSCache, 200-entry limit) in DataManager — eliminates ~3-5ms disk re-read per cell on scroll, used by PokemonCell, Pokemon.spriteImage, and MoveDetailVC learnedBy card
- **Moves card capped** to 10 rows per section with "...and X more" — reduced label creation from 400-800 to ~60, moves card build time from 116-203ms to 48-62ms
- **Total detail layout** improved from ~150-234ms to ~74-96ms
- **[PERF] logging** throughout: detail view layout (per-card breakdown), plist loading, search/filter queries

---

## Phase 3: Additional Images ✓

**Status: Complete**

### What was built

- **Official artwork** as hero image on detail view — high-res Ken Sugimori-style art displayed at 65% card width (capped at 280px), centered in the header card. Falls back to standard sprite if artwork unavailable.
- **Shiny sprites** with toggle button — "★ Shiny" button in header card sprite strip, highlighted gold when active, swaps front sprite to shiny variant
- **Back sprites** — shown alongside front sprite in a 64px sprite strip row below the artwork
- **Female sprites** with gender toggle — ♂/♀ button shown only for sexually dimorphic Pokémon (101 species), swaps front sprite to female variant; `has_female_sprite` flag in each Pokémon plist
- **Redesigned header card** — info section (number, name, genus, type badges) above centered artwork, sprite strip with front/back + toggle buttons below
- **Data pipeline**: `fetch.php` refactored with `download_sprite_variant()` helper to download all variants from cached Pokémon JSON URLs; `process.php` copies to `src/sprites/artwork/`, `shiny/`, `back/`, `female/` subdirectories
- **Sprite counts**: 1025 artwork, 1025 shiny, 862 back, 101 female
- **DataManager**: 4 new methods (`artworkForPokemonID:`, `shinySpriteForPokemonID:`, `backSpriteForPokemonID:`, `femaleSpriteForPokemonID:`) using shared `spriteForPokemonID:directory:` helper with composite cache keys; cache limit raised to 400
- **Modified**: DataManager.h/.m, Pokemon.h/.m, PokemonDetailVC.m, fetch.php, process.php
- **Not yet implemented**: Generation-specific historical sprites (could be a future addition)

---

## Phase 4: Types Tab + Effectiveness Chart

### Type Chart Screen

An 18x18 grid showing type matchups:

- Rows = attacking type, columns = defending type
- Color-coded cells: green (2x), red (0.5x), black (0x), white (1x)
- Scrollable in both directions with sticky row/column headers
- Tap a cell to see details in a `UIPopoverController`

### Type Detail View

Tap a type from anywhere in the app (any type badge) to see:

- All Pokémon of that type (as a filtered list)
- All moves of that type
- Damage relations (super effective against, weak to, immune to)
- Uses data already in `types.plist`

---

## Phase 5: Evolution Chain Visualization

### Detail View Section

Add an "Evolution" card to the detail view:

- Horizontal layout: sprite thumbnails connected by arrows
- Below each sprite: Pokémon name and evolution trigger text ("Lv. 16", "Water Stone", "Trade", "Friendship")
- Tapping a sprite navigates to that Pokémon's detail view and selects it in the master list
- Handle branching evolutions (Eevee → 8 eeveelutions) with vertical stacking

### Data Already Available

Evolution chain data is already in each Pokémon's plist (the `evolution_chain` array with trigger details). This phase is purely UI work.

---

## Phase 6: Abilities + Items Databases ✓

**Status: Complete (v1.1)**

### What was built

- **Abilities tab** (green nav bar): AbilityListVC with 44px cells (name + "Gen X" subtitle), search bar, generation filter via FilterPopoverVC, AbilityDetailVC with card layout showing header (name + generation), effect/flavor text, and Pokémon list with sprites, numbers, names, and purple "Hidden" badges
- **Items tab** (orange nav bar): ItemListVC with 50px cells (32x32 item sprite + name + category + right-aligned cost), search bar, "Cost" column header, sort by number/name/cost, ItemDetailVC with card layout showing header (sprite + name + category + cost), effect/flavor text, fling info (conditional), and held-by Pokémon list
- **Models**: Ability.h/.m (abilityID, name, generation, isMainSeries, effect, flavorText, pokemon array, generationDisplay helper), Item.h/.m (itemID, name, apiName, category, cost, effect, flavorText, hasSprite, heldBy, flingPower, flingEffect, costString/categoryDisplay helpers)
- **FilterPopoverVC refactored**: replaced `BOOL movesMode` with `NSString *filterMode` supporting 4 modes — pokemon (types+gens+categories, sort: number/name/stat_total), moves (types+gens+damage_class, sort: number/name/power), abilities (gens only, sort: number/name), items (sort only: number/name/cost). Popover height auto-adjusts per mode.
- **DataManager extended**: allAbilitySummaries, searchAbilitiesWithQuery:generations:sortBy:, abilityDetailWithID:, allItemSummaries, searchItemsWithQuery:sortBy:, itemDetailWithID:, spriteForItemName: with shared sprite cache (limit raised to 500)
- **Data pipeline**: fetch.php downloads ~367 abilities and ~2175 items with item sprites; process.php generates abilities/index.plist, abilities/{id}.plist, items/index.plist, items/{id}.plist, and copies item sprites
- **Tab bar**: 4 tabs — Pokédex (pokéball), Moves (sword), Abilities (star), Items (bag)
- **New files**: Ability.h/.m, AbilityCell.h/.m, AbilityListVC.h/.m, AbilityDetailVC.h/.m, Item.h/.m, ItemCell.h/.m, ItemListVC.h/.m, ItemDetailVC.h/.m (16 files)
- **Modified**: DataManager.h/.m, FilterPopoverVC.h/.m, MoveListVC.m, PokemonListVC.m, main.m, scripts/config.sh, tools/fetch.php, tools/process.php

---

## Phase 7: Audio + Polish

### Pokémon Cries

- **Available from**: `cries.latest` and `cries.legacy` fields in Pokémon data (OGG format)
- Add a speaker button on the detail view header card
- Play with `AVAudioPlayer` (needs `-framework AVFoundation` in build.sh)
- Note: OGG may need conversion to WAV/CAF for iOS 6 compatibility

### Favorites

- Tap a star icon to favorite a Pokémon
- Store favorites in `NSUserDefaults` (persists across launches)
- Add a "Favorites" filter in the Pokédex tab

### Compare Mode

- Long-press two Pokémon in the list to compare
- Side-by-side stat bars, type matchups, and key info
- Displayed in a modal or popover

---

## Phase 8: Natures, Egg Groups + Berries ✓

**Status: Complete (v1.2, updated in v1.4)**

### What was built

- **Natures tab** (purple nav bar): NatureListVC with 50px cells (name, neutral subtitle, +Stat green/−Stat red labels), search bar, NatureDetailVC with card layout showing header (name, neutral badge), stat effects (+10%/−10% color-coded or "no stat effect" for neutral natures), flavor preferences (likes/dislikes or "no flavor preference")
- **Egg Groups tab** (teal nav bar): EggGroupListVC with 44px cells (name + "X Pokémon" count), search bar, EggGroupDetailVC with header card (name, count) and Pokémon list card (24px sprites, #number, name — capped at 30 rows with "...and X more" overflow)
- **Berries tab** (pink nav bar): BerryListVC with 50px cells (32x32 berry sprite, name, natural gift TypeBadgeView, right-aligned power), search bar + filter popover (sort by number/name/power, type filter for natural gift type), BerryDetailVC with header (48px sprite, name, firmness, TypeBadgeView + power), effect/flavor text, growth stats (5 key-value rows), flavor profile (5 colored horizontal bars: spicy=red, dry=gold, sweet=pink, bitter=green, sour=blue)
- **Models**: Nature.h/.m (stat/flavor display helpers converting API names to abbreviations), EggGroup.h/.m (id, name, pokemon array), Berry.h/.m (full berry data with firmness/growth/size display helpers)
- **FilterPopoverVC**: added `@"berries"` mode with type filter + sort by number/name/power
- **DataManager extended**: natures index (single plist, no separate detail), egg groups index + detail, berries index + detail + sprites via shared cache
- **Data pipeline**: fetch.php downloads 25 natures, 15 egg groups, 64 berries, 64 berry sprites; process.php generates all plists and copies sprites
- **Tab bar**: 7 tabs — Pokédex (pokéball), Moves (sword), Abilities (star), Items (bag), Natures (up/down arrows), Egg Groups (egg), Berries (berry)
- **New files**: Nature.h/.m, EggGroup.h/.m, Berry.h/.m, NatureCell.h/.m, EggGroupCell.h/.m, BerryCell.h/.m, NatureListVC.h/.m, EggGroupListVC.h/.m, BerryListVC.h/.m, NatureDetailVC.h/.m, EggGroupDetailVC.h/.m, BerryDetailVC.h/.m (24 files)
- **Modified**: DataManager.h/.m, FilterPopoverVC.m, main.m, scripts/config.sh, tools/fetch.php, tools/process.php

---

## Phase 9: iPhone/iPod Touch Support ✓

**Status: Complete (v1.3, updated in v1.4)**

### What was built

- **Device-conditional tab setup** in main.m: branches on `UI_USER_INTERFACE_IDIOM()` for all 7 tabs — iPad uses `UISplitViewController` (unchanged), iPhone uses `UINavigationController` wrapping each list VC directly
- **iPhone navigation**: tapping a row in any list pushes the detail VC onto the nav stack (existing `else` branch in `didSelectRowAtIndexPath:` — previously unreachable, now the active path on iPhone)
- **Modal filter presentation** on iPhone: 5 list VCs (PokemonListVC, MoveListVC, AbilityListVC, ItemListVC, BerryListVC) branch filter presentation — iPad shows `UIPopoverController`, iPhone wraps `FilterPopoverVC` in `UINavigationController` and presents modally with Cancel + Apply buttons
- **FilterPopoverVC width-adaptive layout**: replaced hardcoded `POPOVER_WIDTH` constant with `contentWidth` helper (returns 380 on iPad, `self.view.bounds.size.width` on iPhone); all layout — scroll view, sort control, type grid, generation grid, category buttons, bottom bar — uses dynamic width
- **Cancel button**: FilterPopoverVC adds a Cancel bar button item on iPhone for dismissing the modal without applying
- **No changes needed**: all 7 detail VCs (already use `self.view.bounds`), all cell classes (already use `contentView.bounds`), EggGroupListVC/NatureListVC (no filter popover), Info.plist (already declares both device families)
- **Modified**: main.m, FilterPopoverVC.m, PokemonListVC.m, MoveListVC.m, AbilityListVC.m, ItemListVC.m, BerryListVC.m (7 files)

---

## Phase Summary

| Phase | Feature | New Data | New Images | Effort |
|-------|---------|----------|------------|--------|
| 1 | Tab bar + Moves | ~937 moves | — | **Done** |
| 2 | Filters + search + perf | Add legendary/mythical flags | — | **Done** |
| 3 | Additional images | — | 1025 artwork, 1025 shiny, 862 back, 101 female | **Done** |
| 4 | Type chart | — | — | Medium |
| 5 | Evolution chains | — (data exists) | — | Small |
| 6 | Abilities + Items | ~367 abilities, ~2175 items | ~2175 item sprites | **Done** |
| 7 | Audio + polish | ~1025 cries | — | Medium |
| 8 | Natures, Egg Groups + Berries | 25 natures, 15 egg groups, 64 berries | 64 berry sprites | **Done** |
| 9 | iPhone/iPod Touch support | — | — | **Done** |
