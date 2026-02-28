#import "DataManager.h"
#import "Pokemon.h"

@interface DataManager ()
@property (nonatomic, strong) NSArray *index;
@property (nonatomic, strong) NSMutableDictionary *detailCache;
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
        _detailCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Index

- (NSArray *)allPokemonSummaries {
    if (!_index) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"index"
                                                        ofType:@"plist"
                                                   inDirectory:@"data"];
        if (path) {
            _index = [NSArray arrayWithContentsOfFile:path];
        }
        if (!_index) {
            NSLog(@"WARNING: Could not load index.plist");
            _index = @[];
        } else {
            NSLog(@"Loaded %lu Pokemon from index.plist", (unsigned long)_index.count);
        }
    }
    return _index;
}

- (NSUInteger)totalCount {
    return [self allPokemonSummaries].count;
}

- (NSArray *)searchPokemonWithName:(NSString *)query {
    if (!query || query.length == 0) return [self allPokemonSummaries];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:
        @"name CONTAINS[cd] %@", query];
    return [[self allPokemonSummaries] filteredArrayUsingPredicate:predicate];
}

#pragma mark - Detail

- (Pokemon *)pokemonDetailWithID:(NSInteger)pokemonID {
    NSNumber *key = @(pokemonID);
    Pokemon *cached = _detailCache[key];
    if (cached) return cached;

    NSString *filename = [NSString stringWithFormat:@"%ld", (long)pokemonID];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename
                                                    ofType:@"plist"
                                               inDirectory:@"data/pokemon"];
    if (!path) {
        NSLog(@"WARNING: No plist found for Pokemon #%ld", (long)pokemonID);
        return nil;
    }

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!dict) {
        NSLog(@"WARNING: Could not parse plist for Pokemon #%ld", (long)pokemonID);
        return nil;
    }

    Pokemon *pokemon = [Pokemon pokemonFromDictionary:dict];
    _detailCache[key] = pokemon;
    return pokemon;
}

@end
