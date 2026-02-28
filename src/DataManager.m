#import "DataManager.h"
#import "Pokemon.h"
#import "Move.h"

@interface DataManager ()
@property (nonatomic, strong) NSArray *pokemonIndex;
@property (nonatomic, strong) NSArray *movesIndex;
@property (nonatomic, strong) NSMutableDictionary *pokemonDetailCache;
@property (nonatomic, strong) NSMutableDictionary *moveDetailCache;
@property (nonatomic, strong) NSDictionary *pokemonNameLookup;
@property (nonatomic, strong) NSCache *spriteCache;
@end

@implementation DataManager

+ (instancetype)sharedManager {
    static DataManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DataManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pokemonDetailCache = [[NSMutableDictionary alloc] init];
        _moveDetailCache = [[NSMutableDictionary alloc] init];
        _spriteCache = [[NSCache alloc] init];
        _spriteCache.countLimit = 400;
    }
    return self;
}

#pragma mark - Pokemon Index

- (NSArray *)allPokemonSummaries {
    if (!_pokemonIndex) {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        NSString *path = [[NSBundle mainBundle] pathForResource:@"index"
                                                        ofType:@"plist"
                                                   inDirectory:@"data"];
        if (path) {
            _pokemonIndex = [NSArray arrayWithContentsOfFile:path];
        }
        if (!_pokemonIndex) {
            NSLog(@"WARNING: Could not load index.plist");
            _pokemonIndex = @[];
        } else {
            NSLog(@"[PERF] DataManager loadPokemonIndex: %.1fms (%lu entries)",
                  (CFAbsoluteTimeGetCurrent() - start) * 1000,
                  (unsigned long)_pokemonIndex.count);
        }
    }
    return _pokemonIndex;
}

- (NSUInteger)totalPokemonCount {
    return [self allPokemonSummaries].count;
}

- (NSArray *)searchPokemonWithName:(NSString *)query {
    return [self searchPokemonWithQuery:query types:nil generations:nil
                             categories:nil sortBy:@"number"];
}

- (NSArray *)searchPokemonWithQuery:(NSString *)query
                              types:(NSSet *)types
                        generations:(NSSet *)generations
                         categories:(NSSet *)categories
                             sortBy:(NSString *)sortBy {
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    NSArray *results = [self allPokemonSummaries];

    // Filter by types (OR within group)
    if (types.count > 0) {
        results = [results filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(NSDictionary *entry, NSDictionary *bindings) {
                NSArray *entryTypes = entry[@"types"];
                for (NSString *t in entryTypes) {
                    if ([types containsObject:t]) return YES;
                }
                return NO;
            }]];
    }

    // Filter by generations (OR within group)
    if (generations.count > 0) {
        results = [results filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(NSDictionary *entry, NSDictionary *bindings) {
                return [generations containsObject:entry[@"generation"]];
            }]];
    }

    // Filter by categories (OR within group): legendary, mythical, baby
    if (categories.count > 0) {
        results = [results filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(NSDictionary *entry, NSDictionary *bindings) {
                if ([categories containsObject:@"legendary"] &&
                    [entry[@"is_legendary"] boolValue]) return YES;
                if ([categories containsObject:@"mythical"] &&
                    [entry[@"is_mythical"] boolValue]) return YES;
                if ([categories containsObject:@"baby"] &&
                    [entry[@"is_baby"] boolValue]) return YES;
                return NO;
            }]];
    }

    // Search query: match name (substring) OR Pokedex number (prefix)
    if (query.length > 0) {
        NSString *lowerQuery = [query lowercaseString];
        results = [results filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(NSDictionary *entry, NSDictionary *bindings) {
                // Name match
                NSString *name = [entry[@"name"] lowercaseString];
                if ([name rangeOfString:lowerQuery].location != NSNotFound) return YES;

                // Number match: "25" matches #25, "025" matches #25
                NSInteger entryID = [entry[@"id"] integerValue];
                NSString *rawNumber = [NSString stringWithFormat:@"%ld", (long)entryID];
                NSString *paddedNumber = [NSString stringWithFormat:@"%03ld", (long)entryID];
                if ([rawNumber hasPrefix:lowerQuery] ||
                    [paddedNumber hasPrefix:lowerQuery]) return YES;

                return NO;
            }]];
    }

    // Sort
    if ([sortBy isEqualToString:@"name"]) {
        results = [results sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [a[@"name"] compare:b[@"name"] options:NSCaseInsensitiveSearch];
        }];
    } else if ([sortBy isEqualToString:@"stat_total"]) {
        results = [results sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [b[@"stat_total"] compare:a[@"stat_total"]]; // Descending
        }];
    }
    // Default "number" sort is already in plist order (by id)

    NSLog(@"[PERF] searchPokemon: %.1fms (query=%@, types=%lu, gens=%lu, cats=%lu, sort=%@, results=%lu)",
          (CFAbsoluteTimeGetCurrent() - start) * 1000,
          query ?: @"nil", (unsigned long)types.count,
          (unsigned long)generations.count, (unsigned long)categories.count,
          sortBy, (unsigned long)results.count);
    return results;
}

#pragma mark - Pokemon Detail

- (Pokemon *)pokemonDetailWithID:(NSInteger)pokemonID {
    NSNumber *key = @(pokemonID);
    Pokemon *cached = _pokemonDetailCache[key];
    if (cached) {
        NSLog(@"[PERF] DataManager pokemonDetail #%ld: cache hit", (long)pokemonID);
        return cached;
    }

    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    NSString *filename = [NSString stringWithFormat:@"%ld", (long)pokemonID];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename
                                                    ofType:@"plist"
                                               inDirectory:@"data/pokemon"];
    if (!path) return nil;

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!dict) return nil;

    Pokemon *pokemon = [Pokemon pokemonFromDictionary:dict];
    _pokemonDetailCache[key] = pokemon;
    NSLog(@"[PERF] DataManager pokemonDetail #%ld: %.1fms (plist load + parse)",
          (long)pokemonID, (CFAbsoluteTimeGetCurrent() - start) * 1000);
    return pokemon;
}

#pragma mark - Moves Index

- (NSArray *)allMoveSummaries {
    if (!_movesIndex) {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        NSString *path = [[NSBundle mainBundle] pathForResource:@"index"
                                                        ofType:@"plist"
                                                   inDirectory:@"data/moves"];
        if (path) {
            _movesIndex = [NSArray arrayWithContentsOfFile:path];
        }
        if (!_movesIndex) {
            NSLog(@"WARNING: Could not load moves/index.plist");
            _movesIndex = @[];
        } else {
            NSLog(@"[PERF] DataManager loadMovesIndex: %.1fms (%lu entries)",
                  (CFAbsoluteTimeGetCurrent() - start) * 1000,
                  (unsigned long)_movesIndex.count);
        }
    }
    return _movesIndex;
}

- (NSUInteger)totalMoveCount {
    return [self allMoveSummaries].count;
}

- (NSArray *)searchMovesWithName:(NSString *)query {
    return [self searchMovesWithQuery:query types:nil generations:nil
                        damageClasses:nil sortBy:@"number"];
}

- (NSArray *)searchMovesWithQuery:(NSString *)query
                            types:(NSSet *)types
                      generations:(NSSet *)generations
                    damageClasses:(NSSet *)damageClasses
                           sortBy:(NSString *)sortBy {
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    NSArray *results = [self allMoveSummaries];

    // Filter by types (OR within group)
    if (types.count > 0) {
        results = [results filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(NSDictionary *entry, NSDictionary *bindings) {
                return [types containsObject:entry[@"type"]];
            }]];
    }

    // Filter by generations (OR within group)
    if (generations.count > 0) {
        results = [results filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(NSDictionary *entry, NSDictionary *bindings) {
                return [generations containsObject:entry[@"generation"]];
            }]];
    }

    // Filter by damage classes (OR within group)
    if (damageClasses.count > 0) {
        results = [results filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(NSDictionary *entry, NSDictionary *bindings) {
                return [damageClasses containsObject:entry[@"damage_class"]];
            }]];
    }

    // Search query: match name (substring, case-insensitive)
    if (query.length > 0) {
        NSString *lowerQuery = [query lowercaseString];
        results = [results filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(NSDictionary *entry, NSDictionary *bindings) {
                NSString *name = [entry[@"name"] lowercaseString];
                return [name rangeOfString:lowerQuery].location != NSNotFound;
            }]];
    }

    // Sort
    if ([sortBy isEqualToString:@"name"]) {
        results = [results sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [a[@"name"] compare:b[@"name"] options:NSCaseInsensitiveSearch];
        }];
    } else if ([sortBy isEqualToString:@"power"]) {
        results = [results sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            // Nil/null power goes to end
            NSInteger pa = [a[@"power"] isKindOfClass:[NSNumber class]] ? [a[@"power"] integerValue] : 0;
            NSInteger pb = [b[@"power"] isKindOfClass:[NSNumber class]] ? [b[@"power"] integerValue] : 0;
            if (pa == 0 && pb == 0) return NSOrderedSame;
            if (pa == 0) return NSOrderedDescending;
            if (pb == 0) return NSOrderedAscending;
            if (pb > pa) return NSOrderedDescending;
            if (pb < pa) return NSOrderedAscending;
            return NSOrderedSame;
        }];
    }
    // Default "number" sort is already in plist order (by id)

    NSLog(@"[PERF] searchMoves: %.1fms (query=%@, types=%lu, gens=%lu, dmgClass=%lu, sort=%@, results=%lu)",
          (CFAbsoluteTimeGetCurrent() - start) * 1000,
          query ?: @"nil", (unsigned long)types.count,
          (unsigned long)generations.count, (unsigned long)damageClasses.count,
          sortBy, (unsigned long)results.count);
    return results;
}

#pragma mark - Move Detail

- (Move *)moveDetailWithID:(NSInteger)moveID {
    NSNumber *key = @(moveID);
    Move *cached = _moveDetailCache[key];
    if (cached) {
        NSLog(@"[PERF] DataManager moveDetail #%ld: cache hit", (long)moveID);
        return cached;
    }

    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    NSString *filename = [NSString stringWithFormat:@"%ld", (long)moveID];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename
                                                    ofType:@"plist"
                                               inDirectory:@"data/moves"];
    if (!path) return nil;

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!dict) return nil;

    Move *move = [Move moveFromDictionary:dict];
    _moveDetailCache[key] = move;
    NSLog(@"[PERF] DataManager moveDetail #%ld: %.1fms (plist load + parse)",
          (long)moveID, (CFAbsoluteTimeGetCurrent() - start) * 1000);
    return move;
}

#pragma mark - Pokemon Name Lookup

- (NSString *)pokemonNameForID:(NSInteger)pokemonID {
    if (!_pokemonNameLookup) {
        NSMutableDictionary *lookup = [[NSMutableDictionary alloc] init];
        for (NSDictionary *summary in [self allPokemonSummaries]) {
            NSNumber *pid = summary[@"id"];
            NSString *name = summary[@"name"];
            if (pid && name) {
                lookup[pid] = name;
            }
        }
        _pokemonNameLookup = [lookup copy];
    }
    return _pokemonNameLookup[@(pokemonID)] ?: @"???";
}

#pragma mark - Sprite Cache

- (UIImage *)spriteForPokemonID:(NSInteger)pokemonID {
    return [self spriteForPokemonID:pokemonID directory:@"sprites"];
}

- (UIImage *)artworkForPokemonID:(NSInteger)pokemonID {
    return [self spriteForPokemonID:pokemonID directory:@"sprites/artwork"];
}

- (UIImage *)shinySpriteForPokemonID:(NSInteger)pokemonID {
    return [self spriteForPokemonID:pokemonID directory:@"sprites/shiny"];
}

- (UIImage *)backSpriteForPokemonID:(NSInteger)pokemonID {
    return [self spriteForPokemonID:pokemonID directory:@"sprites/back"];
}

- (UIImage *)femaleSpriteForPokemonID:(NSInteger)pokemonID {
    return [self spriteForPokemonID:pokemonID directory:@"sprites/female"];
}

- (UIImage *)spriteForPokemonID:(NSInteger)pokemonID directory:(NSString *)directory {
    // Use composite cache key: "directory:id"
    NSString *key = [NSString stringWithFormat:@"%@:%ld", directory, (long)pokemonID];
    UIImage *cached = [_spriteCache objectForKey:key];
    if (cached) return cached;

    NSString *filename = [NSString stringWithFormat:@"%ld", (long)pokemonID];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename
                                                    ofType:@"png"
                                               inDirectory:directory];
    if (!path) return nil;

    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    if (image) {
        [_spriteCache setObject:image forKey:key];
    }
    return image;
}

@end
