#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Pokemon;
@class Move;

@interface DataManager : NSObject

+ (instancetype)sharedManager;

// Pokemon index (lightweight, loaded once at startup)
- (NSArray *)allPokemonSummaries;
- (NSArray *)searchPokemonWithName:(NSString *)query;
- (NSArray *)searchPokemonWithQuery:(NSString *)query
                              types:(NSSet *)types
                        generations:(NSSet *)generations
                         categories:(NSSet *)categories
                             sortBy:(NSString *)sortBy;
- (NSUInteger)totalPokemonCount;

// Pokemon detail (loaded on demand)
- (Pokemon *)pokemonDetailWithID:(NSInteger)pokemonID;

// Moves index (lightweight, loaded once)
- (NSArray *)allMoveSummaries;
- (NSArray *)searchMovesWithName:(NSString *)query;
- (NSArray *)searchMovesWithQuery:(NSString *)query
                            types:(NSSet *)types
                      generations:(NSSet *)generations
                    damageClasses:(NSSet *)damageClasses
                           sortBy:(NSString *)sortBy;
- (NSUInteger)totalMoveCount;

// Move detail (loaded on demand)
- (Move *)moveDetailWithID:(NSInteger)moveID;

// Pokemon name lookup (for move detail "learned by" list)
- (NSString *)pokemonNameForID:(NSInteger)pokemonID;

// Shared sprite cache (avoids repeated disk reads)
- (UIImage *)spriteForPokemonID:(NSInteger)pokemonID;

@end
