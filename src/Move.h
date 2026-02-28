#import <Foundation/Foundation.h>

@interface Move : NSObject

@property (nonatomic, assign) NSInteger moveID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSNumber *power;      // nil for status moves
@property (nonatomic, strong) NSNumber *accuracy;    // nil for never-miss moves
@property (nonatomic, assign) NSInteger pp;
@property (nonatomic, strong) NSString *damageClass; // physical, special, status
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, strong) NSString *generation;
@property (nonatomic, strong) NSString *effect;
@property (nonatomic, strong) NSString *flavorText;
@property (nonatomic, strong) NSString *target;
@property (nonatomic, strong) NSDictionary *meta;
@property (nonatomic, strong) NSArray *statChanges;
@property (nonatomic, strong) NSArray *learnedBy;    // array of Pokemon IDs

+ (instancetype)moveFromDictionary:(NSDictionary *)dict;

- (NSString *)powerString;
- (NSString *)accuracyString;
- (NSString *)ppString;
- (NSString *)damageClassDisplay;

@end
