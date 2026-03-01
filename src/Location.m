#import "Location.h"

@implementation Location

+ (instancetype)locationFromDictionary:(NSDictionary *)dict {
    Location *loc = [[Location alloc] init];
    loc.locationID = [dict[@"id"] integerValue];
    loc.name = dict[@"name"] ?: @"";
    loc.region = dict[@"region"] ?: @"";
    loc.areas = dict[@"areas"] ?: @[];
    loc.versions = dict[@"versions"] ?: @[];
    return loc;
}

@end
