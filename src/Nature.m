#import "Nature.h"

@implementation Nature

+ (instancetype)natureFromDictionary:(NSDictionary *)dict {
    Nature *n = [[Nature alloc] init];
    n.natureID = [dict[@"id"] integerValue];
    n.name = dict[@"name"] ?: @"";
    n.apiName = dict[@"api_name"] ?: @"";
    n.increasedStat = dict[@"increased_stat"] ?: @"";
    n.decreasedStat = dict[@"decreased_stat"] ?: @"";
    n.likesFlavor = dict[@"likes_flavor"] ?: @"";
    n.hatesFlavor = dict[@"hates_flavor"] ?: @"";
    n.isNeutral = [dict[@"is_neutral"] boolValue];
    return n;
}

- (NSString *)statDisplayName:(NSString *)apiStat {
    if (!apiStat || apiStat.length == 0) return @"\u2014";
    if ([apiStat isEqualToString:@"attack"])          return @"Attack";
    if ([apiStat isEqualToString:@"defense"])         return @"Defense";
    if ([apiStat isEqualToString:@"special-attack"])  return @"Sp. Atk";
    if ([apiStat isEqualToString:@"special-defense"]) return @"Sp. Def";
    if ([apiStat isEqualToString:@"speed"])           return @"Speed";
    if ([apiStat isEqualToString:@"hp"])              return @"HP";
    return apiStat;
}

- (NSString *)flavorDisplayName:(NSString *)flavor {
    if (!flavor || flavor.length == 0) return @"\u2014";
    return [[[flavor substringToIndex:1] uppercaseString]
        stringByAppendingString:[flavor substringFromIndex:1]];
}

- (NSString *)increasedStatDisplay {
    return [self statDisplayName:self.increasedStat];
}

- (NSString *)decreasedStatDisplay {
    return [self statDisplayName:self.decreasedStat];
}

- (NSString *)likesFlavorDisplay {
    return [self flavorDisplayName:self.likesFlavor];
}

- (NSString *)hatesFlavorDisplay {
    return [self flavorDisplayName:self.hatesFlavor];
}

@end
