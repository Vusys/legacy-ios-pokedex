#import "RegionListVC.h"
#import "LocationListVC.h"
#import "DataManager.h"
#import "NavBarStyle.h"
#import <QuartzCore/QuartzCore.h>

#define REGION_CELL_ID @"RegionCell"

@interface RegionListVC ()
@property (nonatomic, strong) NSArray *regions; // array of dicts: name, location_count
@end

@implementation RegionListVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Locations";
    [self styleNavBar];
    self.regions = [[DataManager sharedManager] allRegions];
}

- (void)styleNavBar {
    [self.navigationController.navigationBar
        setBackgroundImage:NavBarGradientImage(0.30, 0.45, 0.20, 0.45, 0.60, 0.30)
             forBarMetrics:UIBarMetricsDefault];

    self.navigationController.navigationBar.titleTextAttributes = @{
        UITextAttributeTextColor: [UIColor whiteColor],
        UITextAttributeTextShadowColor: [UIColor colorWithWhite:0 alpha:0.6],
        UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
        UITextAttributeFont: [UIFont boldSystemFontOfSize:20]
    };
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.regions.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:REGION_CELL_ID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                       reuseIdentifier:REGION_CELL_ID];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }

    NSDictionary *region = self.regions[indexPath.row];
    cell.textLabel.text = region[@"name"];
    NSInteger count = [region[@"location_count"] integerValue];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld locations",
                                  (long)count];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSDictionary *region = self.regions[indexPath.row];
    LocationListVC *listVC = [[LocationListVC alloc] init];
    listVC.regionName = region[@"name"];

    [self.navigationController pushViewController:listVC animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
