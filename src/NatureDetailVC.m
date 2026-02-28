#import "NatureDetailVC.h"
#import "Nature.h"
#import "DataManager.h"
#import "KeyValueCell.h"
#import "TextBlockCell.h"
#import "DetailConstants.h"

@interface NatureDetailVC ()
@property (nonatomic, strong) Nature *nature;
@end

@implementation NatureDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.natureID > 0) {
        [self loadNature];
        self.title = self.nature.name ?: @"Nature";
        [self buildSections];
        [self setupHeaderView];
        [self.tableView reloadData];
    } else {
        [self showEmptyState];
    }
}

- (BOOL)hasData {
    return self.nature != nil;
}

- (void)loadNature {
    NSArray *summaries = [[DataManager sharedManager] allNatureSummaries];
    for (NSDictionary *dict in summaries) {
        if ([dict[@"id"] integerValue] == self.natureID) {
            self.nature = [Nature natureFromDictionary:dict];
            break;
        }
    }
}

- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom {
    top[0] = 0.45; top[1] = 0.25; top[2] = 0.55; top[3] = 1.0;
    bottom[0] = 0.60; bottom[1] = 0.35; bottom[2] = 0.70; bottom[3] = 1.0;
}

- (NSString *)emptyStateText {
    return @"Select a Nature";
}

#pragma mark - Header View

- (void)setupHeaderView {
    if (!self.nature) return;
    NSLog(@"[DEBUG] NatureDetailVC setupHeaderView: tableWidth=%.0f", self.tableView.bounds.size.width);

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
        self.tableView.bounds.size.width, 70)];
    header.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(DETAIL_CELL_PADDING, 14, header.bounds.size.width - DETAIL_CELL_PADDING * 2, 28)];
    nameLabel.text = self.nature.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:nameLabel];

    if (self.nature.isNeutral) {
        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(DETAIL_CELL_PADDING, 48, 200, 20)];
        subtitleLabel.text = @"Neutral Nature";
        subtitleLabel.font = [UIFont systemFontOfSize:14];
        subtitleLabel.textColor = [UIColor grayColor];
        subtitleLabel.backgroundColor = [UIColor clearColor];
        [header addSubview:subtitleLabel];
    }

    self.tableView.tableHeaderView = header;
}

#pragma mark - Build Sections

- (void)buildSections {
    if (!self.nature) {
        self.sections = @[];
        return;
    }

    NSMutableArray *sects = [[NSMutableArray alloc] init];

    // Section 0: Stat Effects
    {
        NSMutableArray *rows = [[NSMutableArray alloc] init];
        if (self.nature.isNeutral) {
            [rows addObject:@{
                @"type": @"text",
                @"text": @"This nature has no stat effect.",
                @"font": @"italic",
                @"height": @(44)
            }];
        } else {
            [rows addObject:@{
                @"type": @"keyvalue",
                @"key": @"+10%",
                @"value": [self.nature increasedStatDisplay],
                @"valueColor": @"green"
            }];
            [rows addObject:@{
                @"type": @"keyvalue",
                @"key": @"\u221210%",
                @"value": [self.nature decreasedStatDisplay],
                @"valueColor": @"red"
            }];
        }
        [sects addObject:@{@"title": @"Stat Effects", @"rows": rows}];
    }

    // Section 1: Flavor Preference
    {
        NSMutableArray *rows = [[NSMutableArray alloc] init];
        if (self.nature.isNeutral) {
            [rows addObject:@{
                @"type": @"text",
                @"text": @"This nature has no flavor preference.",
                @"font": @"italic",
                @"height": @(44)
            }];
        } else {
            [rows addObject:@{
                @"type": @"keyvalue",
                @"key": @"Likes",
                @"value": [self.nature likesFlavorDisplay]
            }];
            [rows addObject:@{
                @"type": @"keyvalue",
                @"key": @"Dislikes",
                @"value": [self.nature hatesFlavorDisplay]
            }];
        }
        [sects addObject:@{@"title": @"Flavor Preference", @"rows": rows}];
    }

    self.sections = sects;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *section = self.sections[(NSUInteger)indexPath.section];
    NSArray *rows = section[@"rows"];
    NSDictionary *row = rows[(NSUInteger)indexPath.row];
    NSString *type = row[@"type"];

    if ([type isEqualToString:@"text"]) {
        static NSString *textID = @"TextBlockCell";
        TextBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:textID];
        if (!cell) {
            cell = [[TextBlockCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:textID];
        }
        [cell configureWithText:row[@"text"]
                           font:[UIFont italicSystemFontOfSize:14]
                          color:[UIColor grayColor]];
        return cell;
    }

    // keyvalue
    static NSString *kvID = @"KeyValueCell";
    KeyValueCell *cell = [tableView dequeueReusableCellWithIdentifier:kvID];
    if (!cell) {
        cell = [[KeyValueCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:kvID];
    }

    NSString *colorKey = row[@"valueColor"];
    if ([colorKey isEqualToString:@"green"]) {
        [cell configureWithKey:row[@"key"] value:row[@"value"]
                    valueColor:[UIColor colorWithRed:0.2 green:0.65 blue:0.2 alpha:1]
                     valueFont:[UIFont boldSystemFontOfSize:16]];
    } else if ([colorKey isEqualToString:@"red"]) {
        [cell configureWithKey:row[@"key"] value:row[@"value"]
                    valueColor:[UIColor colorWithRed:0.85 green:0.2 blue:0.2 alpha:1]
                     valueFont:[UIFont boldSystemFontOfSize:16]];
    } else {
        [cell configureWithKey:row[@"key"] value:row[@"value"]];
    }
    return cell;
}

@end
