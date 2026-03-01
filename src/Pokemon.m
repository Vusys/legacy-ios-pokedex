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
    p.heldItems = dict[@"held_items"] ?: @[];
    p.hasFemaleSprite = [dict[@"has_female_sprite"] boolValue];
    p.hasBackShinySprite = [dict[@"has_back_shiny_sprite"] boolValue];
    p.hasShinyFemaleSprite = [dict[@"has_shiny_female_sprite"] boolValue];
    p.hasBackFemaleSprite = [dict[@"has_back_female_sprite"] boolValue];
    p.hasBackShinyFemaleSprite = [dict[@"has_back_shiny_female_sprite"] boolValue];
    p.hasShinyArtwork = [dict[@"has_shiny_artwork"] boolValue];
    p.growthRate = dict[@"growth_rate"] ?: @"";
    p.isLegendary = [dict[@"is_legendary"] boolValue];
    p.isMythical = [dict[@"is_mythical"] boolValue];
    p.isBaby = [dict[@"is_baby"] boolValue];
    p.flavorTextEntries = dict[@"flavor_text_entries"] ?: @[];
    p.localizedNames = dict[@"localized_names"] ?: @[];
    p.pokedexNumbers = dict[@"pokedex_numbers"] ?: @[];
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

- (NSString *)formattedGrowthRate {
    NSDictionary *names = @{
        @"fast":                  @"Fast",
        @"medium":                @"Medium Fast",
        @"medium-slow":           @"Medium Slow",
        @"slow":                  @"Slow",
        @"fast-then-very-slow":   @"Erratic",
        @"slow-then-very-fast":   @"Fluctuating",
    };
    return names[self.growthRate] ?: self.growthRate;
}

@end
