#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Pokemon : NSObject

@property (nonatomic, assign) NSInteger pokemonID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *types;
@property (nonatomic, strong) NSDictionary *stats;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger weight;
@property (nonatomic, assign) NSInteger baseExperience;
@property (nonatomic, strong) NSArray *abilities;
@property (nonatomic, strong) NSString *flavorText;
@property (nonatomic, strong) NSString *genus;
@property (nonatomic, strong) NSString *generation;
@property (nonatomic, strong) NSString *habitat;
@property (nonatomic, strong) NSString *color;
@property (nonatomic, strong) NSString *shape;
@property (nonatomic, assign) NSInteger genderRate;
@property (nonatomic, assign) NSInteger captureRate;
@property (nonatomic, assign) NSInteger baseHappiness;
@property (nonatomic, assign) NSInteger hatchCounter;
@property (nonatomic, strong) NSArray *eggGroups;
@property (nonatomic, strong) NSArray *evolutionChain;
@property (nonatomic, strong) NSArray *moves;
@property (nonatomic, strong) NSArray *heldItems;
@property (nonatomic, assign) BOOL hasFemaleSprite;
@property (nonatomic, strong) NSString *growthRate;
@property (nonatomic, assign) BOOL isLegendary;
@property (nonatomic, assign) BOOL isMythical;
@property (nonatomic, assign) BOOL isBaby;
@property (nonatomic, strong) NSArray *flavorTextEntries;
@property (nonatomic, strong) NSArray *localizedNames;
@property (nonatomic, strong) NSArray *pokedexNumbers;

+ (instancetype)pokemonFromDictionary:(NSDictionary *)dict;

- (UIImage *)spriteImage;
- (NSString *)formattedID;
- (NSString *)formattedHeight;
- (NSString *)formattedWeight;
- (NSString *)genderString;
- (NSString *)formattedGrowthRate;

@end
