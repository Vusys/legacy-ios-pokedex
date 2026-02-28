#import "MoveListVC.h"
#import "MoveCell.h"
#import "MoveDetailVC.h"
#import "DataManager.h"
#import "FilterState.h"
#import "FilterPopoverVC.h"
#import <QuartzCore/QuartzCore.h>

#define MOVE_CELL_HEIGHT 50
#define MOVE_CELL_ID @"MoveCell"

@interface MoveListVC () <UISearchDisplayDelegate, UISearchBarDelegate>
@property (nonatomic, strong) NSArray *allMoves;
@property (nonatomic, strong) NSArray *displayedMoves;
@property (nonatomic, strong) NSArray *filteredMoves;
@property (nonatomic, strong) UISearchDisplayController *searchDC;
@property (nonatomic, strong) FilterState *filterState;
@property (nonatomic, strong) UIPopoverController *filterPopover;
@property (nonatomic, strong) UIBarButtonItem *filterButton;
@end

@implementation MoveListVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Moves";
    self.filterState = [[FilterState alloc] init];
    self.allMoves = [[DataManager sharedManager] allMoveSummaries];
    self.displayedMoves = self.allMoves;
    self.filteredMoves = @[];

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
    searchBar.placeholder = @"Search Moves";
    searchBar.delegate = self;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [headerWrapper addSubview:searchBar];

    // Column labels
    UIView *colBar = [[UIView alloc] initWithFrame:
        CGRectMake(0, 44, self.view.bounds.size.width, 24)];
    colBar.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1];
    colBar.clipsToBounds = YES;

    CGFloat statsRight = self.view.bounds.size.width - 8;
    CGFloat statColW = 44;
    NSArray *colNames = @[@"PP", @"Acc", @"Pow"];
    for (int i = 0; i < 3; i++) {
        CGFloat x = statsRight - statColW * (3 - i);
        UILabel *col = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, statColW, 24)];
        col.text = colNames[i];
        col.font = [UIFont boldSystemFontOfSize:10];
        col.textColor = [UIColor grayColor];
        col.textAlignment = NSTextAlignmentCenter;
        col.backgroundColor = [UIColor clearColor];
        col.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [colBar addSubview:col];
    }
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
}

- (void)styleNavBar {
    CGSize navSize = CGSizeMake(1, 44);
    UIGraphicsBeginImageContextWithOptions(navSize, YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] = {
        0.15, 0.25, 0.50, 1.0,   // dark blue top
        0.25, 0.40, 0.65, 1.0    // lighter blue bottom
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
    filterVC.filterMode = @"moves";
    filterVC.delegate = self;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (_filterPopover && _filterPopover.isPopoverVisible) {
            [_filterPopover dismissPopoverAnimated:YES];
            return;
        }
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
    [self recomputeDisplayedMoves];
    [self updateFilterButtonTitle];
    [self.tableView reloadData];
}

- (void)recomputeDisplayedMoves {
    if (![_filterState hasActiveFilters] &&
        [_filterState.sortBy isEqualToString:@"number"]) {
        self.displayedMoves = self.allMoves;
    } else {
        self.displayedMoves = [[DataManager sharedManager]
            searchMovesWithQuery:nil
                           types:_filterState.selectedTypes
                     generations:_filterState.selectedGenerations
                   damageClasses:_filterState.selectedCategories
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

- (NSArray *)movesForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.filteredMoves;
    }
    return self.displayedMoves;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self movesForTableView:tableView].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return MOVE_CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MoveCell *cell = [tableView dequeueReusableCellWithIdentifier:MOVE_CELL_ID];
    if (!cell) {
        cell = [[MoveCell alloc] initWithStyle:UITableViewCellStyleDefault
                               reuseIdentifier:MOVE_CELL_ID];
    }

    NSArray *data = [self movesForTableView:tableView];
    if (indexPath.row < (NSInteger)data.count) {
        [cell configureCellWithSummary:data[indexPath.row]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSArray *data = [self movesForTableView:tableView];
    if (indexPath.row >= (NSInteger)data.count) return;

    NSDictionary *summary = data[indexPath.row];
    NSInteger moveID = [summary[@"id"] integerValue];

    MoveDetailVC *detailVC = [[MoveDetailVC alloc] init];
    detailVC.moveID = moveID;
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
    self.filteredMoves = [[DataManager sharedManager]
        searchMovesWithQuery:searchString
                       types:_filterState.selectedTypes
                 generations:_filterState.selectedGenerations
               damageClasses:_filterState.selectedCategories
                      sortBy:_filterState.sortBy];
    return YES;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    self.filteredMoves = @[];
}

@end
