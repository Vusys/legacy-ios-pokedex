#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Pokemon;
@class Move;
@class Ability;
@class Item;

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

// Abilities index (lightweight, loaded once)
- (NSArray *)allAbilitySummaries;
- (NSArray *)searchAbilitiesWithQuery:(NSString *)query
                          generations:(NSSet *)generations
                               sortBy:(NSString *)sortBy;

// Ability detail (loaded on demand)
- (Ability *)abilityDetailWithID:(NSInteger)abilityID;

// Items index (lightweight, loaded once)
- (NSArray *)allItemSummaries;
- (NSArray *)searchItemsWithQuery:(NSString *)query
                           sortBy:(NSString *)sortBy;

// Item detail (loaded on demand)
- (Item *)itemDetailWithID:(NSInteger)itemID;

// Pokemon name lookup (for move detail "learned by" list)
- (NSString *)pokemonNameForID:(NSInteger)pokemonID;

// Shared sprite cache (avoids repeated disk reads)
- (UIImage *)spriteForPokemonID:(NSInteger)pokemonID;
- (UIImage *)artworkForPokemonID:(NSInteger)pokemonID;
- (UIImage *)shinySpriteForPokemonID:(NSInteger)pokemonID;
- (UIImage *)backSpriteForPokemonID:(NSInteger)pokemonID;
- (UIImage *)femaleSpriteForPokemonID:(NSInteger)pokemonID;
- (UIImage *)spriteForItemName:(NSString *)apiName;

@end
