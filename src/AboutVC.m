#import "AboutVC.h"
#import "DataManager.h"
#import "KeyValueCell.h"
#import "DetailConstants.h"

@implementation AboutVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"About";
    [self buildSections];
    [self setupHeaderView];
    [self.tableView reloadData];
}

- (BOOL)hasData {
    return YES;
}

- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom {
    top[0] = 0.25; top[1] = 0.25; top[2] = 0.30; top[3] = 1.0;
    bottom[0] = 0.40; bottom[1] = 0.40; bottom[2] = 0.45; bottom[3] = 1.0;
}

#pragma mark - Header View

- (void)setupHeaderView {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
        self.tableView.bounds.size.width, 80)];
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    // App title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(DETAIL_CELL_PADDING, 14,
                   header.bounds.size.width - DETAIL_CELL_PADDING * 2, 30)];
    titleLabel.text = @"Pok\u00e9dex";
    titleLabel.font = [UIFont boldSystemFontOfSize:26];
    titleLabel.textColor = [UIColor darkTextColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:titleLabel];

    // Version subtitle
    NSString *version = [[NSBundle mainBundle]
        objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0";
    NSString *build = [[NSBundle mainBundle]
        objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"1";
    NSString *versionStr = [NSString stringWithFormat:@"Version %@ (Build %@)",
                            version, build];

    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(DETAIL_CELL_PADDING, 48,
                   header.bounds.size.width - DETAIL_CELL_PADDING * 2, 20)];
    subtitleLabel.text = versionStr;
    subtitleLabel.font = [UIFont systemFontOfSize:14];
    subtitleLabel.textColor = [UIColor grayColor];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:subtitleLabel];

    self.tableView.tableHeaderView = header;
}

#pragma mark - Build Sections

- (void)buildSections {
    NSMutableArray *sects = [[NSMutableArray alloc] init];
    NSDictionary *stats = [[DataManager sharedManager] precomputedStats];

    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    [fmt setNumberStyle:NSNumberFormatterDecimalStyle];

    // Section 0: Database
    {
        NSMutableArray *rows = [[NSMutableArray alloc] init];

        NSArray *entries = @[
            @[@"Pok\u00e9mon",   stats[@"pokemon_count"]  ?: @0],
            @[@"Moves",      stats[@"move_count"]     ?: @0],
            @[@"Abilities",  stats[@"ability_count"]  ?: @0],
            @[@"Items",      stats[@"item_count"]     ?: @0],
            @[@"Natures",    stats[@"nature_count"]   ?: @0],
            @[@"Berries",    stats[@"berry_count"]    ?: @0],
            @[@"Types",      stats[@"type_count"]     ?: @0],
            @[@"Egg Groups", stats[@"egg_group_count"] ?: @0],
            @[@"Locations",  stats[@"location_count"] ?: @0],
            @[@"Images",     stats[@"image_count"]    ?: @0],
        ];

        for (NSArray *entry in entries) {
            [rows addObject:@{
                @"type": @"keyvalue",
                @"key": entry[0],
                @"value": [fmt stringFromNumber:entry[1]]
            }];
        }
        [sects addObject:@{@"title": @"Database", @"rows": rows}];
    }

    // Section 1: App Info
    {
        NSMutableArray *rows = [[NSMutableArray alloc] init];
        [rows addObject:@{
            @"type": @"keyvalue",
            @"key": @"Data Source",
            @"value": @"Pok\u00e9API v2"
        }];
        [rows addObject:@{
            @"type": @"keyvalue",
            @"key": @"Target",
            @"value": @"iOS 6.0+"
        }];
        [rows addObject:@{
            @"type": @"keyvalue",
            @"key": @"Architecture",
            @"value": @"ARMv7"
        }];
        [sects addObject:@{@"title": @"App Info", @"rows": rows}];
    }

    self.sections = sects;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *section = self.sections[(NSUInteger)indexPath.section];
    NSArray *rows = section[@"rows"];
    NSDictionary *row = rows[(NSUInteger)indexPath.row];

    static NSString *kvID = @"KeyValueCell";
    KeyValueCell *cell = [tableView dequeueReusableCellWithIdentifier:kvID];
    if (!cell) {
        cell = [[KeyValueCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:kvID];
    }
    [cell configureWithKey:row[@"key"] value:row[@"value"]];
    return cell;
}

@end
