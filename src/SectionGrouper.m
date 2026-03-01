#import "SectionGrouper.h"

@implementation SectionGrouper

+ (NSDictionary *)groupSummaries:(NSArray *)summaries
                           byKey:(NSString *)key
                    sectionOrder:(NSArray *)orderedKeys
                    displayNames:(NSDictionary *)displayNames {
    // Build buckets
    NSMutableDictionary *buckets = [NSMutableDictionary dictionary];
    for (NSDictionary *s in summaries) {
        NSString *val = s[key];
        if (!val) val = @"unknown";
        NSMutableArray *arr = buckets[val];
        if (!arr) {
            arr = [NSMutableArray array];
            buckets[val] = arr;
        }
        [arr addObject:s];
    }

    // Build ordered results, skipping empty sections
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];

    for (NSString *k in orderedKeys) {
        NSArray *bucket = buckets[k];
        if (bucket.count == 0) continue;
        NSString *display = displayNames[k] ?: k;
        [titles addObject:[NSString stringWithFormat:@"%@ (%lu)",
                           display, (unsigned long)bucket.count]];
        [items addObject:bucket];
    }

    // Add any keys not in the ordered list
    for (NSString *k in buckets) {
        if ([orderedKeys containsObject:k]) continue;
        NSArray *bucket = buckets[k];
        if (bucket.count == 0) continue;
        NSString *display = displayNames[k] ?: k;
        [titles addObject:[NSString stringWithFormat:@"%@ (%lu)",
                           display, (unsigned long)bucket.count]];
        [items addObject:bucket];
    }

    return @{@"titles": titles, @"items": items};
}

+ (NSDictionary *)groupSummaries:(NSArray *)summaries
                      byArrayKey:(NSString *)key
                    sectionOrder:(NSArray *)orderedKeys
                    displayNames:(NSDictionary *)displayNames {
    // Build buckets — each summary can appear in multiple sections
    NSMutableDictionary *buckets = [NSMutableDictionary dictionary];
    for (NSDictionary *s in summaries) {
        NSArray *vals = s[key];
        if (![vals isKindOfClass:[NSArray class]] || vals.count == 0) {
            NSMutableArray *arr = buckets[@"unknown"];
            if (!arr) {
                arr = [NSMutableArray array];
                buckets[@"unknown"] = arr;
            }
            [arr addObject:s];
            continue;
        }
        for (NSString *val in vals) {
            NSMutableArray *arr = buckets[val];
            if (!arr) {
                arr = [NSMutableArray array];
                buckets[val] = arr;
            }
            [arr addObject:s];
        }
    }

    // Build ordered results, skipping empty sections
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];

    for (NSString *k in orderedKeys) {
        NSArray *bucket = buckets[k];
        if (bucket.count == 0) continue;
        NSString *display = displayNames[k] ?: k;
        [titles addObject:[NSString stringWithFormat:@"%@ (%lu)",
                           display, (unsigned long)bucket.count]];
        [items addObject:bucket];
    }

    for (NSString *k in buckets) {
        if ([orderedKeys containsObject:k]) continue;
        NSArray *bucket = buckets[k];
        if (bucket.count == 0) continue;
        NSString *display = displayNames[k] ?: k;
        [titles addObject:[NSString stringWithFormat:@"%@ (%lu)",
                           display, (unsigned long)bucket.count]];
        [items addObject:bucket];
    }

    return @{@"titles": titles, @"items": items};
}

+ (NSDictionary *)groupSummaries:(NSArray *)summaries
                           byKey:(NSString *)key
                          ranges:(NSArray *)rangeMaxValues
                          labels:(NSArray *)rangeLabels {
    NSUInteger rangeCount = rangeLabels.count;
    NSMutableArray *buckets = [NSMutableArray arrayWithCapacity:rangeCount];
    for (NSUInteger i = 0; i < rangeCount; i++) {
        [buckets addObject:[NSMutableArray array]];
    }

    for (NSDictionary *s in summaries) {
        NSInteger val = [s[key] integerValue];
        NSUInteger idx = rangeCount - 1; // default to last bucket
        for (NSUInteger i = 0; i < rangeMaxValues.count; i++) {
            if (val < [rangeMaxValues[i] integerValue]) {
                idx = i;
                break;
            }
        }
        [buckets[idx] addObject:s];
    }

    // Build results, skipping empty sections
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];
    for (NSUInteger i = 0; i < rangeCount; i++) {
        NSArray *bucket = buckets[i];
        if (bucket.count == 0) continue;
        [titles addObject:[NSString stringWithFormat:@"%@ (%lu)",
                           rangeLabels[i], (unsigned long)bucket.count]];
        [items addObject:bucket];
    }

    return @{@"titles": titles, @"items": items};
}

#pragma mark - Shared Helpers

+ (NSArray *)generationKeys {
    return @[@"generation-i", @"generation-ii", @"generation-iii",
             @"generation-iv", @"generation-v", @"generation-vi",
             @"generation-vii", @"generation-viii", @"generation-ix"];
}

+ (NSDictionary *)generationDisplayNames {
    return @{
        @"generation-i":    @"Generation I",
        @"generation-ii":   @"Generation II",
        @"generation-iii":  @"Generation III",
        @"generation-iv":   @"Generation IV",
        @"generation-v":    @"Generation V",
        @"generation-vi":   @"Generation VI",
        @"generation-vii":  @"Generation VII",
        @"generation-viii": @"Generation VIII",
        @"generation-ix":   @"Generation IX",
    };
}

+ (NSArray *)typeKeys {
    return @[@"normal", @"fire", @"water", @"electric", @"grass", @"ice",
             @"fighting", @"poison", @"ground", @"flying", @"psychic", @"bug",
             @"rock", @"ghost", @"dragon", @"dark", @"steel", @"fairy"];
}

+ (NSDictionary *)typeDisplayNames {
    NSArray *keys = [self typeKeys];
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    for (NSString *k in keys) {
        map[k] = [self capitalizeTypeName:k];
    }
    return map;
}

+ (NSString *)capitalizeTypeName:(NSString *)typeName {
    if (typeName.length == 0) return typeName;
    return [[[typeName substringToIndex:1] uppercaseString]
            stringByAppendingString:[typeName substringFromIndex:1]];
}

@end
