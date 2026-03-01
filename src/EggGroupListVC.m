#import "EggGroupListVC.h"
#import "EggGroupCell.h"
#import "EggGroupDetailVC.h"
#import "DataManager.h"
#import "FilterState.h"
#import "FilterPopoverVC.h"
#import "NavBarStyle.h"
#import <QuartzCore/QuartzCore.h>

#define EGGGROUP_CELL_HEIGHT 44
#define EGGGROUP_CELL_ID @"EggGroupCell"

@interface EggGroupListVC () <UISearchDisplayDelegate, UISearchBarDelegate>
@property (nonatomic, strong) NSArray *allEggGroups;
@property (nonatomic, strong) NSArray *displayedEggGroups;
@property (nonatomic, strong) NSArray *filteredEggGroups;
@property (nonatomic, strong) UISearchDisplayController *searchDC;
@property (nonatomic, strong) FilterState *filterState;
@property (nonatomic, strong) UIPopoverController *filterPopover;
@property (nonatomic, strong) UIBarButtonItem *filterButton;
@end

@implementation EggGroupListVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Egg Groups";
    self.filterState = [[FilterState alloc] init];
    self.allEggGroups = [[DataManager sharedManager] allEggGroupSummaries];
    self.displayedEggGroups = self.allEggGroups;
    self.filteredEggGroups = @[];

    [self styleNavBar];

    // Filter button in nav bar
    _filterButton = [[UIBarButtonItem alloc]
        initWithTitle:@"Filter"
                style:UIBarButtonItemStyleBordered
               target:self
               action:@selector(showFilterPopover:)];
    self.navigationItem.rightBarButtonItem = _filterButton;

    // Search bar as table header
    UISearchBar *searchBar = [[UISearchBar alloc]
        initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    searchBar.placeholder = @"Search Egg Groups";
    searchBar.delegate = self;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.tableView.tableHeaderView = searchBar;

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
        [self recomputeDisplayedEggGroups];
        [self.tableView reloadData];
    }
}

- (void)styleNavBar {
    [self.navigationController.navigationBar
        setBackgroundImage:NavBarGradientImage(0.15, 0.45, 0.50, 0.25, 0.60, 0.65)
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
    filterVC.filterMode = @"egg_groups";
    filterVC.delegate = self;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (_filterPopover && _filterPopover.isPopoverVisible) {
            [_filterPopover dismissPopoverAnimated:YES];
            return;
        }
        [filterVC view];
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
    [self recomputeDisplayedEggGroups];
    [self updateFilterButtonTitle];
    [self.tableView reloadData];
}

- (void)recomputeDisplayedEggGroups {
    if (![_filterState hasActiveFilters] &&
        [_filterState.sortBy isEqualToString:@"number"]) {
        self.displayedEggGroups = self.allEggGroups;
    } else {
        self.displayedEggGroups = [[DataManager sharedManager]
            searchEggGroupsWithQuery:nil
                              sortBy:_filterState.sortBy];
    }
    if (_filterState.showFavouritesOnly) {
        self.displayedEggGroups = [[DataManager sharedManager]
            filterSummaries:self.displayedEggGroups byFavouritesOfType:@"egg_groups"];
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

- (NSArray *)eggGroupsForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.filteredEggGroups;
    }
    return self.displayedEggGroups;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self eggGroupsForTableView:tableView].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return EGGGROUP_CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EggGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:EGGGROUP_CELL_ID];
    if (!cell) {
        cell = [[EggGroupCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:EGGGROUP_CELL_ID];
    }

    NSArray *data = [self eggGroupsForTableView:tableView];
    if (indexPath.row < (NSInteger)data.count) {
        [cell configureCellWithSummary:data[indexPath.row]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSArray *data = [self eggGroupsForTableView:tableView];
    if (indexPath.row >= (NSInteger)data.count) return;

    NSDictionary *summary = data[indexPath.row];
    NSInteger eggGroupID = [summary[@"id"] integerValue];

    EggGroupDetailVC *detailVC = [[EggGroupDetailVC alloc] init];
    detailVC.eggGroupID = eggGroupID;
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
    self.filteredEggGroups = [[DataManager sharedManager]
        searchEggGroupsWithQuery:searchString
                          sortBy:_filterState.sortBy];
    if (_filterState.showFavouritesOnly) {
        self.filteredEggGroups = [[DataManager sharedManager]
            filterSummaries:self.filteredEggGroups byFavouritesOfType:@"egg_groups"];
    }
    return YES;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    self.filteredEggGroups = @[];
}

@end
