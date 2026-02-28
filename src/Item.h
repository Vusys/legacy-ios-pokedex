#import <Foundation/Foundation.h>

@interface Item : NSObject

@property (nonatomic, assign) NSInteger itemID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *apiName;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, assign) NSInteger cost;
@property (nonatomic, strong) NSString *effect;
@property (nonatomic, strong) NSString *flavorText;
@property (nonatomic, assign) BOOL hasSprite;
@property (nonatomic, strong) NSArray *heldBy;         // array of dicts: id, name
@property (nonatomic, strong) NSNumber *flingPower;     // nil if not applicable
@property (nonatomic, strong) NSString *flingEffect;    // nil if not applicable
@property (nonatomic, strong) NSDictionary *teachesMove; // nil if not TM/HM

+ (instancetype)itemFromDictionary:(NSDictionary *)dict;

- (NSString *)costString;
- (NSString *)categoryDisplay;

@end
