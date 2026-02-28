#import <Foundation/Foundation.h>

@interface EggGroup : NSObject

@property (nonatomic, assign) NSInteger eggGroupID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *pokemon; // array of dicts: id, name

+ (instancetype)eggGroupFromDictionary:(NSDictionary *)dict;

@end
