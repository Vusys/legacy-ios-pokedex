#import "DataManager.h"
#import "Pokemon.h"
#import "Move.h"

@interface DataManager ()
@property (nonatomic, strong) NSArray *pokemonIndex;
@property (nonatomic, strong) NSArray *movesIndex;
@property (nonatomic, strong) NSMutableDictionary *pokemonDetailCache;
@property (nonatomic, strong) NSMutableDictionary *moveDetailCache;
@property (nonatomic, strong) NSDictionary *pokemonNameLookup;
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
    }
    return self;
}

#pragma mark - Pokemon Index

- (NSArray *)allPokemonSummaries {
    if (!_pokemonIndex) {
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
            NSLog(@"Loaded %lu Pokemon from index.plist",
                  (unsigned long)_pokemonIndex.count);
        }
    }
    return _pokemonIndex;
}

- (NSUInteger)totalPokemonCount {
    return [self allPokemonSummaries].count;
}

- (NSArray *)searchPokemonWithName:(NSString *)query {
    if (!query || query.length == 0) return [self allPokemonSummaries];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:
        @"name CONTAINS[cd] %@", query];
    return [[self allPokemonSummaries] filteredArrayUsingPredicate:predicate];
}

#pragma mark - Pokemon Detail

- (Pokemon *)pokemonDetailWithID:(NSInteger)pokemonID {
    NSNumber *key = @(pokemonID);
    Pokemon *cached = _pokemonDetailCache[key];
    if (cached) return cached;

    NSString *filename = [NSString stringWithFormat:@"%ld", (long)pokemonID];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename
                                                    ofType:@"plist"
                                               inDirectory:@"data/pokemon"];
    if (!path) return nil;

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!dict) return nil;

    Pokemon *pokemon = [Pokemon pokemonFromDictionary:dict];
    _pokemonDetailCache[key] = pokemon;
    return pokemon;
}

#pragma mark - Moves Index

- (NSArray *)allMoveSummaries {
    if (!_movesIndex) {
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
            NSLog(@"Loaded %lu moves from moves/index.plist",
                  (unsigned long)_movesIndex.count);
        }
    }
    return _movesIndex;
}

- (NSUInteger)totalMoveCount {
    return [self allMoveSummaries].count;
}

- (NSArray *)searchMovesWithName:(NSString *)query {
    if (!query || query.length == 0) return [self allMoveSummaries];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:
        @"name CONTAINS[cd] %@", query];
    return [[self allMoveSummaries] filteredArrayUsingPredicate:predicate];
}

#pragma mark - Move Detail

- (Move *)moveDetailWithID:(NSInteger)moveID {
    NSNumber *key = @(moveID);
    Move *cached = _moveDetailCache[key];
    if (cached) return cached;

    NSString *filename = [NSString stringWithFormat:@"%ld", (long)moveID];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename
                                                    ofType:@"plist"
                                               inDirectory:@"data/moves"];
    if (!path) return nil;

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!dict) return nil;

    Move *move = [Move moveFromDictionary:dict];
    _moveDetailCache[key] = move;
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

@end
