#import "Pokemon.h"
#import "DataManager.h"

@interface Pokemon ()
@property (nonatomic, strong) UIImage *cachedSprite;
@end

@implementation Pokemon

+ (instancetype)pokemonFromDictionary:(NSDictionary *)dict {
    Pokemon *p = [[Pokemon alloc] init];
    p.pokemonID = [dict[@"id"] integerValue];
    p.name = dict[@"name"] ?: @"";
    p.types = dict[@"types"] ?: @[];
    p.stats = dict[@"stats"] ?: @{};
    p.height = [dict[@"height"] integerValue];
    p.weight = [dict[@"weight"] integerValue];
    p.baseExperience = [dict[@"base_experience"] integerValue];
    p.abilities = dict[@"abilities"] ?: @[];
    p.flavorText = dict[@"flavor_text"] ?: @"";
    p.genus = dict[@"genus"] ?: @"";
    p.generation = dict[@"generation"] ?: @"";
    p.habitat = dict[@"habitat"] ?: @"";
    p.color = dict[@"color"] ?: @"";
    p.shape = dict[@"shape"] ?: @"";
    p.genderRate = [dict[@"gender_rate"] integerValue];
    p.captureRate = [dict[@"capture_rate"] integerValue];
    p.baseHappiness = [dict[@"base_happiness"] integerValue];
    p.hatchCounter = [dict[@"hatch_counter"] integerValue];
    p.eggGroups = dict[@"egg_groups"] ?: @[];
    p.evolutionChain = dict[@"evolution_chain"] ?: @[];
    p.moves = dict[@"moves"] ?: @[];
    return p;
}

- (UIImage *)spriteImage {
    if (!_cachedSprite) {
        _cachedSprite = [[DataManager sharedManager] spriteForPokemonID:self.pokemonID];
    }
    return _cachedSprite;
}

- (NSString *)formattedID {
    return [NSString stringWithFormat:@"#%03ld", (long)self.pokemonID];
}

- (NSString *)formattedHeight {
    CGFloat meters = self.height / 10.0;
    return [NSString stringWithFormat:@"%.1f m", meters];
}

- (NSString *)formattedWeight {
    CGFloat kg = self.weight / 10.0;
    return [NSString stringWithFormat:@"%.1f kg", kg];
}

- (NSString *)genderString {
    if (self.genderRate == -1) return @"Genderless";
    if (self.genderRate == 0) return @"100% Male";
    if (self.genderRate == 8) return @"100% Female";
    CGFloat femalePercent = (self.genderRate / 8.0) * 100.0;
    CGFloat malePercent = 100.0 - femalePercent;
    return [NSString stringWithFormat:@"%.1f%% M / %.1f%% F", malePercent, femalePercent];
}

@end
