#import "Ability.h"

@implementation Ability

+ (instancetype)abilityFromDictionary:(NSDictionary *)dict {
    Ability *a = [[Ability alloc] init];
    a.abilityID = [dict[@"id"] integerValue];
    a.name = dict[@"name"] ?: @"";
    a.generation = dict[@"generation"] ?: @"";
    a.isMainSeries = [dict[@"is_main_series"] boolValue];
    a.effect = dict[@"effect"] ?: @"";
    a.flavorText = dict[@"flavor_text"] ?: @"";
    a.pokemon = dict[@"pokemon"] ?: @[];
    return a;
}

- (NSString *)generationDisplay {
    if (!self.generation || self.generation.length == 0) return @"";
    NSString *numeral = [[self.generation componentsSeparatedByString:@"-"] lastObject];
    return [NSString stringWithFormat:@"Gen %@", [numeral uppercaseString]];
}

@end
