<?php
/**
 * fetch.php - Download all Pokemon data from PokeAPI with local caching.
 *
 * Downloads:
 *   - All Pokemon data (/api/v2/pokemon/{id})
 *   - All Species data (/api/v2/pokemon-species/{id})
 *   - All Type data (/api/v2/type/{id})
 *   - All Move data (/api/v2/move/{id})
 *   - Move damage classes (/api/v2/move-damage-class/{id})
 *   - Evolution chains (discovered from species data)
 *   - Front-default sprite PNGs
 *   - All Ability data (/api/v2/ability/{id})
 *   - All Item data (/api/v2/item/{id})
 *   - Item sprite PNGs (from GitHub)
 *
 * Everything is cached to tools/.cache/ so re-runs skip already-fetched data.
 *
 * Usage: php tools/fetch.php
 */

define('BASE_URL', 'https://pokeapi.co/api/v2');
define('CACHE_DIR', __DIR__ . '/.cache');
define('RATE_LIMIT_MS', 100); // ms between requests

// ─── Helpers ────────────────────────────────────────────────────────

function cache_path(string $category, string $key, string $ext = 'json'): string {
    return CACHE_DIR . "/{$category}/{$key}.{$ext}";
}

function is_cached(string $category, string $key, string $ext = 'json'): bool {
    return file_exists(cache_path($category, $key, $ext));
}

function read_cache(string $category, string $key, string $ext = 'json'): ?string {
    $path = cache_path($category, $key, $ext);
    if (!file_exists($path)) return null;
    return file_get_contents($path);
}

function write_cache(string $category, string $key, string $data, string $ext = 'json'): void {
    $path = cache_path($category, $key, $ext);
    $dir = dirname($path);
    if (!is_dir($dir)) mkdir($dir, 0755, true);
    file_put_contents($path, $data);
}

function fetch_url(string $url): ?string {
    $ctx = stream_context_create([
        'http' => [
            'timeout' => 30,
            'header' => "User-Agent: ios6pokedex-fetcher/1.0\r\n",
        ],
    ]);

    $data = @file_get_contents($url, false, $ctx);
    if ($data === false) return null;
    return $data;
}

function fetch_json(string $url): ?array {
    $data = fetch_url($url);
    if ($data === null) return null;
    return json_decode($data, true);
}

/**
 * Fetch a URL and cache the response. Returns the cached/fetched data as a string.
 * Returns null on failure.
 */
function fetch_cached(string $category, string $key, string $url, string $ext = 'json'): ?string {
    if (is_cached($category, $key, $ext)) {
        return read_cache($category, $key, $ext);
    }

    usleep(RATE_LIMIT_MS * 1000);
    $data = fetch_url($url);
    if ($data === null) return null;

    write_cache($category, $key, $data, $ext);
    return $data;
}

/**
 * Fetch JSON, cache it, return decoded array.
 */
function fetch_json_cached(string $category, string $key, string $url): ?array {
    $data = fetch_cached($category, $key, $url);
    if ($data === null) return null;
    return json_decode($data, true);
}

// ─── Sprite Variant Downloader ──────────────────────────────────────

/**
 * Download a sprite variant for all Pokemon, using cached pokemon JSON to get URLs.
 */
function download_sprite_variant(string $cacheCategory, string $label, int $totalSpecies, callable $urlExtractor): array {
    echo "--- Downloading {$label} ---\n";
    $fetched = 0;
    $skipped = 0;
    $missing = 0;

    for ($id = 1; $id <= $totalSpecies; $id++) {
        if (is_cached($cacheCategory, (string)$id, 'png')) {
            $skipped++;
        } else {
            $pokemonJson = read_cache('pokemon', (string)$id);
            if ($pokemonJson === null) {
                $missing++;
                if ($id % 50 === 0 || $id === $totalSpecies) {
                    echo "  {$label}: {$id}/{$totalSpecies} (fetched: {$fetched}, cached: {$skipped}, missing: {$missing})\n";
                }
                continue;
            }
            $pokemonData = json_decode($pokemonJson, true);
            $url = $urlExtractor($pokemonData);

            if ($url === null) {
                $missing++;
            } else {
                $data = fetch_cached($cacheCategory, (string)$id, $url, 'png');
                if ($data === null) {
                    echo "  WARN: Failed to download {$label} for #{$id}\n";
                    $missing++;
                } else {
                    $fetched++;
                }
            }
        }

        if ($id % 50 === 0 || $id === $totalSpecies) {
            echo "  {$label}: {$id}/{$totalSpecies} (fetched: {$fetched}, cached: {$skipped}, missing: {$missing})\n";
        }
    }
    echo "\n";
    return ['fetched' => $fetched, 'cached' => $skipped, 'missing' => $missing];
}

// ─── Main ───────────────────────────────────────────────────────────

function main(): void {
    echo "=== PokeAPI Fetcher ===\n\n";

    // Ensure cache directories exist
    foreach (['pokemon', 'species', 'types', 'moves', 'move-damage-class', 'evolution-chains',
              'sprites', 'sprites-artwork', 'sprites-shiny', 'sprites-back', 'sprites-female',
              'abilities', 'items', 'sprites-items'] as $dir) {
        $path = CACHE_DIR . '/' . $dir;
        if (!is_dir($path)) mkdir($path, 0755, true);
    }

    // Step 1: Determine total Pokemon count
    echo "Checking total Pokemon species count...\n";
    $countData = fetch_json(BASE_URL . '/pokemon-species?limit=1');
    if ($countData === null) {
        echo "ERROR: Could not reach PokeAPI. Check your connection.\n";
        exit(1);
    }
    $totalSpecies = $countData['count'];
    echo "Total species: {$totalSpecies}\n\n";

    // Step 2: Fetch all Pokemon data
    echo "--- Fetching Pokemon data ---\n";
    $fetchedPokemon = 0;
    $skippedPokemon = 0;
    for ($id = 1; $id <= $totalSpecies; $id++) {
        if (is_cached('pokemon', (string)$id)) {
            $skippedPokemon++;
        } else {
            $data = fetch_json_cached('pokemon', (string)$id, BASE_URL . "/pokemon/{$id}");
            if ($data === null) {
                echo "  WARN: Failed to fetch pokemon/{$id}, skipping\n";
            }
            $fetchedPokemon++;
        }

        // Progress every 50
        if ($id % 50 === 0 || $id === $totalSpecies) {
            echo "  Pokemon: {$id}/{$totalSpecies} (fetched: {$fetchedPokemon}, cached: {$skippedPokemon})\n";
        }
    }
    echo "\n";

    // Step 3: Fetch all Species data
    echo "--- Fetching Species data ---\n";
    $fetchedSpecies = 0;
    $skippedSpecies = 0;
    $evolutionChainUrls = [];
    for ($id = 1; $id <= $totalSpecies; $id++) {
        $speciesData = fetch_json_cached('species', (string)$id, BASE_URL . "/pokemon-species/{$id}");
        if ($speciesData === null) {
            echo "  WARN: Failed to fetch species/{$id}, skipping\n";
        } else {
            // Collect evolution chain URLs
            if (isset($speciesData['evolution_chain']['url'])) {
                $chainUrl = $speciesData['evolution_chain']['url'];
                // Extract chain ID from URL like https://pokeapi.co/api/v2/evolution-chain/1/
                if (preg_match('/evolution-chain\/(\d+)/', $chainUrl, $m)) {
                    $evolutionChainUrls[$m[1]] = $chainUrl;
                }
            }
            if (is_cached('species', (string)$id)) {
                $skippedSpecies++;
            } else {
                $fetchedSpecies++;
            }
        }

        if ($id % 50 === 0 || $id === $totalSpecies) {
            echo "  Species: {$id}/{$totalSpecies}\n";
        }
    }
    echo "  Unique evolution chains found: " . count($evolutionChainUrls) . "\n\n";

    // Step 4: Fetch all Type data (1-18)
    echo "--- Fetching Type data ---\n";
    for ($id = 1; $id <= 18; $id++) {
        $typeData = fetch_json_cached('types', (string)$id, BASE_URL . "/type/{$id}");
        if ($typeData === null) {
            echo "  WARN: Failed to fetch type/{$id}\n";
        } else {
            $name = $typeData['name'] ?? '?';
            if (!is_cached('types', (string)$id)) {
                echo "  Fetched type {$id}: {$name}\n";
            } else {
                echo "  Cached type {$id}: {$name}\n";
            }
        }
    }
    echo "\n";

    // Step 5: Fetch all Move data
    // Move IDs are NOT sequential (1-919, then 10001-10018), so we fetch
    // the full list from the API first to discover actual IDs.
    echo "Fetching move list to discover IDs...\n";
    $moveListData = fetch_json(BASE_URL . '/move?limit=10000');
    $totalMoves = $moveListData['count'] ?? 0;
    $moveIds = [];
    foreach (($moveListData['results'] ?? []) as $entry) {
        // Extract ID from URL like "https://pokeapi.co/api/v2/move/10001/"
        if (preg_match('/\/move\/(\d+)\/?$/', $entry['url'], $m)) {
            $moveIds[] = (int)$m[1];
        }
    }
    sort($moveIds);
    echo "Total moves: {$totalMoves} (IDs discovered: " . count($moveIds) . ")\n\n";

    echo "--- Fetching Move data ---\n";
    $fetchedMoves = 0;
    $skippedMoves = 0;
    $processedMoves = 0;
    foreach ($moveIds as $id) {
        $processedMoves++;
        if (is_cached('moves', (string)$id)) {
            $skippedMoves++;
        } else {
            $data = fetch_json_cached('moves', (string)$id, BASE_URL . "/move/{$id}");
            if ($data === null) {
                echo "  WARN: Failed to fetch move/{$id}, skipping\n";
            }
            $fetchedMoves++;
        }

        if ($processedMoves % 100 === 0 || $processedMoves === count($moveIds)) {
            echo "  Moves: {$processedMoves}/" . count($moveIds) . " (fetched: {$fetchedMoves}, cached: {$skippedMoves})\n";
        }
    }
    echo "\n";

    // Step 6: Fetch move damage classes (physical, special, status)
    echo "--- Fetching Move Damage Classes ---\n";
    for ($id = 1; $id <= 3; $id++) {
        $classData = fetch_json_cached('move-damage-class', (string)$id, BASE_URL . "/move-damage-class/{$id}");
        if ($classData === null) {
            echo "  WARN: Failed to fetch move-damage-class/{$id}\n";
        } else {
            $name = $classData['name'] ?? '?';
            echo "  {$id}: {$name}\n";
        }
    }
    echo "\n";

    // Step 7: Fetch evolution chains
    echo "--- Fetching Evolution Chains ---\n";
    $totalChains = count($evolutionChainUrls);
    $chainCount = 0;
    foreach ($evolutionChainUrls as $chainId => $chainUrl) {
        $chainCount++;
        $chainData = fetch_json_cached('evolution-chains', (string)$chainId, $chainUrl);
        if ($chainData === null) {
            echo "  WARN: Failed to fetch evolution-chain/{$chainId}\n";
        }
        if ($chainCount % 50 === 0 || $chainCount === $totalChains) {
            echo "  Chains: {$chainCount}/{$totalChains}\n";
        }
    }
    echo "\n";

    // Step 8: Download all sprite variants
    $spriteStats = download_sprite_variant('sprites', 'Front Sprites', $totalSpecies,
        fn($data) => $data['sprites']['front_default'] ?? null);

    $artworkStats = download_sprite_variant('sprites-artwork', 'Official Artwork', $totalSpecies,
        fn($data) => $data['sprites']['other']['official-artwork']['front_default'] ?? null);

    $shinyStats = download_sprite_variant('sprites-shiny', 'Shiny Sprites', $totalSpecies,
        fn($data) => $data['sprites']['front_shiny'] ?? null);

    $backStats = download_sprite_variant('sprites-back', 'Back Sprites', $totalSpecies,
        fn($data) => $data['sprites']['back_default'] ?? null);

    $femaleStats = download_sprite_variant('sprites-female', 'Female Sprites', $totalSpecies,
        fn($data) => $data['sprites']['front_female'] ?? null);

    // Step 9: Fetch all Ability data
    echo "Fetching ability list to discover IDs...\n";
    $abilityListData = fetch_json(BASE_URL . '/ability?limit=10000');
    $totalAbilities = $abilityListData['count'] ?? 0;
    $abilityIds = [];
    foreach (($abilityListData['results'] ?? []) as $entry) {
        if (preg_match('/\/ability\/(\d+)\/?$/', $entry['url'], $m)) {
            $abilityIds[] = (int)$m[1];
        }
    }
    sort($abilityIds);
    echo "Total abilities: {$totalAbilities} (IDs discovered: " . count($abilityIds) . ")\n\n";

    echo "--- Fetching Ability data ---\n";
    $fetchedAbilities = 0;
    $skippedAbilities = 0;
    $processedAbilities = 0;
    foreach ($abilityIds as $id) {
        $processedAbilities++;
        if (is_cached('abilities', (string)$id)) {
            $skippedAbilities++;
        } else {
            $data = fetch_json_cached('abilities', (string)$id, BASE_URL . "/ability/{$id}");
            if ($data === null) {
                echo "  WARN: Failed to fetch ability/{$id}, skipping\n";
            }
            $fetchedAbilities++;
        }

        if ($processedAbilities % 50 === 0 || $processedAbilities === count($abilityIds)) {
            echo "  Abilities: {$processedAbilities}/" . count($abilityIds) . " (fetched: {$fetchedAbilities}, cached: {$skippedAbilities})\n";
        }
    }
    echo "\n";

    // Step 10: Fetch all Item data
    echo "Fetching item list to discover IDs...\n";
    $itemListData = fetch_json(BASE_URL . '/item?limit=10000');
    $totalItems = $itemListData['count'] ?? 0;
    $itemIds = [];
    $itemNames = []; // id → name, needed for sprite downloads
    foreach (($itemListData['results'] ?? []) as $entry) {
        if (preg_match('/\/item\/(\d+)\/?$/', $entry['url'], $m)) {
            $id = (int)$m[1];
            $itemIds[] = $id;
            $itemNames[$id] = $entry['name'];
        }
    }
    sort($itemIds);
    echo "Total items: {$totalItems} (IDs discovered: " . count($itemIds) . ")\n\n";

    echo "--- Fetching Item data ---\n";
    $fetchedItems = 0;
    $skippedItems = 0;
    $processedItems = 0;
    foreach ($itemIds as $id) {
        $processedItems++;
        if (is_cached('items', (string)$id)) {
            $skippedItems++;
        } else {
            $data = fetch_json_cached('items', (string)$id, BASE_URL . "/item/{$id}");
            if ($data === null) {
                echo "  WARN: Failed to fetch item/{$id}, skipping\n";
            }
            $fetchedItems++;
        }

        if ($processedItems % 100 === 0 || $processedItems === count($itemIds)) {
            echo "  Items: {$processedItems}/" . count($itemIds) . " (fetched: {$fetchedItems}, cached: {$skippedItems})\n";
        }
    }
    echo "\n";

    // Step 11: Download Item Sprites
    echo "--- Downloading Item Sprites ---\n";
    $itemSpritesFetched = 0;
    $itemSpritesCached = 0;
    $itemSpritesMissing = 0;
    $processedItemSprites = 0;
    foreach ($itemIds as $id) {
        $processedItemSprites++;
        $name = $itemNames[$id] ?? null;
        if ($name === null) {
            $itemSpritesMissing++;
        } elseif (is_cached('sprites-items', $name, 'png')) {
            $itemSpritesCached++;
        } else {
            $url = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/{$name}.png";
            $data = fetch_cached('sprites-items', $name, $url, 'png');
            if ($data === null) {
                $itemSpritesMissing++;
            } else {
                $itemSpritesFetched++;
            }
        }

        if ($processedItemSprites % 200 === 0 || $processedItemSprites === count($itemIds)) {
            echo "  Item Sprites: {$processedItemSprites}/" . count($itemIds) . " (fetched: {$itemSpritesFetched}, cached: {$itemSpritesCached}, missing: {$itemSpritesMissing})\n";
        }
    }
    echo "\n";

    // Summary
    echo "=== Fetch Complete ===\n";
    echo "  Pokemon:   {$totalSpecies} entries\n";
    echo "  Species:   {$totalSpecies} entries\n";
    echo "  Types:     18 entries\n";
    echo "  Moves:     {$totalMoves} entries\n";
    echo "  Chains:    {$totalChains} entries\n";
    $spriteTotal = $spriteStats['fetched'] + $spriteStats['cached'];
    echo "  Sprites:        {$spriteTotal} downloaded, {$spriteStats['missing']} missing\n";
    $artworkTotal = $artworkStats['fetched'] + $artworkStats['cached'];
    echo "  Artwork:        {$artworkTotal} downloaded, {$artworkStats['missing']} missing\n";
    $shinyTotal = $shinyStats['fetched'] + $shinyStats['cached'];
    echo "  Shiny:          {$shinyTotal} downloaded, {$shinyStats['missing']} missing\n";
    $backTotal = $backStats['fetched'] + $backStats['cached'];
    echo "  Back:           {$backTotal} downloaded, {$backStats['missing']} missing\n";
    $femaleTotal = $femaleStats['fetched'] + $femaleStats['cached'];
    echo "  Female:         {$femaleTotal} downloaded, {$femaleStats['missing']} missing\n";
    echo "  Abilities: {$totalAbilities} entries\n";
    echo "  Items:     {$totalItems} entries\n";
    $itemSpritesTotal = $itemSpritesFetched + $itemSpritesCached;
    echo "  Item Sprites:   {$itemSpritesTotal} downloaded, {$itemSpritesMissing} missing\n";
    echo "  Cache dir: " . realpath(CACHE_DIR) . "\n\n";
    echo "Next step: php tools/process.php\n";
}

main();
