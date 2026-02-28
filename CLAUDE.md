# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS 6 Pokédex app targeting jailbroken iPad 2 and iPhone/iPod Touch (ARMv7). Pure Objective-C with ARC, no package managers or third-party libraries. All data comes from PokeAPI v2, pre-processed into plist files bundled with the app.

Current version: 1.4. See ROADMAP.md for completed phases (1-3, 6, 8-9) and planned work (4, 5, 7).

## Build & Deploy

**Do NOT run build/deploy scripts.** The user handles all compilation and deployment to the iPad. After making code changes, prompt the user to build and deploy.

The app compiles on-device using clang over SSH. All scripts are in `scripts/` and source `config.sh` for iPad connection settings.

```bash
# Full pipeline: sync source to iPad → compile → package IPA → install
./scripts/deploy.sh

# Individual steps
./scripts/sync.sh      # Upload src/ to iPad via SCP
./scripts/build.sh     # Compile on iPad with clang (armv7, -fobjc-arc)
./scripts/install.sh   # Sign with ldid, package IPA, install, copy to builds/
```

Frameworks: UIKit, Foundation, CoreGraphics, QuartzCore. Compiler: clang 3.7.1. Min iOS: 6.0.

## Data Pipeline

**Do NOT run the PHP scripts.** Edit `tools/fetch.php` and `tools/process.php` as needed, but prompt the user to execute them.

```bash
php tools/fetch.php     # Download PokeAPI data → tools/.cache/ (JSON, with rate limiting)
php tools/process.php   # Convert cached JSON → src/data/ (plist) + src/sprites/ (PNG)
```

Data flow: PokeAPI v2 → cached JSON → XML plist files → DataManager singleton → model objects → views.

Index plists (lightweight arrays) are loaded at startup. Detail plists are lazy-loaded per ID and cached.

## Architecture

**UIKit MVC with singleton DataManager.** iPad-optimized: UITabBarController → 7 UISplitViewControllers (Pokédex, Moves, Abilities, Items, Natures, Egg Groups, Berries), each with master list + detail view.

### Key patterns

- **DataManager** (`DataManager.h/.m`): Singleton via `+sharedManager`. Lazy-loads and caches plist data. Provides search/filter APIs. Shared NSCache (500 entries) for sprites.
- **Models** (`Pokemon`, `Move`, `Ability`, `Item`, `Nature`, `EggGroup`, `Berry`): Property holders with `+fromDictionary:` factory methods and display helpers.
- **FilterState** + **FilterPopoverVC**: Reusable filter system. FilterPopoverVC adapts to `filterMode` (@"pokemon", @"moves", @"abilities", @"items", @"berries") — different filter sections per mode. Operates on a copy of FilterState (cancel discards changes).
- **List VCs**: UITableViewController subclasses implementing UISearchDisplayDelegate and FilterPopoverDelegate. Filter button shows badge count.
- **Detail VCs**: UIScrollView with manually-laid-out "card" UIViews. Layout constants: 16px margins, 14px padding/spacing, 8px corner radius. Rebuild layout in `viewDidLayoutSubviews` via `rebuildLayout` method.
- **TexturedBackgroundView**: Skeuomorphic iOS 6 linen-texture background used across detail views.
- **TypeBadgeView** + **PokemonType**: Colored type badges with static color mappings for 18 types.

### Source layout

All source files are flat in `src/` (no subdirectories for code). Headers and implementations side-by-side. Data in `src/data/`, sprites in `src/sprites/` with subdirectories (artwork/, shiny/, back/, female/, items/, berries/).

### Filter/search logic

- Types and generations: OR within group (any match passes)
- Categories: AND between groups, OR within groups
- Pokédex number search: matches raw ("25") and zero-padded ("025") formats
- Sort options vary by tab (number/name/stat_total, number/name/power, number/name, number/name/cost, number/name/power for berries)

## iOS 6 Constraints

- No Auto Layout—use manual frame-based layout (`CGRectMake`, `sizeThatFits:`)
- No `UISearchController`—use deprecated `UISearchDisplayController` + `UISearchBar`
- No `UIAlertController`—use `UIAlertView` / `UIActionSheet`
- No asset catalogs—direct PNG references
- Popovers via `UIPopoverController` (iPad only, no iPhone equivalent)
- `NSArray`/`NSDictionary` literals require iOS 6+ (fine for this project)
- ARC is enabled; no manual retain/release

## Performance

Performance logging throughout with `[PERF]` prefix in NSLog. Key optimizations:
- Sprite NSCache shared across all views (500-entry limit, composite keys with directory)
- Moves card in PokemonDetailVC capped at 10 rows per section with "...and X more"
- Plist indexes loaded once and cached in DataManager
