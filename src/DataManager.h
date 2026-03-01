#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Pokemon;
@class Move;
@class Ability;
@class Item;
@class Nature;
@class EggGroup;
@class Berry;
@class Location;

extern NSString *const FavouritesChangedNotification;

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
- (UIImage *)backShinySpriteForPokemonID:(NSInteger)pokemonID;
- (UIImage *)shinyFemaleSpriteForPokemonID:(NSInteger)pokemonID;
- (UIImage *)backFemaleSpriteForPokemonID:(NSInteger)pokemonID;
- (UIImage *)backShinyFemaleSpriteForPokemonID:(NSInteger)pokemonID;
- (UIImage *)shinyArtworkForPokemonID:(NSInteger)pokemonID;
- (UIImage *)spriteForItemName:(NSString *)apiName;

// Types data (for type effectiveness calculations)
- (NSArray *)allTypes;

// Natures (all data in single index, no separate detail plists)
- (NSArray *)allNatureSummaries;
- (NSArray *)searchNaturesWithQuery:(NSString *)query
                             sortBy:(NSString *)sortBy;

// Egg Groups index
- (NSArray *)allEggGroupSummaries;
- (NSArray *)searchEggGroupsWithQuery:(NSString *)query
                               sortBy:(NSString *)sortBy;

// Egg Group detail (loaded on demand)
- (EggGroup *)eggGroupDetailWithID:(NSInteger)eggGroupID;

// Berries index
- (NSArray *)allBerrySummaries;
- (NSArray *)searchBerriesWithQuery:(NSString *)query
                              types:(NSSet *)types
                             sortBy:(NSString *)sortBy;

// Berry detail (loaded on demand)
- (Berry *)berryDetailWithID:(NSInteger)berryID;

// Berry sprite
- (UIImage *)spriteForBerryID:(NSInteger)berryID;

// Encounter data (loaded on demand, separate from Pokemon detail)
- (NSArray *)encounterDataForPokemonID:(NSInteger)pokemonID;

// Locations index
- (NSArray *)allLocationSummaries;
- (NSArray *)locationSummariesForRegion:(NSString *)regionName;
- (NSArray *)searchLocationsWithQuery:(NSString *)query
                             inRegion:(NSString *)regionName
                               sortBy:(NSString *)sortBy;
- (Location *)locationDetailWithID:(NSInteger)locationID;
- (NSArray *)allRegions;

// Favourites
- (BOOL)isFavourite:(NSInteger)entityID type:(NSString *)entityType;
- (void)toggleFavourite:(NSInteger)entityID type:(NSString *)entityType;
- (NSSet *)favouriteIDsForType:(NSString *)entityType;
- (NSUInteger)totalFavouriteCount;
- (NSArray *)filterSummaries:(NSArray *)summaries byFavouritesOfType:(NSString *)type;

@end
