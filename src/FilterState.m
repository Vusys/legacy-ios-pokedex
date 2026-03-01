#import "FilterState.h"

@implementation FilterState

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedTypes = [[NSMutableSet alloc] init];
        _selectedGenerations = [[NSMutableSet alloc] init];
        _selectedCategories = [[NSMutableSet alloc] init];
        _sortBy = @"number";
    }
    return self;
}

- (BOOL)hasActiveFilters {
    return _showFavouritesOnly ||
           _selectedTypes.count > 0 ||
           _selectedGenerations.count > 0 ||
           _selectedCategories.count > 0;
}

- (NSUInteger)activeFilterCount {
    return (_showFavouritesOnly ? 1 : 0) +
           _selectedTypes.count +
           _selectedGenerations.count +
           _selectedCategories.count;
}

- (void)reset {
    _showFavouritesOnly = NO;
    [_selectedTypes removeAllObjects];
    [_selectedGenerations removeAllObjects];
    [_selectedCategories removeAllObjects];
    _sortBy = @"number";
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    FilterState *copy = [[[self class] allocWithZone:zone] init];
    copy.showFavouritesOnly = _showFavouritesOnly;
    copy.selectedTypes = [_selectedTypes mutableCopy];
    copy.selectedGenerations = [_selectedGenerations mutableCopy];
    copy.selectedCategories = [_selectedCategories mutableCopy];
    copy.sortBy = [_sortBy copy];
    return copy;
}

@end
