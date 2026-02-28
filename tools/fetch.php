<?php
/**
 * fetch.php - Download all Pokemon data from PokeAPI with local caching.
 *
 * Downloads:
 *   - All Pokemon data (/api/v2/pokemon/{id})
 *   - All Species data (/api/v2/pokemon-species/{id})
 *   - All Type data (/api/v2/type/{id})
 *   - Evolution chains (discovered from species data)
 *   - Front-default sprite PNGs
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

// ─── Main ───────────────────────────────────────────────────────────

function main(): void {
    echo "=== PokeAPI Fetcher ===\n\n";

    // Ensure cache directories exist
    foreach (['pokemon', 'species', 'types', 'evolution-chains', 'sprites'] as $dir) {
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

    // Step 5: Fetch evolution chains
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

    // Step 6: Download sprites
    echo "--- Downloading Sprites ---\n";
    $fetchedSprites = 0;
    $skippedSprites = 0;
    $missingSprites = 0;
    for ($id = 1; $id <= $totalSpecies; $id++) {
        if (is_cached('sprites', (string)$id, 'png')) {
            $skippedSprites++;
        } else {
            // Read the pokemon cache to get the sprite URL
            $pokemonJson = read_cache('pokemon', (string)$id);
            if ($pokemonJson === null) {
                $missingSprites++;
                continue;
            }
            $pokemonData = json_decode($pokemonJson, true);
            $spriteUrl = $pokemonData['sprites']['front_default'] ?? null;

            if ($spriteUrl === null) {
                $missingSprites++;
                continue;
            }

            $spriteData = fetch_cached('sprites', (string)$id, $spriteUrl, 'png');
            if ($spriteData === null) {
                echo "  WARN: Failed to download sprite for #{$id}\n";
                $missingSprites++;
            } else {
                $fetchedSprites++;
            }
        }

        if ($id % 50 === 0 || $id === $totalSpecies) {
            echo "  Sprites: {$id}/{$totalSpecies} (fetched: {$fetchedSprites}, cached: {$skippedSprites}, missing: {$missingSprites})\n";
        }
    }
    echo "\n";

    // Summary
    echo "=== Fetch Complete ===\n";
    echo "  Pokemon:   {$totalSpecies} entries\n";
    echo "  Species:   {$totalSpecies} entries\n";
    echo "  Types:     18 entries\n";
    echo "  Chains:    {$totalChains} entries\n";
    echo "  Sprites:   " . ($fetchedSprites + $skippedSprites) . " downloaded, {$missingSprites} missing\n";
    echo "  Cache dir: " . realpath(CACHE_DIR) . "\n\n";
    echo "Next step: php tools/process.php\n";
}

main();
