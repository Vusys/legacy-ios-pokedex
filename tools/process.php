<?php
/**
 * process.php - Convert cached PokeAPI JSON into XML plist files for the iOS app.
 *
 * Reads from tools/.cache/ (populated by fetch.php).
 * Writes to src/data/ (plists) and src/sprites/ (PNGs).
 *
 * Output:
 *   src/data/index.plist         - Lightweight array of all Pokemon (id, name, types)
 *   src/data/types.plist         - Type metadata with colors and damage relations
 *   src/data/pokemon/{id}.plist  - Full detail per Pokemon
 *   src/data/moves/index.plist   - Lightweight array of all moves (id, name, type, power, etc.)
 *   src/data/moves/{id}.plist    - Full detail per move
 *   src/sprites/{id}.png         - Front-default sprites (copied from cache)
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
function flatten_evolution_chain(array $chainNode, array &$result = []): array {
    $speciesUrl = $chainNode['species']['url'] ?? '';
    $speciesId = null;
    if (preg_match('/pokemon-species\/(\d+)/', $speciesUrl, $m)) {
        $speciesId = (int)$m[1];
    }

    $entry = [
        'id' => $speciesId,
        'name' => title_case_name($chainNode['species']['name'] ?? ''),
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
            flatten_evolution_chain($evolution, $result);
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

// ─── Main Processing ────────────────────────────────────────────────

function main(): void {
    echo "=== Plist Processor ===\n\n";

    // Ensure output directories exist
    if (!is_dir(POKEMON_DIR)) mkdir(POKEMON_DIR, 0755, true);
    if (!is_dir(MOVES_DIR)) mkdir(MOVES_DIR, 0755, true);
    if (!is_dir(SPRITES_DST)) mkdir(SPRITES_DST, 0755, true);

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

        // Extract egg groups
        $eggGroups = [];
        foreach ($speciesData['egg_groups'] ?? [] as $eg) {
            $eggGroups[] = title_case_name($eg['name'] ?? '');
        }

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
            'moves' => $moves,
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

    // Copy sprites
    echo "Copying sprites...\n";
    $copiedSprites = 0;
    foreach ($speciesIds as $id) {
        $src = SPRITES_SRC . "/{$id}.png";
        $dst = SPRITES_DST . "/{$id}.png";
        if (file_exists($src)) {
            copy($src, $dst);
            $copiedSprites++;
        }
    }
    echo "  Copied {$copiedSprites} sprites.\n\n";

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

    echo "=== Processing Complete ===\n";
    echo "  Index:    " . DATA_DIR . "/index.plist ({$processed} Pokemon)\n";
    echo "  Types:    " . DATA_DIR . "/types.plist (" . count($typesData) . " types)\n";
    echo "  Pokemon:  " . POKEMON_DIR . "/ ({$processed} plists)\n";
    echo "  Moves:    " . MOVES_DIR . "/ ({$processedMoves} plists)\n";
    echo "  Sprites:  " . SPRITES_DST . "/ ({$copiedSprites} PNGs)\n";
}

main();
