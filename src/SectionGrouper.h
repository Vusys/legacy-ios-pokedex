#import <Foundation/Foundation.h>

@interface SectionGrouper : NSObject

// Group summaries by a single-value key (generation, damage_class, firmness, type)
// Returns @{@"titles": NSArray*, @"items": NSArray<NSArray*>*}
+ (NSDictionary *)groupSummaries:(NSArray *)summaries
                           byKey:(NSString *)key
                    sectionOrder:(NSArray *)orderedKeys
                    displayNames:(NSDictionary *)displayNames;

// Group summaries by an array-valued key (e.g. Pokemon types — dual-type appears in both)
+ (NSDictionary *)groupSummaries:(NSArray *)summaries
                      byArrayKey:(NSString *)key
                    sectionOrder:(NSArray *)orderedKeys
                    displayNames:(NSDictionary *)displayNames;

// Group summaries into numeric range buckets (e.g. stat_total ranges)
+ (NSDictionary *)groupSummaries:(NSArray *)summaries
                           byKey:(NSString *)key
                          ranges:(NSArray *)rangeMaxValues
                          labels:(NSArray *)rangeLabels;

// Shared helpers
+ (NSArray *)generationKeys;
+ (NSDictionary *)generationDisplayNames;
+ (NSArray *)typeKeys;
+ (NSDictionary *)typeDisplayNames;
+ (NSString *)capitalizeTypeName:(NSString *)typeName;

@end
