#import <Foundation/Foundation.h>

@interface Location : NSObject

@property (nonatomic, assign) NSInteger locationID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *region;
@property (nonatomic, strong) NSArray *areas;     // array of area name strings
@property (nonatomic, strong) NSArray *versions;   // array of dicts: version, pokemon[]

+ (instancetype)locationFromDictionary:(NSDictionary *)dict;

@end
