#import "Item.h"

@implementation Item

+ (instancetype)itemFromDictionary:(NSDictionary *)dict {
    Item *item = [[Item alloc] init];
    item.itemID = [dict[@"id"] integerValue];
    item.name = dict[@"name"] ?: @"";
    item.apiName = dict[@"api_name"] ?: @"";
    item.category = dict[@"category"] ?: @"";
    item.cost = [dict[@"cost"] integerValue];
    item.effect = dict[@"effect"] ?: @"";
    item.flavorText = dict[@"flavor_text"] ?: @"";
    item.hasSprite = [dict[@"has_sprite"] boolValue];
    item.heldBy = dict[@"held_by"] ?: @[];

    id flingPower = dict[@"fling_power"];
    if (flingPower && flingPower != [NSNull null]) {
        item.flingPower = flingPower;
    }

    id flingEffect = dict[@"fling_effect"];
    if (flingEffect && flingEffect != [NSNull null] &&
        [flingEffect isKindOfClass:[NSString class]] && [flingEffect length] > 0) {
        item.flingEffect = flingEffect;
    }

    id teachesMove = dict[@"teaches_move"];
    if (teachesMove && teachesMove != [NSNull null] &&
        [teachesMove isKindOfClass:[NSDictionary class]]) {
        item.teachesMove = teachesMove;
    }

    return item;
}

- (NSString *)costString {
    if (self.cost == 0) return @"Free";
    return [NSString stringWithFormat:@"¥%ld", (long)self.cost];
}

- (NSString *)categoryDisplay {
    if (!self.category || self.category.length == 0) return @"";
    // Convert "standard-balls" → "Standard Balls"
    NSArray *parts = [self.category componentsSeparatedByString:@"-"];
    NSMutableArray *capitalized = [[NSMutableArray alloc] init];
    for (NSString *part in parts) {
        if (part.length > 0) {
            [capitalized addObject:[[[part substringToIndex:1] uppercaseString]
                stringByAppendingString:[part substringFromIndex:1]]];
        }
    }
    return [capitalized componentsJoinedByString:@" "];
}

@end
