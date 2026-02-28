<?php
/**
 * process.php - Convert cached PokeAPI JSON into XML plist files for the iOS app.
 *
 * Reads from tools/.cache/ (populated by fetch.php).
 * Writes to src/data/ (plists) and src/sprites/ (PNGs).
 *
 * Output:
 *   src/data/index.plist              - Lightweight array of all Pokemon (id, name, types)
 *   src/data/types.plist              - Type metadata with colors and damage relations
 *   src/data/pokemon/{id}.plist       - Full detail per Pokemon
 *   src/data/moves/index.plist        - Lightweight array of all moves (id, name, type, power, etc.)
 *   src/data/moves/{id}.plist         - Full detail per move
 *   src/data/abilities/index.plist    - Lightweight array of all abilities
 *   src/data/abilities/{id}.plist     - Full detail per ability
 *   src/data/items/index.plist        - Lightweight array of all items
 *   src/data/items/{id}.plist         - Full detail per item
 *   src/data/natures/index.plist      - All natures (single file with full data)
 *   src/data/egg-groups/index.plist   - Lightweight array of all egg groups
 *   src/data/egg-groups/{id}.plist    - Full detail per egg group
 *   src/data/berries/index.plist      - Lightweight array of all berries
 *   src/data/berries/{id}.plist       - Full detail per berry
 *   src/sprites/{id}.png              - Front-default sprites (copied from cache)
 *   src/sprites/items/{name}.png      - Item sprites (copied from cache)
 *   src/sprites/berries/{id}.png      - Berry sprites (copied from cache)
 *
 * Usage: php tools/process.php
 */

define('CACHE_DIR', __DIR__ . '/.cache');
define('SRC_DIR', __DIR__ . '/../src');
define('DATA_DIR', SRC_DIR . '/data');
define('POKEMON_DIR', DATA_DIR . '/pokemon');
define('MOVES_DIR', DATA_DIR . '/moves');
define('SPRITES_SRC', CACHE_DIR . '/sprites');
define('SPRITES_DST', SRC_DIR . '/sprites');
define('ARTWORK_SRC', CACHE_DIR . '/sprites-artwork');
define('ARTWORK_DST', SRC_DIR . '/sprites/artwork');
define('SHINY_SRC', CACHE_DIR . '/sprites-shiny');
define('SHINY_DST', SRC_DIR . '/sprites/shiny');
define('BACK_SRC', CACHE_DIR . '/sprites-back');
define('BACK_DST', SRC_DIR . '/sprites/back');
define('FEMALE_SRC', CACHE_DIR . '/sprites-female');
define('FEMALE_DST', SRC_DIR . '/sprites/female');
define('ABILITIES_DIR', DATA_DIR . '/abilities');
define('ITEMS_DIR', DATA_DIR . '/items');
define('ITEM_SPRITES_SRC', CACHE_DIR . '/sprites-items');
define('ITEM_SPRITES_DST', SRC_DIR . '/sprites/items');
define('NATURES_DIR', DATA_DIR . '/natures');
define('EGG_GROUPS_DIR', DATA_DIR . '/egg-groups');
define('BERRIES_DIR', DATA_DIR . '/berries');
define('BERRY_SPRITES_SRC', CACHE_DIR . '/sprites-berries');
define('BERRY_SPRITES_DST', SRC_DIR . '/sprites/berries');

// Standard community-agreed Pokemon type colors
define('TYPE_COLORS', [
    'normal'   => '#A8A878',
    'fire'     => '#F08030',
    'water'    => '#6890F0',
    'electric' => '#F8D030',
    'grass'    => '#78C850',
    'ice'      => '#98D8D8',
    'fighting' => '#C03028',
    'poison'   => '#A040A0',
    'ground'   => '#E0C068',
    'flying'   => '#A890F0',
    'psychic'  => '#F85888',
    'bug'      => '#A8B820',
    'rock'     => '#B8A038',
    'ghost'    => '#705898',
    'dragon'   => '#7038F8',
    'dark'     => '#705848',
    'steel'    => '#B8B8D0',
    'fairy'    => '#EE99AC',
]);

// ─── Plist Writer ───────────────────────────────────────────────────

function to_plist_xml($value, int $indent = 1): string {
    $pad = str_repeat("\t", $indent);
    $pad1 = str_repeat("\t", $indent + 1);

    if ($value === null) {
        return "{$pad}<string></string>\n";
    }
    if (is_bool($value)) {
        return $value ? "{$pad}<true/>\n" : "{$pad}<false/>\n";
    }
    if (is_int($value)) {
        return "{$pad}<integer>{$value}</integer>\n";
    }
    if (is_float($value)) {
        return "{$pad}<real>{$value}</real>\n";
    }
    if (is_string($value)) {
        $escaped = htmlspecialchars($value, ENT_XML1 | ENT_QUOTES, 'UTF-8');
        return "{$pad}<string>{$escaped}</string>\n";
    }
    if (is_array($value)) {
        // Check if it's an associative array (dict) or sequential (array)
        if (empty($value)) {
            if (array_is_list($value)) {
                return "{$pad}<array/>\n";
            }
            return "{$pad}<dict/>\n";
        }
        if (array_is_list($value)) {
            $xml = "{$pad}<array>\n";
            foreach ($value as $item) {
                $xml .= to_plist_xml($item, $indent + 1);
            }
            $xml .= "{$pad}</array>\n";
            return $xml;
        }
        // Associative array → dict
        $xml = "{$pad}<dict>\n";
        foreach ($value as $key => $val) {
            $escapedKey = htmlspecialchars((string)$key, ENT_XML1 | ENT_QUOTES, 'UTF-8');
            $xml .= "{$pad1}<key>{$escapedKey}</key>\n";
            $xml .= to_plist_xml($val, $indent + 1);
        }
        $xml .= "{$pad}</dict>\n";
        return $xml;
    }

    return "{$pad}<string>" . htmlspecialchars((string)$value, ENT_XML1 | ENT_QUOTES, 'UTF-8') . "</string>\n";
}

function write_plist(string $path, $data): void {
    $dir = dirname($path);
    if (!is_dir($dir)) mkdir($dir, 0755, true);

    $xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    $xml .= "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n";
    $xml .= "<plist version=\"1.0\">\n";
    $xml .= to_plist_xml($data, 0);
    $xml .= "</plist>\n";

    file_put_contents($path, $xml);
}

// ─── Data Transformation ───────────────────────────────────────────

function read_cached_json(string $category, string $key): ?array {
    $path = CACHE_DIR . "/{$category}/{$key}.json";
    if (!file_exists($path)) return null;
    $data = file_get_contents($path);
    return json_decode($data, true);
}

function title_case_name(string $name): string {
    // Handle special cases
    $specials = [
        'mr-mime' => 'Mr. Mime',
        'mr-rime' => 'Mr. Rime',
        'mime-jr' => 'Mime Jr.',
        'type-null' => 'Type: Null',
        'jangmo-o' => 'Jangmo-o',
        'hakamo-o' => 'Hakamo-o',
        'kommo-o' => 'Kommo-o',
        'tapu-koko' => 'Tapu Koko',
        'tapu-lele' => 'Tapu Lele',
        'tapu-bulu' => 'Tapu Bulu',
        'tapu-fini' => 'Tapu Fini',
        'ho-oh' => 'Ho-Oh',
        'porygon-z' => 'Porygon-Z',
        'nidoran-f' => 'Nidoran (F)',
        'nidoran-m' => 'Nidoran (M)',
        'farfetchd' => "Farfetch'd",
        'sirfetchd' => "Sirfetch'd",
        'wo-chien' => 'Wo-Chien',
        'chien-pao' => 'Chien-Pao',
        'ting-lu' => 'Ting-Lu',
        'chi-yu' => 'Chi-Yu',
        'flutter-mane' => 'Flutter Mane',
        'iron-hands' => 'Iron Hands',
        'iron-jugulis' => 'Iron Jugulis',
        'iron-moth' => 'Iron Moth',
        'iron-thorns' => 'Iron Thorns',
        'iron-bundle' => 'Iron Bundle',
        'iron-valiant' => 'Iron Valiant',
        'roaring-moon' => 'Roaring Moon',
        'great-tusk' => 'Great Tusk',
        'scream-tail' => 'Scream Tail',
        'brute-bonnet' => 'Brute Bonnet',
        'slither-wing' => 'Slither Wing',
        'sandy-shocks' => 'Sandy Shocks',
        'iron-treads' => 'Iron Treads',
        'iron-leaves' => 'Iron Leaves',
        'walking-wake' => 'Walking Wake',
        'iron-boulder' => 'Iron Boulder',
        'iron-crown' => 'Iron Crown',
        'raging-bolt' => 'Raging Bolt',
        'gouging-fire' => 'Gouging Fire',
        'terapagos' => 'Terapagos',
        'pecharunt' => 'Pecharunt',
    ];

    $lower = strtolower($name);
    if (isset($specials[$lower])) return $specials[$lower];

    // Default: capitalize first letter of each hyphenated segment
    return implode('-', array_map('ucfirst', explode('-', $lower)));
}

function clean_flavor_text(string $text): string {
    // PokeAPI flavor text has form-feed (\f), newlines, and weird whitespace
    $text = str_replace(["\f", "\n", "\r"], ' ', $text);
    $text = preg_replace('/\s+/', ' ', $text);
    return trim($text);
}

/**
 * Walk the evolution chain tree and flatten into an ordered array.
 */
function flatten_evolution_chain(array $chainNode, array &$result = [], ?int $parentId = null): array {
    $speciesUrl = $chainNode['species']['url'] ?? '';
    $speciesId = null;
    if (preg_match('/pokemon-species\/(\d+)/', $speciesUrl, $m)) {
        $speciesId = (int)$m[1];
    }

    $entry = [
        'id' => $speciesId,
        'name' => title_case_name($chainNode['species']['name'] ?? ''),
        'from_id' => $parentId,
    ];

    // Add evolution details if this isn't the base form
    if (!empty($chainNode['evolution_details'])) {
        $details = $chainNode['evolution_details'][0]; // Take first trigger
        $entry['trigger'] = $details['trigger']['name'] ?? null;
        $entry['min_level'] = $details['min_level'] ?? null;

        // Include item if it's an item-based evolution
        if (isset($details['item']['name'])) {
            $entry['item'] = title_case_name($details['item']['name']);
        }
        if (isset($details['held_item']['name'])) {
            $entry['held_item'] = title_case_name($details['held_item']['name']);
        }
        if (isset($details['known_move']['name'])) {
            $entry['known_move'] = title_case_name($details['known_move']['name']);
        }
        if (isset($details['known_move_type']['name'])) {
            $entry['known_move_type'] = title_case_name($details['known_move_type']['name']);
        }
        if (!empty($details['min_happiness'])) {
            $entry['min_happiness'] = $details['min_happiness'];
        }
        if (!empty($details['min_beauty'])) {
            $entry['min_beauty'] = $details['min_beauty'];
        }
        if (!empty($details['min_affection'])) {
            $entry['min_affection'] = $details['min_affection'];
        }
        if (!empty($details['time_of_day'])) {
            $entry['time_of_day'] = $details['time_of_day'];
        }
        if (!empty($details['needs_overworld_rain'])) {
            $entry['needs_overworld_rain'] = true;
        }
        if (!empty($details['turn_upside_down'])) {
            $entry['turn_upside_down'] = true;
        }
        if (isset($details['gender'])) {
            $entry['gender'] = $details['gender']; // 1=female, 2=male
        }
        if (isset($details['trade_species']['name'])) {
            $entry['trade_species'] = title_case_name($details['trade_species']['name']);
        }
    }

    $result[] = $entry;

    // Recurse into evolutions
    if (!empty($chainNode['evolves_to'])) {
        foreach ($chainNode['evolves_to'] as $evolution) {
            flatten_evolution_chain($evolution, $result, $speciesId);
        }
    }

    return $result;
}

/**
 * Get the first English flavor text, preferring earlier game versions.
 */
function get_english_flavor_text(array $entries): string {
    // Prefer earlier versions for classic feel
    $preferred = ['red', 'blue', 'yellow', 'gold', 'silver', 'crystal',
                  'ruby', 'sapphire', 'emerald', 'firered', 'leafgreen',
                  'diamond', 'pearl', 'platinum', 'heartgold', 'soulsilver',
                  'black', 'white', 'black-2', 'white-2',
                  'x', 'y', 'omega-ruby', 'alpha-sapphire',
                  'sun', 'moon', 'ultra-sun', 'ultra-moon',
                  'sword', 'shield', 'legends-arceus',
                  'scarlet', 'violet'];

    $englishEntries = array_filter($entries, fn($e) => ($e['language']['name'] ?? '') === 'en');

    // Try preferred versions first
    foreach ($preferred as $version) {
        foreach ($englishEntries as $entry) {
            if (($entry['version']['name'] ?? '') === $version) {
                return clean_flavor_text($entry['flavor_text']);
            }
        }
    }

    // Fall back to any English entry
    foreach ($englishEntries as $entry) {
        return clean_flavor_text($entry['flavor_text']);
    }

    return '';
}

/**
 * Get the English genus string (e.g., "Seed Pokemon").
 */
function get_english_genus(array $genera): string {
    foreach ($genera as $g) {
        if (($g['language']['name'] ?? '') === 'en') {
            return $g['genus'];
        }
    }
    return '';
}

/**
 * Get the English effect text for a move, with $effect_chance replaced.
 */
function get_english_effect(array $entries, ?int $effectChance): string {
    foreach ($entries as $e) {
        if (($e['language']['name'] ?? '') === 'en') {
            $text = $e['short_effect'] ?? $e['effect'] ?? '';
            if ($effectChance !== null) {
                $text = str_replace('$effect_chance', (string)$effectChance, $text);
            }
            return clean_flavor_text($text);
        }
    }
    return '';
}

/**
 * Get the first English flavor text for a move.
 */
function get_english_move_flavor(array $entries): string {
    // Same version preference as Pokemon flavor text
    $preferred = ['red-blue', 'yellow', 'gold-silver', 'crystal',
                  'ruby-sapphire', 'emerald', 'firered-leafgreen',
                  'diamond-pearl', 'platinum', 'heartgold-soulsilver',
                  'black-white', 'black-2-white-2',
                  'x-y', 'omega-ruby-alpha-sapphire',
                  'sun-moon', 'ultra-sun-ultra-moon',
                  'sword-shield', 'legends-arceus',
                  'scarlet-violet'];

    $englishEntries = array_filter($entries, fn($e) => ($e['language']['name'] ?? '') === 'en');

    foreach ($preferred as $vg) {
        foreach ($englishEntries as $entry) {
            if (($entry['version_group']['name'] ?? '') === $vg) {
                return clean_flavor_text($entry['flavor_text']);
            }
        }
    }

    foreach ($englishEntries as $entry) {
        return clean_flavor_text($entry['flavor_text']);
    }

    return '';
}

/**
 * Get the English name from a localized names array.
 */
function get_english_name(array $names, string $fallbackApiName): string {
    foreach ($names as $n) {
        if (($n['language']['name'] ?? '') === 'en') {
            return $n['name'];
        }
    }
    return title_case_name($fallbackApiName);
}

/**
 * Get the first English flavor text for an ability.
 * Abilities use 'flavor_text' field and 'version_group' key.
 */
function get_english_ability_flavor(array $entries): string {
    $preferred = ['red-blue', 'yellow', 'gold-silver', 'crystal',
                  'ruby-sapphire', 'emerald', 'firered-leafgreen',
                  'diamond-pearl', 'platinum', 'heartgold-soulsilver',
                  'black-white', 'black-2-white-2',
                  'x-y', 'omega-ruby-alpha-sapphire',
                  'sun-moon', 'ultra-sun-ultra-moon',
                  'sword-shield', 'legends-arceus',
                  'scarlet-violet'];

    $englishEntries = array_filter($entries, fn($e) => ($e['language']['name'] ?? '') === 'en');

    foreach ($preferred as $vg) {
        foreach ($englishEntries as $entry) {
            if (($entry['version_group']['name'] ?? '') === $vg) {
                return clean_flavor_text($entry['flavor_text']);
            }
        }
    }

    foreach ($englishEntries as $entry) {
        return clean_flavor_text($entry['flavor_text']);
    }

    return '';
}

/**
 * Get the first English flavor text for an item.
 * Items use 'text' field and 'version_group' key.
 */
function get_english_item_flavor(array $entries): string {
    $preferred = ['red-blue', 'yellow', 'gold-silver', 'crystal',
                  'ruby-sapphire', 'emerald', 'firered-leafgreen',
                  'diamond-pearl', 'platinum', 'heartgold-soulsilver',
                  'black-white', 'black-2-white-2',
                  'x-y', 'omega-ruby-alpha-sapphire',
                  'sun-moon', 'ultra-sun-ultra-moon',
                  'sword-shield', 'legends-arceus',
                  'scarlet-violet'];

    $englishEntries = array_filter($entries, fn($e) => ($e['language']['name'] ?? '') === 'en');

    foreach ($preferred as $vg) {
        foreach ($englishEntries as $entry) {
            if (($entry['version_group']['name'] ?? '') === $vg) {
                return clean_flavor_text($entry['text']);
            }
        }
    }

    foreach ($englishEntries as $entry) {
        return clean_flavor_text($entry['text']);
    }

    return '';
}

// ─── Main Processing ────────────────────────────────────────────────

function main(): void {
    echo "=== Plist Processor ===\n\n";

    // Ensure output directories exist
    if (!is_dir(POKEMON_DIR)) mkdir(POKEMON_DIR, 0755, true);
    if (!is_dir(MOVES_DIR)) mkdir(MOVES_DIR, 0755, true);
    if (!is_dir(SPRITES_DST)) mkdir(SPRITES_DST, 0755, true);
    if (!is_dir(ARTWORK_DST)) mkdir(ARTWORK_DST, 0755, true);
    if (!is_dir(SHINY_DST)) mkdir(SHINY_DST, 0755, true);
    if (!is_dir(BACK_DST)) mkdir(BACK_DST, 0755, true);
    if (!is_dir(FEMALE_DST)) mkdir(FEMALE_DST, 0755, true);
    if (!is_dir(ABILITIES_DIR)) mkdir(ABILITIES_DIR, 0755, true);
    if (!is_dir(ITEMS_DIR)) mkdir(ITEMS_DIR, 0755, true);
    if (!is_dir(ITEM_SPRITES_DST)) mkdir(ITEM_SPRITES_DST, 0755, true);
    if (!is_dir(NATURES_DIR)) mkdir(NATURES_DIR, 0755, true);
    if (!is_dir(EGG_GROUPS_DIR)) mkdir(EGG_GROUPS_DIR, 0755, true);
    if (!is_dir(BERRIES_DIR)) mkdir(BERRIES_DIR, 0755, true);
    if (!is_dir(BERRY_SPRITES_DST)) mkdir(BERRY_SPRITES_DST, 0755, true);

    // Determine how many species we have cached
    $speciesFiles = glob(CACHE_DIR . '/species/*.json');
    if (empty($speciesFiles)) {
        echo "ERROR: No cached species data found. Run fetch.php first.\n";
        exit(1);
    }

    // Extract IDs and sort
    $speciesIds = [];
    foreach ($speciesFiles as $f) {
        $id = (int)basename($f, '.json');
        if ($id > 0) $speciesIds[] = $id;
    }
    sort($speciesIds);
    $totalSpecies = count($speciesIds);
    echo "Found {$totalSpecies} cached species.\n\n";

    // Pre-load all evolution chains into a lookup by chain ID
    echo "Loading evolution chains...\n";
    $chainFiles = glob(CACHE_DIR . '/evolution-chains/*.json');
    $chains = [];
    foreach ($chainFiles as $f) {
        $chainId = (int)basename($f, '.json');
        $data = json_decode(file_get_contents($f), true);
        if ($data && isset($data['chain'])) {
            $chains[$chainId] = flatten_evolution_chain($data['chain']);
        }
    }
    echo "  Loaded " . count($chains) . " evolution chains.\n\n";

    // Pre-load move summary data for enriching Pokemon move lists
    echo "Building move lookup table...\n";
    $moveFiles = glob(CACHE_DIR . '/moves/*.json');
    $moveLookup = []; // keyed by move name (lowercase)
    $moveIds = [];
    foreach ($moveFiles as $f) {
        $moveId = (int)basename($f, '.json');
        if ($moveId <= 0) continue;
        $moveIds[] = $moveId;
        $moveJson = json_decode(file_get_contents($f), true);
        if (!$moveJson) continue;
        $moveName = $moveJson['name'] ?? '';
        $moveLookup[$moveName] = [
            'id' => $moveId,
            'type' => $moveJson['type']['name'] ?? '',
            'power' => $moveJson['power'],
            'accuracy' => $moveJson['accuracy'],
            'pp' => $moveJson['pp'],
            'damage_class' => $moveJson['damage_class']['name'] ?? '',
        ];
    }
    sort($moveIds);
    echo "  Loaded " . count($moveLookup) . " moves into lookup.\n\n";

    // Process each Pokemon
    echo "--- Processing Pokemon ---\n";
    $index = [];
    $processed = 0;
    $skipped = 0;

    foreach ($speciesIds as $id) {
        $pokemonData = read_cached_json('pokemon', (string)$id);
        $speciesData = read_cached_json('species', (string)$id);

        if ($pokemonData === null || $speciesData === null) {
            echo "  WARN: Missing data for #{$id}, skipping\n";
            $skipped++;
            continue;
        }

        $name = title_case_name($speciesData['name'] ?? "pokemon-{$id}");

        // Extract types
        $types = [];
        if (isset($pokemonData['types'])) {
            // Sort by slot to get primary type first
            $typeSlots = $pokemonData['types'];
            usort($typeSlots, fn($a, $b) => $a['slot'] - $b['slot']);
            foreach ($typeSlots as $t) {
                $types[] = $t['type']['name'];
            }
        }

        // Extract stats
        $stats = [];
        foreach ($pokemonData['stats'] ?? [] as $s) {
            $statName = $s['stat']['name'] ?? '';
            $stats[$statName] = $s['base_stat'] ?? 0;
        }

        // Extract abilities
        $abilities = [];
        foreach ($pokemonData['abilities'] ?? [] as $a) {
            $abilities[] = [
                'name' => title_case_name($a['ability']['name'] ?? ''),
                'is_hidden' => $a['is_hidden'] ?? false,
            ];
        }

        // Get evolution chain
        $evolutionChain = [];
        if (isset($speciesData['evolution_chain']['url'])) {
            if (preg_match('/evolution-chain\/(\d+)/', $speciesData['evolution_chain']['url'], $m)) {
                $evolutionChain = $chains[(int)$m[1]] ?? [];
            }
        }

        // Get flavor text and genus
        $flavorText = get_english_flavor_text($speciesData['flavor_text_entries'] ?? []);
        $genus = get_english_genus($speciesData['genera'] ?? []);

        // Extract moves (enriched with type/power/accuracy from move lookup)
        $moves = [];
        foreach ($pokemonData['moves'] ?? [] as $moveEntry) {
            $moveRawName = $moveEntry['move']['name'] ?? '';
            $moveName = title_case_name($moveRawName);
            $versionDetails = $moveEntry['version_group_details'] ?? [];
            if (empty($versionDetails)) continue;

            $detail = end($versionDetails);
            $moveInfo = $moveLookup[$moveRawName] ?? null;

            $moveData = [
                'name' => $moveName,
                'level' => $detail['level_learned_at'] ?? 0,
                'method' => $detail['move_learn_method']['name'] ?? 'unknown',
            ];

            // Enrich with move details if available
            if ($moveInfo) {
                $moveData['move_id'] = $moveInfo['id'];
                $moveData['type'] = $moveInfo['type'];
                $moveData['power'] = $moveInfo['power'];
                $moveData['accuracy'] = $moveInfo['accuracy'];
                $moveData['pp'] = $moveInfo['pp'];
                $moveData['damage_class'] = $moveInfo['damage_class'];
            }

            $moves[] = $moveData;
        }

        // Sort moves: level-up by level, then others alphabetically
        usort($moves, function ($a, $b) {
            if ($a['method'] === 'level-up' && $b['method'] === 'level-up') {
                return $a['level'] - $b['level'];
            }
            if ($a['method'] === 'level-up') return -1;
            if ($b['method'] === 'level-up') return 1;
            return strcmp($a['name'], $b['name']);
        });

        // Extract held items
        $heldItems = [];
        foreach ($pokemonData['held_items'] ?? [] as $hi) {
            $itemName = $hi['item']['name'] ?? '';
            if (!$itemName) continue;
            // Take max rarity across all version details
            $maxRarity = 0;
            foreach ($hi['version_details'] ?? [] as $vd) {
                $rarity = $vd['rarity'] ?? 0;
                if ($rarity > $maxRarity) $maxRarity = $rarity;
            }
            $heldItems[] = [
                'name' => title_case_name($itemName),
                'api_name' => $itemName,
                'rarity' => $maxRarity,
            ];
        }

        // Extract egg groups
        $eggGroups = [];
        foreach ($speciesData['egg_groups'] ?? [] as $eg) {
            $eggGroups[] = title_case_name($eg['name'] ?? '');
        }

        // Check for female sprite availability
        $hasFemaleSprite = file_exists(FEMALE_SRC . "/{$id}.png");

        // Build full detail plist data
        $detail = [
            'id' => $id,
            'name' => $name,
            'types' => $types,
            'stats' => $stats,
            'height' => $pokemonData['height'] ?? 0,
            'weight' => $pokemonData['weight'] ?? 0,
            'base_experience' => $pokemonData['base_experience'] ?? 0,
            'abilities' => $abilities,
            'flavor_text' => $flavorText,
            'genus' => $genus,
            'generation' => $speciesData['generation']['name'] ?? '',
            'habitat' => $speciesData['habitat']['name'] ?? '',
            'color' => $speciesData['color']['name'] ?? '',
            'shape' => $speciesData['shape']['name'] ?? '',
            'gender_rate' => $speciesData['gender_rate'] ?? -1,
            'capture_rate' => $speciesData['capture_rate'] ?? 0,
            'base_happiness' => $speciesData['base_happiness'] ?? 0,
            'hatch_counter' => $speciesData['hatch_counter'] ?? 0,
            'egg_groups' => $eggGroups,
            'evolution_chain' => $evolutionChain,
            'has_female_sprite' => $hasFemaleSprite,
            'moves' => $moves,
            'held_items' => $heldItems,
        ];

        // Write detail plist
        write_plist(POKEMON_DIR . "/{$id}.plist", $detail);

        // Compute stat total
        $statTotal = 0;
        foreach ($stats as $val) {
            $statTotal += $val;
        }

        // Add to index (lightweight)
        $index[] = [
            'id' => $id,
            'name' => $name,
            'types' => $types,
            'generation' => $speciesData['generation']['name'] ?? '',
            'stat_total' => $statTotal,
            'is_legendary' => $speciesData['is_legendary'] ?? false,
            'is_mythical' => $speciesData['is_mythical'] ?? false,
            'is_baby' => $speciesData['is_baby'] ?? false,
        ];

        $processed++;
        if ($processed % 50 === 0 || $processed === $totalSpecies) {
            echo "  Processed: {$processed}/{$totalSpecies}\n";
        }
    }
    echo "  Skipped: {$skipped}\n\n";

    // Write index plist
    echo "Writing index.plist ({$processed} entries)...\n";
    write_plist(DATA_DIR . '/index.plist', $index);

    // Process types
    echo "Processing types...\n";
    $typesData = [];
    for ($id = 1; $id <= 18; $id++) {
        $typeJson = read_cached_json('types', (string)$id);
        if ($typeJson === null) continue;

        $typeName = $typeJson['name'];
        $damageRelations = [];
        $dr = $typeJson['damage_relations'] ?? [];

        foreach (['double_damage_from', 'double_damage_to', 'half_damage_from',
                   'half_damage_to', 'no_damage_from', 'no_damage_to'] as $relation) {
            $names = [];
            foreach ($dr[$relation] ?? [] as $t) {
                $names[] = $t['name'];
            }
            $damageRelations[$relation] = $names;
        }

        $typesData[] = [
            'name' => $typeName,
            'color' => TYPE_COLORS[$typeName] ?? '#888888',
            'damage_relations' => $damageRelations,
        ];
    }
    write_plist(DATA_DIR . '/types.plist', $typesData);
    echo "  Wrote types.plist (" . count($typesData) . " types)\n\n";

    // Copy sprites (all variants)
    echo "Copying sprites...\n";
    $spriteCounts = ['front' => 0, 'artwork' => 0, 'shiny' => 0, 'back' => 0, 'female' => 0];
    foreach ($speciesIds as $id) {
        $filename = "{$id}.png";

        // Front (default)
        if (file_exists(SPRITES_SRC . "/{$filename}")) {
            copy(SPRITES_SRC . "/{$filename}", SPRITES_DST . "/{$filename}");
            $spriteCounts['front']++;
        }
        // Official artwork
        if (file_exists(ARTWORK_SRC . "/{$filename}")) {
            copy(ARTWORK_SRC . "/{$filename}", ARTWORK_DST . "/{$filename}");
            $spriteCounts['artwork']++;
        }
        // Shiny
        if (file_exists(SHINY_SRC . "/{$filename}")) {
            copy(SHINY_SRC . "/{$filename}", SHINY_DST . "/{$filename}");
            $spriteCounts['shiny']++;
        }
        // Back
        if (file_exists(BACK_SRC . "/{$filename}")) {
            copy(BACK_SRC . "/{$filename}", BACK_DST . "/{$filename}");
            $spriteCounts['back']++;
        }
        // Female
        if (file_exists(FEMALE_SRC . "/{$filename}")) {
            copy(FEMALE_SRC . "/{$filename}", FEMALE_DST . "/{$filename}");
            $spriteCounts['female']++;
        }
    }
    echo "  Front:   {$spriteCounts['front']}\n";
    echo "  Artwork: {$spriteCounts['artwork']}\n";
    echo "  Shiny:   {$spriteCounts['shiny']}\n";
    echo "  Back:    {$spriteCounts['back']}\n";
    echo "  Female:  {$spriteCounts['female']}\n\n";

    // Process moves
    echo "--- Processing Moves ---\n";
    $movesIndex = [];
    $processedMoves = 0;

    foreach ($moveIds as $moveId) {
        $moveJson = read_cached_json('moves', (string)$moveId);
        if ($moveJson === null) continue;

        $moveName = title_case_name($moveJson['name'] ?? '');
        $moveType = $moveJson['type']['name'] ?? '';
        $power = $moveJson['power'];
        $accuracy = $moveJson['accuracy'];
        $pp = $moveJson['pp'];
        $damageClass = $moveJson['damage_class']['name'] ?? '';
        $effectChance = $moveJson['effect_chance'] ?? null;
        $priority = $moveJson['priority'] ?? 0;
        $generation = $moveJson['generation']['name'] ?? '';

        // Effect description
        $effect = get_english_effect($moveJson['effect_entries'] ?? [], $effectChance);
        $flavorText = get_english_move_flavor($moveJson['flavor_text_entries'] ?? []);

        // Target
        $target = $moveJson['target']['name'] ?? '';

        // Meta (additional battle details)
        $meta = $moveJson['meta'] ?? null;
        $metaData = [];
        if ($meta) {
            if (isset($meta['ailment']['name']) && $meta['ailment']['name'] !== 'none') {
                $metaData['ailment'] = title_case_name($meta['ailment']['name']);
                $metaData['ailment_chance'] = $meta['ailment_chance'] ?? 0;
            }
            if (($meta['min_hits'] ?? null) !== null && ($meta['max_hits'] ?? null) !== null
                && ($meta['min_hits'] > 0 || $meta['max_hits'] > 0)) {
                $metaData['min_hits'] = $meta['min_hits'];
                $metaData['max_hits'] = $meta['max_hits'];
            }
            if (($meta['drain'] ?? 0) != 0) {
                $metaData['drain'] = $meta['drain'];
            }
            if (($meta['healing'] ?? 0) != 0) {
                $metaData['healing'] = $meta['healing'];
            }
            if (($meta['crit_rate'] ?? 0) != 0) {
                $metaData['crit_rate'] = $meta['crit_rate'];
            }
            if (($meta['flinch_chance'] ?? 0) != 0) {
                $metaData['flinch_chance'] = $meta['flinch_chance'];
            }
            if (($meta['stat_chance'] ?? 0) != 0) {
                $metaData['stat_chance'] = $meta['stat_chance'];
            }
        }

        // Stat changes
        $statChanges = [];
        foreach ($moveJson['stat_changes'] ?? [] as $sc) {
            $statChanges[] = [
                'stat' => $sc['stat']['name'] ?? '',
                'change' => $sc['change'] ?? 0,
            ];
        }

        // Which Pokemon learn this move
        $learnedBy = [];
        foreach ($moveJson['learned_by_pokemon'] ?? [] as $lbp) {
            $pokemonUrl = $lbp['url'] ?? '';
            if (preg_match('/pokemon\/(\d+)/', $pokemonUrl, $m)) {
                $learnedBy[] = (int)$m[1];
            }
        }
        sort($learnedBy);

        // Full move detail
        $moveDetail = [
            'id' => $moveId,
            'name' => $moveName,
            'type' => $moveType,
            'power' => $power,
            'accuracy' => $accuracy,
            'pp' => $pp,
            'damage_class' => $damageClass,
            'priority' => $priority,
            'generation' => $generation,
            'effect' => $effect,
            'flavor_text' => $flavorText,
            'target' => $target,
            'learned_by' => $learnedBy,
        ];
        if (!empty($metaData)) {
            $moveDetail['meta'] = $metaData;
        }
        if (!empty($statChanges)) {
            $moveDetail['stat_changes'] = $statChanges;
        }

        write_plist(MOVES_DIR . "/{$moveId}.plist", $moveDetail);

        // Lightweight index entry
        $movesIndex[] = [
            'id' => $moveId,
            'name' => $moveName,
            'type' => $moveType,
            'power' => $power,
            'accuracy' => $accuracy,
            'pp' => $pp,
            'damage_class' => $damageClass,
            'generation' => $generation,
        ];

        $processedMoves++;
        if ($processedMoves % 100 === 0 || $processedMoves === count($moveIds)) {
            echo "  Moves: {$processedMoves}/" . count($moveIds) . "\n";
        }
    }

    // Write moves index
    echo "Writing moves/index.plist ({$processedMoves} entries)...\n";
    write_plist(MOVES_DIR . '/index.plist', $movesIndex);
    echo "\n";

    // Process abilities
    echo "--- Processing Abilities ---\n";
    $abilityFiles = glob(CACHE_DIR . '/abilities/*.json');
    $abilityIds = [];
    foreach ($abilityFiles as $f) {
        $id = (int)basename($f, '.json');
        if ($id > 0) $abilityIds[] = $id;
    }
    sort($abilityIds);

    $abilitiesIndex = [];
    $processedAbilities = 0;

    foreach ($abilityIds as $abilityId) {
        $abilityJson = read_cached_json('abilities', (string)$abilityId);
        if ($abilityJson === null) continue;

        $apiName = $abilityJson['name'] ?? '';
        $name = get_english_name($abilityJson['names'] ?? [], $apiName);
        $generation = $abilityJson['generation']['name'] ?? '';
        $isMainSeries = $abilityJson['is_main_series'] ?? false;
        $effect = get_english_effect($abilityJson['effect_entries'] ?? [], null);
        $flavorText = get_english_ability_flavor($abilityJson['flavor_text_entries'] ?? []);

        // Pokemon with this ability
        $pokemon = [];
        foreach ($abilityJson['pokemon'] ?? [] as $p) {
            $pokemonUrl = $p['pokemon']['url'] ?? '';
            $pokemonId = null;
            if (preg_match('/\/pokemon\/(\d+)\/?$/', $pokemonUrl, $m)) {
                $pokemonId = (int)$m[1];
            }
            if ($pokemonId === null) continue;

            $pokemon[] = [
                'id' => $pokemonId,
                'name' => title_case_name($p['pokemon']['name'] ?? ''),
                'is_hidden' => $p['is_hidden'] ?? false,
                'slot' => $p['slot'] ?? 0,
            ];
        }
        usort($pokemon, fn($a, $b) => $a['id'] - $b['id']);

        // Detail plist
        $abilityDetail = [
            'id' => $abilityId,
            'name' => $name,
            'generation' => $generation,
            'is_main_series' => $isMainSeries,
            'effect' => $effect,
            'flavor_text' => $flavorText,
            'pokemon' => $pokemon,
        ];
        write_plist(ABILITIES_DIR . "/{$abilityId}.plist", $abilityDetail);

        // Index entry
        $abilitiesIndex[] = [
            'id' => $abilityId,
            'name' => $name,
            'generation' => $generation,
            'is_main_series' => $isMainSeries,
        ];

        $processedAbilities++;
        if ($processedAbilities % 50 === 0 || $processedAbilities === count($abilityIds)) {
            echo "  Abilities: {$processedAbilities}/" . count($abilityIds) . "\n";
        }
    }

    echo "Writing abilities/index.plist ({$processedAbilities} entries)...\n";
    write_plist(ABILITIES_DIR . '/index.plist', $abilitiesIndex);
    echo "\n";

    // Build machine lookup: item_id → {move_name, move_id, move_type}
    echo "Building machine lookup...\n";
    $machineLookup = []; // keyed by item_id
    $machineFiles = glob(CACHE_DIR . '/machines/*.json');
    foreach ($machineFiles as $mf) {
        $machineJson = json_decode(file_get_contents($mf), true);
        if (!$machineJson) continue;

        $itemUrl = $machineJson['item']['url'] ?? '';
        $moveUrl = $machineJson['move']['url'] ?? '';
        $itemId = null;
        $moveId = null;
        if (preg_match('/\/item\/(\d+)\/?$/', $itemUrl, $m)) {
            $itemId = (int)$m[1];
        }
        if (preg_match('/\/move\/(\d+)\/?$/', $moveUrl, $m)) {
            $moveId = (int)$m[1];
        }
        if ($itemId === null || $moveId === null) continue;

        $moveName = title_case_name($machineJson['move']['name'] ?? '');
        $moveRawName = $machineJson['move']['name'] ?? '';
        $moveType = '';
        if (isset($moveLookup[$moveRawName])) {
            $moveType = $moveLookup[$moveRawName]['type'];
        }

        // Prefer later version groups (higher machine IDs tend to be newer)
        $machineLookup[$itemId] = [
            'move_name' => $moveName,
            'move_id' => $moveId,
            'move_type' => $moveType,
        ];
    }
    echo "  Loaded " . count($machineLookup) . " machine→item mappings.\n\n";

    // Process items
    echo "--- Processing Items ---\n";
    $itemFiles = glob(CACHE_DIR . '/items/*.json');
    $itemCacheIds = [];
    foreach ($itemFiles as $f) {
        $id = (int)basename($f, '.json');
        if ($id > 0) $itemCacheIds[] = $id;
    }
    sort($itemCacheIds);

    $itemsIndex = [];
    $processedItemsCount = 0;
    $itemNameLookup = []; // id → api_name, for sprite copying

    foreach ($itemCacheIds as $itemId) {
        $itemJson = read_cached_json('items', (string)$itemId);
        if ($itemJson === null) continue;

        $apiName = $itemJson['name'] ?? '';
        $name = get_english_name($itemJson['names'] ?? [], $apiName);
        $category = $itemJson['category']['name'] ?? '';
        $cost = $itemJson['cost'] ?? 0;
        $effect = get_english_effect($itemJson['effect_entries'] ?? [], null);
        $flavorText = get_english_item_flavor($itemJson['flavor_text_entries'] ?? []);
        $hasSprite = file_exists(ITEM_SPRITES_SRC . "/{$apiName}.png");

        $itemNameLookup[$itemId] = $apiName;

        // Pokemon that hold this item
        $heldBy = [];
        foreach ($itemJson['held_by_pokemon'] ?? [] as $h) {
            $pokemonUrl = $h['pokemon']['url'] ?? '';
            $pokemonId = null;
            if (preg_match('/\/pokemon\/(\d+)\/?$/', $pokemonUrl, $m)) {
                $pokemonId = (int)$m[1];
            }
            if ($pokemonId === null) continue;

            $heldBy[] = [
                'id' => $pokemonId,
                'name' => title_case_name($h['pokemon']['name'] ?? ''),
            ];
        }
        usort($heldBy, fn($a, $b) => $a['id'] - $b['id']);

        // Detail plist
        $itemDetail = [
            'id' => $itemId,
            'name' => $name,
            'api_name' => $apiName,
            'category' => $category,
            'cost' => $cost,
            'effect' => $effect,
            'flavor_text' => $flavorText,
            'has_sprite' => $hasSprite,
            'held_by' => $heldBy,
        ];

        // Optional fields
        $flingPower = $itemJson['fling_power'] ?? null;
        if ($flingPower !== null) {
            $itemDetail['fling_power'] = $flingPower;
        }
        $flingEffect = $itemJson['fling_effect']['name'] ?? null;
        if ($flingEffect !== null) {
            $itemDetail['fling_effect'] = $flingEffect;
        }

        // Add teaches_move for TM/HM items
        if (isset($machineLookup[$itemId])) {
            $itemDetail['teaches_move'] = $machineLookup[$itemId];
        }

        write_plist(ITEMS_DIR . "/{$itemId}.plist", $itemDetail);

        // Index entry
        $itemsIndex[] = [
            'id' => $itemId,
            'name' => $name,
            'api_name' => $apiName,
            'category' => $category,
            'cost' => $cost,
            'has_sprite' => $hasSprite,
        ];

        $processedItemsCount++;
        if ($processedItemsCount % 100 === 0 || $processedItemsCount === count($itemCacheIds)) {
            echo "  Items: {$processedItemsCount}/" . count($itemCacheIds) . "\n";
        }
    }

    echo "Writing items/index.plist ({$processedItemsCount} entries)...\n";
    write_plist(ITEMS_DIR . '/index.plist', $itemsIndex);
    echo "\n";

    // Copy item sprites
    echo "Copying item sprites...\n";
    $itemSpritesCopied = 0;
    foreach ($itemNameLookup as $itemId => $apiName) {
        $src = ITEM_SPRITES_SRC . "/{$apiName}.png";
        if (file_exists($src)) {
            copy($src, ITEM_SPRITES_DST . "/{$apiName}.png");
            $itemSpritesCopied++;
        }
    }
    echo "  Item sprites: {$itemSpritesCopied}\n\n";

    // Process natures
    echo "--- Processing Natures ---\n";
    $natureFiles = glob(CACHE_DIR . '/natures/*.json');
    $natureIds = [];
    foreach ($natureFiles as $f) {
        $id = (int)basename($f, '.json');
        if ($id > 0) $natureIds[] = $id;
    }
    sort($natureIds);

    $naturesData = [];
    foreach ($natureIds as $natureId) {
        $natureJson = read_cached_json('natures', (string)$natureId);
        if (!$natureJson) continue;

        $name = get_english_name($natureJson['names'] ?? [], $natureJson['name'] ?? '');
        $increasedStat = $natureJson['increased_stat']['name'] ?? '';
        $decreasedStat = $natureJson['decreased_stat']['name'] ?? '';
        $likesFlavor = $natureJson['likes_flavor']['name'] ?? '';
        $hatesFlavor = $natureJson['hates_flavor']['name'] ?? '';
        $isNeutral = ($increasedStat === '' || $decreasedStat === ''
                       || $increasedStat === $decreasedStat);

        $naturesData[] = [
            'id' => $natureJson['id'],
            'name' => $name,
            'api_name' => $natureJson['name'] ?? '',
            'increased_stat' => $increasedStat,
            'decreased_stat' => $decreasedStat,
            'likes_flavor' => $likesFlavor,
            'hates_flavor' => $hatesFlavor,
            'is_neutral' => $isNeutral,
        ];
    }
    usort($naturesData, fn($a, $b) => $a['id'] - $b['id']);
    write_plist(NATURES_DIR . '/index.plist', $naturesData);
    echo "  Wrote natures/index.plist (" . count($naturesData) . " natures)\n\n";

    // Process egg groups
    echo "--- Processing Egg Groups ---\n";
    $eggGroupFiles = glob(CACHE_DIR . '/egg-groups/*.json');
    $eggGroupIds = [];
    foreach ($eggGroupFiles as $f) {
        $id = (int)basename($f, '.json');
        if ($id > 0) $eggGroupIds[] = $id;
    }
    sort($eggGroupIds);

    $eggGroupsIndex = [];
    foreach ($eggGroupIds as $egId) {
        $egJson = read_cached_json('egg-groups', (string)$egId);
        if (!$egJson) continue;

        $name = get_english_name($egJson['names'] ?? [], $egJson['name'] ?? '');

        // Extract pokemon species and resolve IDs
        $pokemonSpecies = [];
        foreach ($egJson['pokemon_species'] ?? [] as $sp) {
            $speciesUrl = $sp['url'] ?? '';
            $speciesId = null;
            if (preg_match('/pokemon-species\/(\d+)/', $speciesUrl, $m)) {
                $speciesId = (int)$m[1];
            }
            if ($speciesId !== null) {
                $pokemonSpecies[] = [
                    'id' => $speciesId,
                    'name' => title_case_name($sp['name'] ?? ''),
                ];
            }
        }
        usort($pokemonSpecies, fn($a, $b) => $a['id'] - $b['id']);

        // Detail plist
        $egDetail = [
            'id' => $egId,
            'name' => $name,
            'pokemon' => $pokemonSpecies,
        ];
        write_plist(EGG_GROUPS_DIR . "/{$egId}.plist", $egDetail);

        // Index entry
        $eggGroupsIndex[] = [
            'id' => $egId,
            'name' => $name,
            'pokemon_count' => count($pokemonSpecies),
        ];
    }
    write_plist(EGG_GROUPS_DIR . '/index.plist', $eggGroupsIndex);
    echo "  Wrote egg-groups/index.plist (" . count($eggGroupsIndex) . " groups)\n";
    echo "  Wrote " . count($eggGroupIds) . " detail plists\n\n";

    // Process berries
    echo "--- Processing Berries ---\n";
    $berryFiles = glob(CACHE_DIR . '/berries/*.json');
    $berryCacheIds = [];
    foreach ($berryFiles as $f) {
        $id = (int)basename($f, '.json');
        if ($id > 0) $berryCacheIds[] = $id;
    }
    sort($berryCacheIds);

    $berriesIndex = [];
    $processedBerriesCount = 0;

    foreach ($berryCacheIds as $berryId) {
        $berryJson = read_cached_json('berries', (string)$berryId);
        if (!$berryJson) continue;

        $apiName = $berryJson['name'] ?? '';
        $name = title_case_name($apiName) . ' Berry';
        $naturalGiftType = $berryJson['natural_gift_type']['name'] ?? '';
        $naturalGiftPower = $berryJson['natural_gift_power'] ?? 0;
        $firmness = $berryJson['firmness']['name'] ?? '';
        $growthTime = $berryJson['growth_time'] ?? 0;
        $maxHarvest = $berryJson['max_harvest'] ?? 0;
        $size = $berryJson['size'] ?? 0;
        $smoothness = $berryJson['smoothness'] ?? 0;
        $soilDryness = $berryJson['soil_dryness'] ?? 0;
        $hasSprite = file_exists(BERRY_SPRITES_SRC . "/{$berryId}.png");

        // Flavors
        $flavors = [];
        foreach ($berryJson['flavors'] ?? [] as $flavorEntry) {
            $flavorName = $flavorEntry['flavor']['name'] ?? '';
            $potency = $flavorEntry['potency'] ?? 0;
            if ($flavorName) {
                $flavors[$flavorName] = $potency;
            }
        }

        // Get effect from associated item
        $effect = '';
        $flavorText = '';
        $itemUrl = $berryJson['item']['url'] ?? '';
        if (preg_match('/\/item\/(\d+)/', $itemUrl, $m)) {
            $berryItemId = (int)$m[1];
            $itemJson = read_cached_json('items', (string)$berryItemId);
            if ($itemJson) {
                $effect = get_english_effect($itemJson['effect_entries'] ?? [], null);
                $flavorText = get_english_item_flavor($itemJson['flavor_text_entries'] ?? []);
            }
        }

        // Detail plist
        $berryDetail = [
            'id' => $berryId,
            'name' => $name,
            'api_name' => $apiName,
            'natural_gift_type' => $naturalGiftType,
            'natural_gift_power' => $naturalGiftPower,
            'firmness' => $firmness,
            'growth_time' => $growthTime,
            'max_harvest' => $maxHarvest,
            'size' => $size,
            'smoothness' => $smoothness,
            'soil_dryness' => $soilDryness,
            'has_sprite' => $hasSprite,
            'flavors' => $flavors,
            'effect' => $effect,
            'flavor_text' => $flavorText,
        ];
        write_plist(BERRIES_DIR . "/{$berryId}.plist", $berryDetail);

        // Index entry
        $berriesIndex[] = [
            'id' => $berryId,
            'name' => $name,
            'api_name' => $apiName,
            'natural_gift_type' => $naturalGiftType,
            'natural_gift_power' => $naturalGiftPower,
            'firmness' => $firmness,
            'has_sprite' => $hasSprite,
        ];

        $processedBerriesCount++;
    }

    write_plist(BERRIES_DIR . '/index.plist', $berriesIndex);
    echo "  Wrote berries/index.plist ({$processedBerriesCount} entries)\n";
    echo "  Wrote {$processedBerriesCount} detail plists\n\n";

    // Copy berry sprites
    echo "Copying berry sprites...\n";
    $berrySpritesCopied = 0;
    foreach ($berryCacheIds as $berryId) {
        $src = BERRY_SPRITES_SRC . "/{$berryId}.png";
        if (file_exists($src)) {
            copy($src, BERRY_SPRITES_DST . "/{$berryId}.png");
            $berrySpritesCopied++;
        }
    }
    echo "  Berry sprites: {$berrySpritesCopied}\n\n";

    echo "=== Processing Complete ===\n";
    echo "  Index:      " . DATA_DIR . "/index.plist ({$processed} Pokemon)\n";
    echo "  Types:      " . DATA_DIR . "/types.plist (" . count($typesData) . " types)\n";
    echo "  Pokemon:    " . POKEMON_DIR . "/ ({$processed} plists)\n";
    echo "  Moves:      " . MOVES_DIR . "/ ({$processedMoves} plists)\n";
    echo "  Abilities:  " . ABILITIES_DIR . "/ ({$processedAbilities} plists)\n";
    echo "  Items:      " . ITEMS_DIR . "/ ({$processedItemsCount} plists)\n";
    echo "  Sprites:    " . SPRITES_DST . "/ (front: {$spriteCounts['front']}, artwork: {$spriteCounts['artwork']}, shiny: {$spriteCounts['shiny']}, back: {$spriteCounts['back']}, female: {$spriteCounts['female']})\n";
    echo "  Item sprites: " . ITEM_SPRITES_DST . "/ ({$itemSpritesCopied} files)\n";
    echo "  Natures:    " . NATURES_DIR . "/ (" . count($naturesData) . " natures)\n";
    echo "  Egg Groups: " . EGG_GROUPS_DIR . "/ (" . count($eggGroupsIndex) . " groups)\n";
    echo "  Berries:    " . BERRIES_DIR . "/ ({$processedBerriesCount} plists)\n";
    echo "  Berry sprites: " . BERRY_SPRITES_DST . "/ ({$berrySpritesCopied} files)\n";
}

main();
