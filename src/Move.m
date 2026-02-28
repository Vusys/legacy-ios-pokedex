#import "Move.h"

@implementation Move

+ (instancetype)moveFromDictionary:(NSDictionary *)dict {
    Move *m = [[Move alloc] init];
    m.moveID = [dict[@"id"] integerValue];
    m.name = dict[@"name"] ?: @"";
    m.type = dict[@"type"] ?: @"";
    m.power = dict[@"power"];        // NSNumber or nil from plist
    m.accuracy = dict[@"accuracy"];  // NSNumber or nil from plist
    m.pp = [dict[@"pp"] integerValue];
    m.damageClass = dict[@"damage_class"] ?: @"";
    m.priority = [dict[@"priority"] integerValue];
    m.generation = dict[@"generation"] ?: @"";
    m.effect = dict[@"effect"] ?: @"";
    m.flavorText = dict[@"flavor_text"] ?: @"";
    m.target = dict[@"target"] ?: @"";
    m.meta = dict[@"meta"] ?: @{};
    m.statChanges = dict[@"stat_changes"] ?: @[];
    m.learnedBy = dict[@"learned_by"] ?: @[];
    return m;
}

- (NSString *)powerString {
    if (!self.power || [self.power isKindOfClass:[NSNull class]]) return @"—";
    return [NSString stringWithFormat:@"%ld", (long)[self.power integerValue]];
}

- (NSString *)accuracyString {
    if (!self.accuracy || [self.accuracy isKindOfClass:[NSNull class]]) return @"—";
    return [NSString stringWithFormat:@"%ld%%", (long)[self.accuracy integerValue]];
}

- (NSString *)ppString {
    return [NSString stringWithFormat:@"%ld", (long)self.pp];
}

- (NSString *)damageClassDisplay {
    if ([self.damageClass isEqualToString:@"physical"]) return @"Physical";
    if ([self.damageClass isEqualToString:@"special"]) return @"Special";
    if ([self.damageClass isEqualToString:@"status"]) return @"Status";
    return self.damageClass;
}

@end
