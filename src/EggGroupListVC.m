#import "EggGroupListVC.h"
#import "EggGroupCell.h"
#import "EggGroupDetailVC.h"
#import "DataManager.h"
#import <QuartzCore/QuartzCore.h>

#define EGGGROUP_CELL_HEIGHT 44
#define EGGGROUP_CELL_ID @"EggGroupCell"

@interface EggGroupListVC () <UISearchDisplayDelegate, UISearchBarDelegate>
@property (nonatomic, strong) NSArray *allEggGroups;
@property (nonatomic, strong) NSArray *displayedEggGroups;
@property (nonatomic, strong) NSArray *filteredEggGroups;
@property (nonatomic, strong) UISearchDisplayController *searchDC;
@end

@implementation EggGroupListVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Egg Groups";
    self.allEggGroups = [[DataManager sharedManager] allEggGroupSummaries];
    self.displayedEggGroups = self.allEggGroups;
    self.filteredEggGroups = @[];

    [self styleNavBar];

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
}

- (void)styleNavBar {
    CGSize navSize = CGSizeMake(1, 44);
    UIGraphicsBeginImageContextWithOptions(navSize, YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] = {
        0.15, 0.45, 0.50, 1.0,   // teal top
        0.25, 0.60, 0.65, 1.0    // lighter teal bottom
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
                          sortBy:@"number"];
    return YES;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    self.filteredEggGroups = @[];
}

@end
