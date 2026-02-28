#import "NatureListVC.h"
#import "NatureCell.h"
#import "NatureDetailVC.h"
#import "DataManager.h"
#import <QuartzCore/QuartzCore.h>

#define NATURE_CELL_HEIGHT 50
#define NATURE_CELL_ID @"NatureCell"

@interface NatureListVC () <UISearchDisplayDelegate, UISearchBarDelegate>
@property (nonatomic, strong) NSArray *allNatures;
@property (nonatomic, strong) NSArray *displayedNatures;
@property (nonatomic, strong) NSArray *filteredNatures;
@property (nonatomic, strong) UISearchDisplayController *searchDC;
@end

@implementation NatureListVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Natures";
    self.allNatures = [[DataManager sharedManager] allNatureSummaries];
    self.displayedNatures = self.allNatures;
    self.filteredNatures = @[];

    [self styleNavBar];

    // Search bar as table header
    UISearchBar *searchBar = [[UISearchBar alloc]
        initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    searchBar.placeholder = @"Search Natures";
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
        0.45, 0.25, 0.55, 1.0,   // purple top
        0.60, 0.35, 0.70, 1.0    // lighter purple bottom
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

- (NSArray *)naturesForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.filteredNatures;
    }
    return self.displayedNatures;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self naturesForTableView:tableView].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NATURE_CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NatureCell *cell = [tableView dequeueReusableCellWithIdentifier:NATURE_CELL_ID];
    if (!cell) {
        cell = [[NatureCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:NATURE_CELL_ID];
    }

    NSArray *data = [self naturesForTableView:tableView];
    if (indexPath.row < (NSInteger)data.count) {
        [cell configureCellWithSummary:data[indexPath.row]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSArray *data = [self naturesForTableView:tableView];
    if (indexPath.row >= (NSInteger)data.count) return;

    NSDictionary *summary = data[indexPath.row];
    NSInteger natureID = [summary[@"id"] integerValue];

    NatureDetailVC *detailVC = [[NatureDetailVC alloc] init];
    detailVC.natureID = natureID;
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
    self.filteredNatures = [[DataManager sharedManager]
        searchNaturesWithQuery:searchString
                        sortBy:@"number"];
    return YES;
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    self.filteredNatures = @[];
}

@end
