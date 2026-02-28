#import "PokemonType.h"

@implementation PokemonType

+ (NSDictionary *)typeColorMap {
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @"normal":   [UIColor colorWithRed:0.66 green:0.66 blue:0.47 alpha:1],
            @"fire":     [UIColor colorWithRed:0.94 green:0.50 blue:0.19 alpha:1],
            @"water":    [UIColor colorWithRed:0.41 green:0.56 blue:0.94 alpha:1],
            @"electric": [UIColor colorWithRed:0.97 green:0.82 blue:0.19 alpha:1],
            @"grass":    [UIColor colorWithRed:0.47 green:0.78 blue:0.31 alpha:1],
            @"ice":      [UIColor colorWithRed:0.60 green:0.85 blue:0.85 alpha:1],
            @"fighting": [UIColor colorWithRed:0.75 green:0.19 blue:0.16 alpha:1],
            @"poison":   [UIColor colorWithRed:0.63 green:0.25 blue:0.63 alpha:1],
            @"ground":   [UIColor colorWithRed:0.88 green:0.75 blue:0.41 alpha:1],
            @"flying":   [UIColor colorWithRed:0.66 green:0.56 blue:0.94 alpha:1],
            @"psychic":  [UIColor colorWithRed:0.97 green:0.35 blue:0.53 alpha:1],
            @"bug":      [UIColor colorWithRed:0.66 green:0.72 blue:0.13 alpha:1],
            @"rock":     [UIColor colorWithRed:0.72 green:0.63 blue:0.22 alpha:1],
            @"ghost":    [UIColor colorWithRed:0.44 green:0.35 blue:0.60 alpha:1],
            @"dragon":   [UIColor colorWithRed:0.44 green:0.22 blue:0.97 alpha:1],
            @"dark":     [UIColor colorWithRed:0.44 green:0.35 blue:0.28 alpha:1],
            @"steel":    [UIColor colorWithRed:0.72 green:0.72 blue:0.82 alpha:1],
            @"fairy":    [UIColor colorWithRed:0.93 green:0.60 blue:0.67 alpha:1],
        };
    });
    return map;
}

+ (UIColor *)colorForTypeName:(NSString *)typeName {
    NSString *lower = [typeName lowercaseString];
    UIColor *color = [self typeColorMap][lower];
    return color ?: [UIColor grayColor];
}

+ (UIColor *)darkColorForTypeName:(NSString *)typeName {
    UIColor *base = [self colorForTypeName:typeName];
    CGFloat r, g, b, a;
    [base getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:r * 0.7 green:g * 0.7 blue:b * 0.7 alpha:a];
}

+ (NSArray *)allTypeNames {
    return @[@"normal", @"fire", @"water", @"electric", @"grass", @"ice",
             @"fighting", @"poison", @"ground", @"flying", @"psychic", @"bug",
             @"rock", @"ghost", @"dragon", @"dark", @"steel", @"fairy"];
}

@end
