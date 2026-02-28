#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Pokemon;
@class Move;

@interface DataManager : NSObject

+ (instancetype)sharedManager;

// Pokemon index (lightweight, loaded once at startup)
- (NSArray *)allPokemonSummaries;
- (NSArray *)searchPokemonWithName:(NSString *)query;
- (NSUInteger)totalPokemonCount;

// Pokemon detail (loaded on demand)
- (Pokemon *)pokemonDetailWithID:(NSInteger)pokemonID;

// Moves index (lightweight, loaded once)
- (NSArray *)allMoveSummaries;
- (NSArray *)searchMovesWithName:(NSString *)query;
- (NSUInteger)totalMoveCount;

// Move detail (loaded on demand)
- (Move *)moveDetailWithID:(NSInteger)moveID;

// Pokemon name lookup (for move detail "learned by" list)
- (NSString *)pokemonNameForID:(NSInteger)pokemonID;

@end
