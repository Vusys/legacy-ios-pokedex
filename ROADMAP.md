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

## Phase 3: Additional Images

PokeAPI provides many sprite variants. These are all available for download.

### Official Artwork (High Priority)

- **URL pattern**: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/{id}.png`
- Large, high-quality official Ken Sugimori-style artwork
- Use as the main image on the detail view (much nicer than the 96x96 sprite)
- Keep the small sprite for the list view cells

### Shiny Sprites

- **URL pattern**: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/{id}.png`
- Add a toggle button on the detail view to swap between normal and shiny
- Same 96x96 size as regular sprites

### Back Sprites

- **URL pattern**: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/back/{id}.png`
- Show front + back side by side on the detail header card

### Female Sprites (Where Applicable)

- **URL pattern**: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/female/{id}.png`
- Only exists for sexually dimorphic Pokémon (Pikachu, Meowstic, etc.)
- Show a gender toggle on the detail view when available

### Generation-Specific Sprites

Historical sprites from each game generation:

- **Gen I** (Red/Blue, Yellow) — original pixel art, ~56x56
- **Gen II** (Gold/Silver, Crystal) — animated in Crystal
- **Gen III** (Ruby/Sapphire, Emerald, FireRed/LeafGreen)
- **Gen IV** (Diamond/Pearl, HeartGold/SoulSilver, Platinum)
- **Gen V** (Black/White) — animated sprites available

Could add a "Sprite Gallery" section to the detail view showing the Pokémon's art across generations.

### Data Pipeline Changes

- `fetch.php`: download additional sprite variants to separate cache directories
- `process.php`: copy them to `src/sprites/artwork/`, `src/sprites/shiny/`, `src/sprites/back/`, etc.
- Estimated additional storage: ~50MB for artwork, ~5MB for shiny, ~5MB for back sprites

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

## Phase 6: Abilities + Items Databases

### Abilities Tab/Section

- **Endpoint**: `/api/v2/ability/{id}` (~300 abilities)
- **Fields**: name, effect description, flavor text, generation, Pokémon with this ability
- Searchable list, tap for detail showing description + Pokémon list
- Link from Pokémon detail view ability names to the ability detail

### Items Database

- **Endpoint**: `/api/v2/item/{id}` (~2000 items)
- **Fields**: name, category, cost, effect, flavor text, sprite, held-by Pokémon, fling power
- **Item sprites**: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/{name}.png`
- Organized by pocket/category (Poké Balls, Medicine, TMs, Berries, etc.)

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

## Phase 8: Natures, Egg Groups + Berries

Three additional reference databases to round out the Pokédex.

### Natures Tab

- **Endpoint**: `/api/v2/nature/{id}` (25 natures)
- **Fields**: name, increased stat (+10%), decreased stat (-10%), favorite/disliked flavor
- Display as a grid/table: Nature → boosted stat → reduced stat → flavor preference
- Color-code stat changes (green for boost, red for reduction)
- 5 neutral natures (Hardy, Docile, Serious, Bashful, Quirky) where both stats are the same
- Small dataset — could be a single scrollable screen rather than master/detail

### Egg Groups Browser

- **Endpoint**: `/api/v2/egg-group/{id}` (15 egg groups)
- **Fields**: name, list of Pokémon species in the group
- **Groups**: Monster, Water 1, Water 2, Water 3, Bug, Flying, Field, Fairy, Grass, Human-Like, Mineral, Amorphous, Ditto, Dragon, Undiscovered
- Master list of egg groups → tap to see all compatible Pokémon with sprites
- Note: Pokémon can belong to multiple egg groups (e.g., Bulbasaur is Monster + Grass)
- Egg group data already exists in individual Pokémon plists (`egg_groups` field) — could add a section to Pokémon detail view linking to egg group pages
- "Undiscovered" group contains legendaries/mythicals/baby Pokémon that cannot breed

### Berries Database

- **Endpoint**: `/api/v2/berry/{id}` (~64 berries)
- **Fields**: name, growth time, max harvest, size, smoothness, soil dryness, firmness, natural gift power/type, flavors (spicy/dry/sweet/bitter/sour potency values)
- **Berry sprites**: available via the items endpoint (`https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/{name}-berry.png`)
- Searchable master list with berry sprite, name, and natural gift type badge
- Detail view showing growth stats, flavor profile (could visualize as a radar/bar chart), natural gift info, and game effect description
- **Firmness categories**: very soft, soft, hard, very hard, super hard

### Data Pipeline Changes

- `fetch.php`: download nature, egg group, and berry data from PokeAPI
- `process.php`: generate `natures.plist`, `egg-groups/index.plist`, `egg-groups/{id}.plist`, `berries/index.plist`, `berries/{id}.plist`, and berry sprites

---

## Phase Summary

| Phase | Feature | New Data | New Images | Effort |
|-------|---------|----------|------------|--------|
| 1 | Tab bar + Moves | ~937 moves | — | **Done** |
| 2 | Filters + search + perf | Add legendary/mythical flags | — | **Done** |
| 3 | Additional images | — | Artwork, shiny, back, historical | Medium |
| 4 | Type chart | — | — | Medium |
| 5 | Evolution chains | — (data exists) | — | Small |
| 6 | Abilities + Items | ~300 abilities, ~2000 items | ~2000 item sprites | Large |
| 7 | Audio + polish | ~1025 cries | — | Medium |
| 8 | Natures, Egg Groups + Berries | 25 natures, 15 egg groups, ~64 berries | ~64 berry sprites | Medium |
