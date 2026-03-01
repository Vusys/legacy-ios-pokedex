#import <Foundation/Foundation.h>

@interface FilterState : NSObject <NSCopying>

@property (nonatomic, strong) NSMutableSet *selectedTypes;
@property (nonatomic, strong) NSMutableSet *selectedGenerations;
@property (nonatomic, strong) NSMutableSet *selectedCategories;
@property (nonatomic, copy) NSString *sortBy;
@property (nonatomic, assign) BOOL showFavouritesOnly;

- (BOOL)hasActiveFilters;
- (NSUInteger)activeFilterCount;
- (void)reset;

@end
