#import "BerryListVC.h"
#import "BerryCell.h"
#import "BerryDetailVC.h"
#import "DataManager.h"
#import "FilterState.h"
#import "FilterPopoverVC.h"
#import "SectionGrouper.h"
#import "PokemonType.h"
#import "NavBarStyle.h"
#import <QuartzCore/QuartzCore.h>

#define BERRY_CELL_HEIGHT 50
#define BERRY_CELL_ID @"BerryCell"
#define SECTION_HEADER_HEIGHT 28

static NSDictionary *firmnessDisplayNames() {
    return @{
        @"very-soft":  @"Very Soft",
        @"soft":       @"Soft",
        @"hard":       @"Hard",
        @"very-hard":  @"Very Hard",
        @"super-hard": @"Super Hard",
    };
}

@interface BerryListVC () <UISearchDisplayDelegate, UISearchBarDelegate>
@property (nonatomic, strong) NSArray *allBerries;
@property (nonatomic, strong) NSArray *displayedBerries;
@property (nonatomic, strong) NSArray *filteredBerries;
@property (nonatomic, strong) UISearchDisplayController *searchDC;
@property (nonatomic, strong) FilterState *filterState;
@property (nonatomic, strong) UIPopoverController *filterPopover;
@property (nonatomic, strong) UIBarButtonItem *filterButton;
// Section grouping
@property (nonatomic, strong) NSArray *sectionTitles;
@property (nonatomic, strong) NSArray *sectionItems;
@property (nonatomic, copy)   NSString *activeGrouping;
@property (nonatomic, strong) UISegmentedControl *groupControl;
@end

@implementation BerryListVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Berries";
    self.filterState = [[FilterState alloc] init];
    self.allBerries = [[DataManager sharedManager] allBerrySummaries];
    self.displayedBerries = self.allBerries;
    self.filteredBerries = @[];

    [self styleNavBar];

    // Filter button in nav bar
    _filterButton = [[UIBarButtonItem alloc]
        initWithTitle:@"Filter"
                style:UIBarButtonItemStyleBordered
               target:self
               action:@selector(showFilterPopover:)];
    self.navigationItem.rightBarButtonItem = _filterButton;

    // Compound table header: search bar + segmented control
    CGFloat width = self.view.bounds.size.width;

    UIView *headerWrapper = [[UIView alloc] initWithFrame:
        CGRectMake(0, 0, width, 44 + 36)];
    headerWrapper.backgroundColor = [UIColor clearColor];
    headerWrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    // Search bar
    UISearchBar *searchBar = [[UISearchBar alloc]
        initWithFrame:CGRectMake(0, 0, width, 44)];
    searchBar.placeholder = @"Search Berries";
    searchBar.delegate = self;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBar.tintColor = [UIColor colorWithRed:0.85 green:0.40 blue:0.50 alpha:1];
    [headerWrapper addSubview:searchBar];

    // Segmented control bar
    UIView *segBar = [[UIView alloc] initWithFrame:
        CGRectMake(0, 44, width, 36)];
    segBar.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1];
    segBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    _groupControl = [[UISegmentedControl alloc]
        initWithItems:@[@"All", @"Type", @"Firmness"]];
    _groupControl.frame = CGRectMake(8, 4, width - 44, 28);
    _groupControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _groupControl.segmentedControlStyle = UISegmentedControlStyleBar;
    _groupControl.tintColor = [UIColor colorWithWhite:0.45 alpha:1];
    _groupControl.selectedSegmentIndex = 0;
    [_groupControl addTarget:self action:@selector(groupingChanged:)
            forControlEvents:UIControlEventValueChanged];
    [segBar addSubview:_groupControl];

    UIView *segSep = [[UIView alloc] initWithFrame:
        CGRectMake(0, 35.5, width, 0.5)];
    segSep.backgroundColor = [UIColor colorWithWhite:0.80 alpha:1];
    segSep.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [segBar addSubview:segSep];

    [headerWrapper addSubview:segBar];
    self.tableView.tableHeaderView = headerWrapper;

    self.searchDC = [[UISearchDisplayController alloc]
        initWithSearchBar:searchBar contentsController:self];
    self.searchDC.delegate = self;
    self.searchDC.searchResultsDataSource = self;
    self.searchDC.searchResultsDelegate = self;

    // Restore saved grouping
    NSInteger savedIndex = [[NSUserDefaults standardUserDefaults]
        integerForKey:@"groupBy_berries"];
    if (savedIndex > 0 && savedIndex < (NSInteger)_groupControl.numberOfSegments) {
        _groupControl.selectedSegmentIndex = savedIndex;
        [self groupingChanged:_groupControl];
    }

    [[NSNotificationCenter defaultCenter]
        addObserver:self selector:@selector(favouritesDidChange:)
               name:FavouritesChangedNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)favouritesDidChange:(NSNotification *)note {
    if (_filterState.showFavouritesOnly) {
        [self recomputeDisplayedBerries];
        [self rebuildSections];
        [self.tableView reloadData];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self styleNavBar];
}

- (void)styleNavBar {
    [self.navigationController.navigationBar
        setBackgroundImage:NavBarGradientImage(0.70, 0.25, 0.35, 0.85, 0.40, 0.50)
             forBarMetrics:UIBarMetricsDefault];

    self.navigationController.navigationBar.titleTextAttributes = @{
        UITextAttributeTextColor: [UIColor whiteColor],
        UITextAttributeTextShadowColor: [UIColor colorWithWhite:0 alpha:0.6],
        UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
        UITextAttributeFont: [UIFont boldSystemFontOfSize:20]
    };
}

#pragma mark - Grouping

- (void)groupingChanged:(UISegmentedControl *)sender {
    NSInteger idx = sender.selectedSegmentIndex;
    [[NSUserDefaults standardUserDefaults] setInteger:idx forKey:@"groupBy_berries"];

    switch (idx) {
        case 1: self.activeGrouping = @"natural_gift_type"; break;
        case 2: self.activeGrouping = @"firmness"; break;
        default: self.activeGrouping = nil; break;
    }

    [self rebuildSections];
    [self.tableView reloadData];
}

- (void)rebuildSections {
    if (!_activeGrouping) {
        self.sectionTitles = nil;
        self.sectionItems = nil;
        return;
    }

    NSDictionary *result;
    if ([_activeGrouping isEqualToString:@"natural_gift_type"]) {
        result = [SectionGrouper groupSummaries:_displayedBerries
                                          byKey:@"natural_gift_type"
                                   sectionOrder:[SectionGrouper typeKeys]
                                   displayNames:[SectionGrouper typeDisplayNames]];
    } else if ([_activeGrouping isEqualToString:@"firmness"]) {
        result = [SectionGrouper groupSummaries:_displayedBerries
                                          byKey:@"firmness"
                                   sectionOrder:@[@"very-soft", @"soft", @"hard",
                                                  @"very-hard", @"super-hard"]
                                   displayNames:firmnessDisplayNames()];
    }

    self.sectionTitles = result[@"titles"];
    self.sectionItems = result[@"items"];
}

- (BOOL)isGroupedForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) return NO;
    return _activeGrouping != nil && _sectionTitles.count > 0;
}

#pragma mark - Filter

- (void)showFilterPopover:(UIBarButtonItem *)sender {
    FilterPopoverVC *filterVC = [[FilterPopoverVC alloc] init];
    filterVC.filterState = [_filterState copy];
    filterVC.filterMode = @"berries";
    filterVC.delegate = self;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (_filterPopover && _filterPopover.isPopoverVisible) {
            [_filterPopover dismissPopoverAnimated:YES];
            return;
        }
        [filterVC view]; // Force viewDidLoad so contentSizeForViewInPopover is set
        _filterPopover = [[UIPopoverController alloc] initWithContentViewController:filterVC];
        [_filterPopover presentPopoverFromBarButtonItem:sender
                               permittedArrowDirections:UIPopoverArrowDirectionAny
                                               animated:YES];
    } else {
        UINavigationController *filterNav = [[UINavigationController alloc]
            initWithRootViewController:filterVC];
        [self presentViewController:filterNav animated:YES completion:nil];
    }
}

- (void)filterPopoverDidApply:(FilterState *)filterState {
    self.filterState = filterState;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_filterPopover dismissPopoverAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [self recomputeDisplayedBerries];
    [self rebuildSections];
    [self updateFilterButtonTitle];
    [self.tableView reloadData];
}

- (void)recomputeDisplayedBerries {
    if (![_filterState hasActiveFilters] &&
        [_filterState.sortBy isEqualToString:@"number"]) {
        self.displayedBerries = self.allBerries;
    } else {
        self.displayedBerries = [[DataManager sharedManager]
            searchBerriesWithQuery:nil
                            types:_filterState.selectedTypes
                           sortBy:_filterState.sortBy];
    }
    if (_filterState.showFavouritesOnly) {
        self.displayedBerries = [[DataManager sharedManager]
            filterSummaries:self.displayedBerries byFavouritesOfType:@"berries"];
    }
}

- (void)updateFilterButtonTitle {
    NSUInteger count = [_filterState activeFilterCount];
    if (count > 0) {
        _filterButton.title = [NSString stringWithFormat:@"Filter (%lu)",
                               (unsigned long)count];
    } else {
        _filterButton.title = @"Filter";
    }
}

#pragma mark - Data Helper

- (NSDictionary *)summaryForTableView:(UITableView *)tableView
                          atIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (indexPath.row < (NSInteger)_filteredBerries.count)
            return _filteredBerries[indexPath.row];
        return nil;
    }
    if ([self isGroupedForTableView:tableView]) {
        if (indexPath.section < (NSInteger)_sectionItems.count) {
            NSArray *rows = _sectionItems[indexPath.section];
            if (indexPath.row < (NSInteger)rows.count)
                return rows[indexPath.row];
        }
        return nil;
    }
    if (indexPath.row < (NSInteger)_displayedBerries.count)
        return _displayedBerries[indexPath.row];
    return nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self isGroupedForTableView:tableView]) {
        return _sectionTitles.count;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return _filteredBerries.count;
    }
    if ([self isGroupedForTableView:tableView]) {
        if (section < (NSInteger)_sectionItems.count)
            return [_sectionItems[section] count];
        return 0;
    }
    return _displayedBerries.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return BERRY_CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BerryCell *cell = [tableView dequeueReusableCellWithIdentifier:BERRY_CELL_ID];
    if (!cell) {
        cell = [[BerryCell alloc] initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:BERRY_CELL_ID];
    }

    NSDictionary *summary = [self summaryForTableView:tableView atIndexPath:indexPath];
    if (summary) {
        [cell configureCellWithSummary:summary];
    }
    return cell;
}

#pragma mark - Section Headers

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (![self isGroupedForTableView:tableView]) return nil;
    if (section >= (NSInteger)_sectionTitles.count) return nil;

    UIView *header = [[UIView alloc] initWithFrame:
        CGRectMake(0, 0, tableView.bounds.size.width, SECTION_HEADER_HEIGHT)];
    header.backgroundColor = [UIColor colorWithWhite:0.90 alpha:0.97];

    UIView *sep = [[UIView alloc] initWithFrame:
        CGRectMake(0, SECTION_HEADER_HEIGHT - 0.5,
                   tableView.bounds.size.width, 0.5)];
    sep.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1];
    sep.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:sep];

    CGFloat labelX = 12;

    // Add colored dot for type grouping
    if ([_activeGrouping isEqualToString:@"natural_gift_type"]) {
        NSString *title = _sectionTitles[section];
        NSRange parenRange = [title rangeOfString:@" ("];
        NSString *typeName = (parenRange.location != NSNotFound)
            ? [[title substringToIndex:parenRange.location] lowercaseString]
            : [title lowercaseString];

        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(12, 8, 12, 12)];
        dot.backgroundColor = [PokemonType colorForTypeName:typeName];
        dot.layer.cornerRadius = 2;
        [header addSubview:dot];
        labelX = 30;
    }

    UILabel *label = [[UILabel alloc] initWithFrame:
        CGRectMake(labelX, 0, tableView.bounds.size.width - labelX - 12,
                   SECTION_HEADER_HEIGHT)];
    label.text = _sectionTitles[section];
    label.font = [UIFont boldSystemFontOfSize:13];
    label.textColor = [UIColor colorWithWhite:0.30 alpha:1];
    label.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.75];
    label.shadowOffset = CGSizeMake(0, 1);
    label.backgroundColor = [UIColor clearColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:label];

    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self isGroupedForTableView:tableView]) return SECTION_HEADER_HEIGHT;
    return 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (![self isGroupedForTableView:tableView]) return nil;
    if (_sectionTitles.count < 4) return nil;

    if ([_activeGrouping isEqualToString:@"natural_gift_type"]) {
        NSMutableArray *idx = [NSMutableArray array];
        for (NSString *title in _sectionTitles) {
            NSRange parenRange = [title rangeOfString:@" ("];
            NSString *name = (parenRange.location != NSNotFound)
                ? [title substringToIndex:parenRange.location]
                : title;
            if (name.length >= 3)
                [idx addObject:[[name substringToIndex:3] uppercaseString]];
            else
                [idx addObject:[name uppercaseString]];
        }
        return idx;
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView
    sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSDictionary *summary = [self summaryForTableView:tableView atIndexPath:indexPath];
    if (!summary) return;

    NSInteger berryID = [summary[@"id"] integerValue];

    BerryDetailVC *detailVC = [[BerryDetailVC alloc] init];
    detailVC.berryID = berryID;
    UINavigationController *detailNav = [[UINavigationController alloc]
        initWithRootViewController:detailVC];

    UISplitViewController *splitVC = self.splitViewController;
    if (splitVC) {
        splitVC.viewControllers = @[splitVC.viewControllers[0], detailNav];
    } else {
        [self.navigationController pushViewController:detailVC animated:YES];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
    shouldReloadTableForSearchString:(NSString *)searchString {
    self.filteredBerries = [[DataManager sharedManager]
        searchBerriesWithQuery:searchString
                        types:_filterState.selectedTypes
                       sortBy:_filterState.sortBy];
    if (_filterState.showFavouritesOnly) {
        self.filteredBerries = [[DataManager sharedManager]
            filterSummaries:self.filteredBerries byFavouritesOfType:@"berries"];
    }
    return YES;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    self.filteredBerries = @[];
}

@end
