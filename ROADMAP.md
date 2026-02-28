# Pokédex Roadmap

## Phase 1: Tab Bar + Moves Database

Restructure the app from a single split view into a tab bar with multiple sections.

### Tab Bar Structure

- **Pokédex** — the current split view (Pokémon list + detail)
- **Moves** — searchable/filterable move database
- **Types** — type effectiveness chart

### Moves Tab

New data to fetch and process:

- **Endpoint**: `/api/v2/move/{id}` (~900 moves)
- **Fields**: name, type, power, accuracy, PP, damage class (physical/special/status), effect description, flavor text, generation introduced, learned-by Pokémon list
- **Endpoint**: `/api/v2/move-damage-class/{id}` — physical, special, status icons/labels

UI: split view mirroring the Pokédex tab. Master list shows move name, type badge, power/accuracy. Detail view shows full info + which Pokémon learn it.

### Pokémon Detail: Move List Section

Add a "Moves" card to the existing detail view, organized by learn method:

- **Level-up** — sorted by level, shows level number
- **TM/HM** — sorted by machine number
- **Egg Moves** — alphabetical
- **Tutor Moves** — alphabetical

Each row: move name, type badge, power, accuracy, PP.

### Data Pipeline Changes

- `fetch.php`: add loop for `/api/v2/move/{id}` (1–900), cache to `tools/.cache/moves/`
- `process.php`: generate `src/data/moves/index.plist` (lightweight) and `src/data/moves/{id}.plist` (detail)

---

## Phase 2: Filters and Search Improvements

### Pokédex Filters

Add a filter button in the master list nav bar that opens a `UIPopoverController` with:

- **Type filter** — grid of type badges, tap to toggle (multi-select). Show only Pokémon matching selected types.
- **Generation filter** — list of Gen I through Gen IX, tap to toggle
- **Sort by** — number (default), name (A-Z), stat totals (high-low)
- **Category filter** — legendary, mythical, baby (using `is_legendary`, `is_mythical`, `is_baby` from species data — needs adding to process.php)

### Search Improvements

- Search should match Pokédex number (typing "025" finds Pikachu)
- Search in the Moves tab by move name
- Search across tabs via a top-level search bar

### Data Pipeline Changes

- `process.php`: add `is_legendary`, `is_mythical`, `is_baby` boolean fields to each Pokémon plist and to `index.plist` entries

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

## Phase Summary

| Phase | Feature | New Data | New Images | Effort |
|-------|---------|----------|------------|--------|
| 1 | Tab bar + Moves | ~900 moves | — | Large |
| 2 | Filters + search | Add legendary/mythical flags | — | Medium |
| 3 | Additional images | — | Artwork, shiny, back, historical | Medium |
| 4 | Type chart | — | — | Medium |
| 5 | Evolution chains | — (data exists) | — | Small |
| 6 | Abilities + Items | ~300 abilities, ~2000 items | ~2000 item sprites | Large |
| 7 | Audio + polish | ~1025 cries | — | Medium |
