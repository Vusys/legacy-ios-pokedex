#import <Foundation/Foundation.h>

@interface Ability : NSObject

@property (nonatomic, assign) NSInteger abilityID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *generation;
@property (nonatomic, assign) BOOL isMainSeries;
@property (nonatomic, strong) NSString *effect;
@property (nonatomic, strong) NSString *flavorText;
@property (nonatomic, strong) NSArray *pokemon; // array of dicts: id, name, is_hidden, slot

+ (instancetype)abilityFromDictionary:(NSDictionary *)dict;

- (NSString *)generationDisplay;

@end
