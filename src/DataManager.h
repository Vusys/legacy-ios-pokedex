#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Pokemon;

@interface DataManager : NSObject

+ (instancetype)sharedManager;

// Index (lightweight, loaded once at startup)
- (NSArray *)allPokemonSummaries;
- (NSArray *)searchPokemonWithName:(NSString *)query;
- (NSUInteger)totalCount;

// Detail (loaded on demand per Pokemon)
- (Pokemon *)pokemonDetailWithID:(NSInteger)pokemonID;

@end
