#import "ItemListVC.h"
#import "ItemCell.h"
#import "ItemDetailVC.h"
#import "DataManager.h"
#import "FilterState.h"
#import "FilterPopoverVC.h"
#import "NavBarStyle.h"
#import <QuartzCore/QuartzCore.h>

#define ITEM_CELL_HEIGHT 50
#define ITEM_CELL_ID @"ItemCell"

@interface ItemListVC () <UISearchDisplayDelegate, UISearchBarDelegate>
@property (nonatomic, strong) NSArray *allItems;
@property (nonatomic, strong) NSArray *displayedItems;
@property (nonatomic, strong) NSArray *filteredItems;
@property (nonatomic, strong) UISearchDisplayController *searchDC;
@property (nonatomic, strong) FilterState *filterState;
@property (nonatomic, strong) UIPopoverController *filterPopover;
@property (nonatomic, strong) UIBarButtonItem *filterButton;
@end

@implementation ItemListVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!self.title) self.title = @"Items";
    self.filterState = [[FilterState alloc] init];

    NSArray *all = [[DataManager sharedManager] allItemSummaries];
    if (_categoryFilter.length > 0) {
        NSMutableArray *filtered = [[NSMutableArray alloc] init];
        for (NSDictionary *item in all) {
            if ([item[@"category"] isEqualToString:_categoryFilter]) {
                [filtered addObject:item];
            }
        }
        self.allItems = filtered;
    } else {
        self.allItems = all;
    }
    self.displayedItems = self.allItems;
    self.filteredItems = @[];

    [self styleNavBar];

    // Filter button in nav bar
    _filterButton = [[UIBarButtonItem alloc]
        initWithTitle:@"Filter"
                style:UIBarButtonItemStyleBordered
               target:self
               action:@selector(showFilterPopover:)];
    self.navigationItem.rightBarButtonItem = _filterButton;

    // Column headers
    UIView *headerWrapper = [[UIView alloc] initWithFrame:
        CGRectMake(0, 0, self.view.bounds.size.width, 44 + 24)];
    headerWrapper.backgroundColor = [UIColor clearColor];
    headerWrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    // Search bar
    UISearchBar *searchBar = [[UISearchBar alloc]
        initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    searchBar.placeholder = @"Search Items";
    searchBar.delegate = self;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBar.tintColor = [UIColor colorWithRed:0.75 green:0.50 blue:0.15 alpha:1];
    [headerWrapper addSubview:searchBar];

    // Column label bar
    UIView *colBar = [[UIView alloc] initWithFrame:
        CGRectMake(0, 44, self.view.bounds.size.width, 24)];
    colBar.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1];
    colBar.clipsToBounds = YES;

    UILabel *costCol = [[UILabel alloc] initWithFrame:
        CGRectMake(self.view.bounds.size.width - 78, 0, 70, 24)];
    costCol.text = @"Cost";
    costCol.font = [UIFont boldSystemFontOfSize:10];
    costCol.textColor = [UIColor grayColor];
    costCol.textAlignment = NSTextAlignmentRight;
    costCol.backgroundColor = [UIColor clearColor];
    costCol.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [colBar addSubview:costCol];

    UIView *colSep = [[UIView alloc] initWithFrame:
        CGRectMake(0, 23.5, self.view.bounds.size.width, 0.5)];
    colSep.backgroundColor = [UIColor colorWithWhite:0.80 alpha:1];
    colSep.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [colBar addSubview:colSep];
    colBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [headerWrapper addSubview:colBar];

    self.tableView.tableHeaderView = headerWrapper;

    self.searchDC = [[UISearchDisplayController alloc]
        initWithSearchBar:searchBar contentsController:self];
    self.searchDC.delegate = self;
    self.searchDC.searchResultsDataSource = self;
    self.searchDC.searchResultsDelegate = self;

    [[NSNotificationCenter defaultCenter]
        addObserver:self selector:@selector(favouritesDidChange:)
               name:FavouritesChangedNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)favouritesDidChange:(NSNotification *)note {
    if (_filterState.showFavouritesOnly) {
        [self recomputeDisplayedItems];
        [self.tableView reloadData];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self styleNavBar];
}

- (void)styleNavBar {
    [self.navigationController.navigationBar
        setBackgroundImage:NavBarGradientImage(0.60, 0.35, 0.10, 0.75, 0.50, 0.15)
             forBarMetrics:UIBarMetricsDefault];

    self.navigationController.navigationBar.titleTextAttributes = @{
        UITextAttributeTextColor: [UIColor whiteColor],
        UITextAttributeTextShadowColor: [UIColor colorWithWhite:0 alpha:0.6],
        UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
        UITextAttributeFont: [UIFont boldSystemFontOfSize:20]
    };
}

#pragma mark - Filter

- (void)showFilterPopover:(UIBarButtonItem *)sender {
    FilterPopoverVC *filterVC = [[FilterPopoverVC alloc] init];
    filterVC.filterState = [_filterState copy];
    filterVC.filterMode = @"items";
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
    [self recomputeDisplayedItems];
    [self updateFilterButtonTitle];
    [self.tableView reloadData];
}

- (void)recomputeDisplayedItems {
    if (![_filterState hasActiveFilters] &&
        [_filterState.sortBy isEqualToString:@"number"]) {
        self.displayedItems = self.allItems;
    } else {
        NSArray *sorted = [[DataManager sharedManager]
            searchItemsWithQuery:nil
                          sortBy:_filterState.sortBy];
        if (_categoryFilter.length > 0) {
            sorted = [self filterItems:sorted byCategory:_categoryFilter];
        }
        self.displayedItems = sorted;
    }
    if (_filterState.showFavouritesOnly) {
        self.displayedItems = [[DataManager sharedManager]
            filterSummaries:self.displayedItems byFavouritesOfType:@"items"];
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

#pragma mark - UITableViewDataSource

- (NSArray *)itemsForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.filteredItems;
    }
    return self.displayedItems;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self itemsForTableView:tableView].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ITEM_CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ItemCell *cell = [tableView dequeueReusableCellWithIdentifier:ITEM_CELL_ID];
    if (!cell) {
        cell = [[ItemCell alloc] initWithStyle:UITableViewCellStyleDefault
                               reuseIdentifier:ITEM_CELL_ID];
    }

    NSArray *data = [self itemsForTableView:tableView];
    if (indexPath.row < (NSInteger)data.count) {
        [cell configureCellWithSummary:data[indexPath.row]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSArray *data = [self itemsForTableView:tableView];
    if (indexPath.row >= (NSInteger)data.count) return;

    NSDictionary *summary = data[indexPath.row];
    NSInteger itemID = [summary[@"id"] integerValue];

    ItemDetailVC *detailVC = [[ItemDetailVC alloc] init];
    detailVC.itemID = itemID;
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

#pragma mark - Category Filtering

- (NSArray *)filterItems:(NSArray *)items byCategory:(NSString *)category {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSDictionary *item in items) {
        if ([item[@"category"] isEqualToString:category]) {
            [result addObject:item];
        }
    }
    return result;
}

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
    shouldReloadTableForSearchString:(NSString *)searchString {
    NSArray *results = [[DataManager sharedManager]
        searchItemsWithQuery:searchString
                      sortBy:_filterState.sortBy];
    if (_categoryFilter.length > 0) {
        results = [self filterItems:results byCategory:_categoryFilter];
    }
    if (_filterState.showFavouritesOnly) {
        results = [[DataManager sharedManager]
            filterSummaries:results byFavouritesOfType:@"items"];
    }
    self.filteredItems = results;
    return YES;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    self.filteredItems = @[];
}

@end
