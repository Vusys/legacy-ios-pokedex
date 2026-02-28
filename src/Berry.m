#import "Berry.h"

@implementation Berry

+ (instancetype)berryFromDictionary:(NSDictionary *)dict {
    Berry *b = [[Berry alloc] init];
    b.berryID = [dict[@"id"] integerValue];
    b.name = dict[@"name"] ?: @"";
    b.apiName = dict[@"api_name"] ?: @"";
    b.naturalGiftType = dict[@"natural_gift_type"] ?: @"";
    b.naturalGiftPower = [dict[@"natural_gift_power"] integerValue];
    b.firmness = dict[@"firmness"] ?: @"";
    b.growthTime = [dict[@"growth_time"] integerValue];
    b.maxHarvest = [dict[@"max_harvest"] integerValue];
    b.size = [dict[@"size"] integerValue];
    b.smoothness = [dict[@"smoothness"] integerValue];
    b.soilDryness = [dict[@"soil_dryness"] integerValue];
    b.hasSprite = [dict[@"has_sprite"] boolValue];
    b.flavors = dict[@"flavors"] ?: @{};
    b.effect = dict[@"effect"] ?: @"";
    b.flavorText = dict[@"flavor_text"] ?: @"";
    return b;
}

- (NSString *)firmnessDisplay {
    if (!self.firmness || self.firmness.length == 0) return @"";
    NSArray *parts = [self.firmness componentsSeparatedByString:@"-"];
    NSMutableArray *capitalized = [[NSMutableArray alloc] init];
    for (NSString *part in parts) {
        if (part.length > 0) {
            [capitalized addObject:[[[part substringToIndex:1] uppercaseString]
                stringByAppendingString:[part substringFromIndex:1]]];
        }
    }
    return [capitalized componentsJoinedByString:@" "];
}

- (NSString *)growthTimeDisplay {
    return [NSString stringWithFormat:@"%ld hrs", (long)self.growthTime];
}

- (NSString *)sizeDisplay {
    return [NSString stringWithFormat:@"%ld mm", (long)self.size];
}

@end
