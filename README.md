# Pokédex for iOS 6

A native Objective-C Pokédex app for jailbroken iPad 2 / iPhone / iPod Touch
running iOS 6, built entirely without Xcode or a Mac — compiled on-device
over SSH with clang. Pure UIKit, no third-party libraries, no package
managers.

See [`guide-ios6-development.md`](guide-ios6-development.md) for the full
story of how a legacy iOS app gets built this way, and
[`ROADMAP.md`](ROADMAP.md) for what's shipped and what's planned.

## Features

- Pokédex, Moves, Abilities, Items, Natures, Egg Groups, and Berries tabs,
  each a master/detail `UISplitViewController`
- Search and multi-criteria filtering (type, generation, category) across
  every tab
- Evolution chains, encounter locations, learnsets, and sprite variants
  (shiny, back, female)

## Data pipeline

All Pokémon data and sprites come from [PokeAPI](https://pokeapi.co) and are
**fetched at build time — nothing is committed to this repository**.
`src/data/` and `src/sprites/` are generated, gitignored directories:

```bash
php tools/fetch.php          # Download PokeAPI data → tools/.cache/ (JSON, rate-limited)
php tools/process.php        # Convert cached JSON → src/data/ (plist) + src/sprites/ (PNG)
./scripts/optimize-sprites.sh  # Losslessly recompress src/sprites/ with optipng -o7 (parallel)
```

`fetch.php` caches every response under `tools/.cache/` (also gitignored)
and skips anything already cached, so re-runs only pull what's missing. CI
restores that cache between runs rather than re-fetching from PokeAPI on
every build (see `.github/workflows/build.yml`).

Pokémon names, sprites, and data are property of Nintendo, Game Freak, and
Creatures Inc. — see [`LICENSE`](LICENSE).

## Building

**Locally, on a jailbroken device:** copy `scripts/config.sh.example` to
`scripts/config.sh`, fill in your device's IP and paths, then:

```bash
./scripts/deploy.sh     # sync → compile on-device → package IPA → install
```

**In CI, without a device:** GitHub Actions cross-compiles against a
Linux-hosted clang and a fetched iOS 6.1 SDK (see
`.github/actions/setup-toolchain/`) and packages a fakesigned `.ipa`:

```bash
php tools/fetch.php && php tools/process.php
./scripts/optimize-sprites.sh   # needs optipng + GNU parallel
./scripts/ci-build.sh           # needs $CLANG, $LDID, $SDK — see the action above
```

Every push builds an `.ipa` as a GitHub Actions artifact. Pushing a tag like
`v1.5` (matching `src/Info.plist`'s `CFBundleShortVersionString`) cuts a
GitHub Release with the `.ipa` attached.

## Architecture

See [`CLAUDE.md`](CLAUDE.md) for the full architecture writeup (MVC layout,
`DataManager` singleton, filter/search semantics, iOS 6 constraints, etc).

## Requirements

- iOS 6.0–6.1, jailbroken (for on-device installs)
- iPad 2 or iPhone/iPod Touch, ARMv7

## License

Source code is MIT-licensed — see [`LICENSE`](LICENSE). Pokémon data and
sprites are not included in this repo and are not covered by that license.
