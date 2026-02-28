#import "AbilityListVC.h"
#import "AbilityCell.h"
#import "AbilityDetailVC.h"
#import "DataManager.h"
#import "FilterState.h"
#import "FilterPopoverVC.h"
#import <QuartzCore/QuartzCore.h>

#define ABILITY_CELL_HEIGHT 44
#define ABILITY_CELL_ID @"AbilityCell"

@interface AbilityListVC () <UISearchDisplayDelegate, UISearchBarDelegate>
@property (nonatomic, strong) NSArray *allAbilities;
@property (nonatomic, strong) NSArray *displayedAbilities;
@property (nonatomic, strong) NSArray *filteredAbilities;
@property (nonatomic, strong) UISearchDisplayController *searchDC;
@property (nonatomic, strong) FilterState *filterState;
@property (nonatomic, strong) UIPopoverController *filterPopover;
@property (nonatomic, strong) UIBarButtonItem *filterButton;
@end

@implementation AbilityListVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Abilities";
    self.filterState = [[FilterState alloc] init];
    self.allAbilities = [[DataManager sharedManager] allAbilitySummaries];
    self.displayedAbilities = self.allAbilities;
    self.filteredAbilities = @[];

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
    searchBar.placeholder = @"Search Abilities";
    searchBar.delegate = self;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.tableView.tableHeaderView = searchBar;

    self.searchDC = [[UISearchDisplayController alloc]
        initWithSearchBar:searchBar contentsController:self];
    self.searchDC.delegate = self;
    self.searchDC.searchResultsDataSource = self;
    self.searchDC.searchResultsDelegate = self;
}

- (void)styleNavBar {
    CGSize navSize = CGSizeMake(1, 44);
    UIGraphicsBeginImageContextWithOptions(navSize, YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] = {
        0.15, 0.40, 0.20, 1.0,   // dark green top
        0.25, 0.55, 0.30, 1.0    // lighter green bottom
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
    CGContextDrawLinearGradient(ctx, gradient,
        CGPointMake(0, 0), CGPointMake(0, navSize.height), 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    UIImage *navImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self.navigationController.navigationBar setBackgroundImage:navImage
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
    filterVC.filterMode = @"abilities";
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
    [self recomputeDisplayedAbilities];
    [self updateFilterButtonTitle];
    [self.tableView reloadData];
}

- (void)recomputeDisplayedAbilities {
    if (![_filterState hasActiveFilters] &&
        [_filterState.sortBy isEqualToString:@"number"]) {
        self.displayedAbilities = self.allAbilities;
    } else {
        self.displayedAbilities = [[DataManager sharedManager]
            searchAbilitiesWithQuery:nil
                         generations:_filterState.selectedGenerations
                              sortBy:_filterState.sortBy];
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

- (NSArray *)abilitiesForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.filteredAbilities;
    }
    return self.displayedAbilities;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self abilitiesForTableView:tableView].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ABILITY_CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AbilityCell *cell = [tableView dequeueReusableCellWithIdentifier:ABILITY_CELL_ID];
    if (!cell) {
        cell = [[AbilityCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:ABILITY_CELL_ID];
    }

    NSArray *data = [self abilitiesForTableView:tableView];
    if (indexPath.row < (NSInteger)data.count) {
        [cell configureCellWithSummary:data[indexPath.row]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSArray *data = [self abilitiesForTableView:tableView];
    if (indexPath.row >= (NSInteger)data.count) return;

    NSDictionary *summary = data[indexPath.row];
    NSInteger abilityID = [summary[@"id"] integerValue];

    AbilityDetailVC *detailVC = [[AbilityDetailVC alloc] init];
    detailVC.abilityID = abilityID;
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
    self.filteredAbilities = [[DataManager sharedManager]
        searchAbilitiesWithQuery:searchString
                     generations:_filterState.selectedGenerations
                          sortBy:_filterState.sortBy];
    return YES;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    self.filteredAbilities = @[];
}

@end
