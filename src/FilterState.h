#import <Foundation/Foundation.h>

@interface FilterState : NSObject <NSCopying>

@property (nonatomic, strong) NSMutableSet *selectedTypes;
@property (nonatomic, strong) NSMutableSet *selectedGenerations;
@property (nonatomic, strong) NSMutableSet *selectedCategories;
@property (nonatomic, copy) NSString *sortBy;

- (BOOL)hasActiveFilters;
- (NSUInteger)activeFilterCount;
- (void)reset;

@end
