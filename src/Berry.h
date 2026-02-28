#import <Foundation/Foundation.h>

@interface Berry : NSObject

@property (nonatomic, assign) NSInteger berryID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *apiName;
@property (nonatomic, strong) NSString *naturalGiftType;
@property (nonatomic, assign) NSInteger naturalGiftPower;
@property (nonatomic, strong) NSString *firmness;
@property (nonatomic, assign) NSInteger growthTime;
@property (nonatomic, assign) NSInteger maxHarvest;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, assign) NSInteger smoothness;
@property (nonatomic, assign) NSInteger soilDryness;
@property (nonatomic, assign) BOOL hasSprite;
@property (nonatomic, strong) NSDictionary *flavors; // flavor_name → potency (NSNumber)
@property (nonatomic, strong) NSString *effect;
@property (nonatomic, strong) NSString *flavorText;

+ (instancetype)berryFromDictionary:(NSDictionary *)dict;

- (NSString *)firmnessDisplay;
- (NSString *)growthTimeDisplay;
- (NSString *)sizeDisplay;

@end
