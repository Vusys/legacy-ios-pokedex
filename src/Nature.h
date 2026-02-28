#import <Foundation/Foundation.h>

@interface Nature : NSObject

@property (nonatomic, assign) NSInteger natureID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *apiName;
@property (nonatomic, strong) NSString *increasedStat;  // API name e.g. "attack", "" if neutral
@property (nonatomic, strong) NSString *decreasedStat;  // API name e.g. "defense", "" if neutral
@property (nonatomic, strong) NSString *likesFlavor;     // e.g. "spicy", "" if neutral
@property (nonatomic, strong) NSString *hatesFlavor;     // e.g. "sour", "" if neutral
@property (nonatomic, assign) BOOL isNeutral;

+ (instancetype)natureFromDictionary:(NSDictionary *)dict;

- (NSString *)increasedStatDisplay;
- (NSString *)decreasedStatDisplay;
- (NSString *)likesFlavorDisplay;
- (NSString *)hatesFlavorDisplay;

@end
