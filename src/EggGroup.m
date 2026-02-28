#import "EggGroup.h"

@implementation EggGroup

+ (instancetype)eggGroupFromDictionary:(NSDictionary *)dict {
    EggGroup *eg = [[EggGroup alloc] init];
    eg.eggGroupID = [dict[@"id"] integerValue];
    eg.name = dict[@"name"] ?: @"";
    eg.pokemon = dict[@"pokemon"] ?: @[];
    return eg;
}

@end
