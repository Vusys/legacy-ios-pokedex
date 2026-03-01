#import "BerryDetailVC.h"
#import "Berry.h"
#import "DataManager.h"
#import "TypeBadgeView.h"
#import "TextBlockCell.h"
#import "KeyValueCell.h"
#import "FlavorBarCell.h"
#import "DetailConstants.h"

@interface BerryDetailVC ()
@property (nonatomic, strong) Berry *berry;
@end

@implementation BerryDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.berryID > 0) {
        self.berry = [[DataManager sharedManager] berryDetailWithID:self.berryID];
        self.title = self.berry.name ?: @"Berry";
        [self buildSections];
        [self setupHeaderView];
        [self.tableView reloadData];
        [self setupFavouriteButton];
    } else {
        [self showEmptyState];
    }
}

- (BOOL)hasData {
    return self.berry != nil;
}

- (NSString *)favouriteEntityType { return @"berries"; }
- (NSInteger)favouriteEntityID { return self.berryID; }

- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom {
    top[0] = 0.70; top[1] = 0.25; top[2] = 0.35; top[3] = 1.0;
    bottom[0] = 0.85; bottom[1] = 0.40; bottom[2] = 0.50; bottom[3] = 1.0;
}

- (NSString *)emptyStateText {
    return @"Select a Berry";
}

#pragma mark - Header View

- (void)setupHeaderView {
    if (!self.berry) return;
    NSLog(@"[DEBUG] BerryDetailVC setupHeaderView: tableWidth=%.0f", self.tableView.bounds.size.width);

    BOOL hasSprite = self.berry.hasSprite;
    CGFloat spriteSize = 48;
    CGFloat textX = DETAIL_CELL_PADDING + (hasSprite ? spriteSize + 10 : 0);
    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat nameLineY = pad;
    CGFloat firmnessLineY = pad + 30;
    CGFloat typeLineY = firmnessLineY + 20;

    BOOL hasType = self.berry.naturalGiftType.length > 0;
    CGFloat headerHeight = hasType ? typeLineY + [TypeBadgeView badgeHeight] + pad
                                    : firmnessLineY + 18 + pad;
    if (hasSprite) {
        headerHeight = MAX(headerHeight, pad + spriteSize + pad);
    }

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
        self.tableView.bounds.size.width, headerHeight)];

    if (hasSprite) {
        UIImageView *spriteView = [[UIImageView alloc] initWithFrame:
            CGRectMake(pad, pad, spriteSize, spriteSize)];
        spriteView.contentMode = UIViewContentModeScaleAspectFit;
        spriteView.image = [[DataManager sharedManager] spriteForBerryID:self.berry.berryID];
        [header addSubview:spriteView];
    }

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(textX, nameLineY, header.bounds.size.width - textX - pad, 28)];
    nameLabel.text = self.berry.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:nameLabel];

    UILabel *firmnessLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(textX, firmnessLineY, 200, 18)];
    firmnessLabel.text = [self.berry firmnessDisplay];
    firmnessLabel.font = [UIFont systemFontOfSize:14];
    firmnessLabel.textColor = [UIColor grayColor];
    firmnessLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:firmnessLabel];

    if (hasType) {
        TypeBadgeView *badge = [[TypeBadgeView alloc]
            initWithTypeName:self.berry.naturalGiftType];
        CGRect badgeFrame = badge.frame;
        badgeFrame.origin.x = textX;
        badgeFrame.origin.y = typeLineY;
        badge.frame = badgeFrame;
        [header addSubview:badge];

        UILabel *powerLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(textX + [TypeBadgeView badgeWidth] + 8, typeLineY,
                       120, [TypeBadgeView badgeHeight])];
        powerLabel.text = [NSString stringWithFormat:@"Power: %ld",
                           (long)self.berry.naturalGiftPower];
        powerLabel.font = [UIFont systemFontOfSize:13];
        powerLabel.textColor = [UIColor colorWithWhite:0.40 alpha:1];
        powerLabel.backgroundColor = [UIColor clearColor];
        [header addSubview:powerLabel];
    }

    self.tableView.tableHeaderView = header;
}

#pragma mark - Build Sections

- (void)buildSections {
    if (!self.berry) {
        self.sections = @[];
        return;
    }

    NSMutableArray *sects = [[NSMutableArray alloc] init];
    CGFloat tableWidth = self.tableView.bounds.size.width;

    // Effect text
    {
        NSString *effect = self.berry.effect;
        NSString *flavor = self.berry.flavorText;
        NSMutableString *text = [[NSMutableString alloc] init];
        if (effect.length > 0) [text appendString:effect];
        if (flavor.length > 0 && ![flavor isEqualToString:effect]) {
            if (text.length > 0) [text appendString:@"\n\n"];
            [text appendString:flavor];
        }
        if (text.length > 0) {
            CGFloat h = [TextBlockCell heightForText:text width:tableWidth];
            [sects addObject:@{
                @"rows": @[@{@"type": @"text", @"text": [text copy], @"height": @(h)}]
            }];
        }
    }

    // Growth Stats
    {
        NSArray *rows = @[
            @{@"type": @"keyvalue", @"key": @"Growth Time", @"value": [self.berry growthTimeDisplay]},
            @{@"type": @"keyvalue", @"key": @"Max Harvest",
              @"value": [NSString stringWithFormat:@"%ld", (long)self.berry.maxHarvest]},
            @{@"type": @"keyvalue", @"key": @"Size", @"value": [self.berry sizeDisplay]},
            @{@"type": @"keyvalue", @"key": @"Smoothness",
              @"value": [NSString stringWithFormat:@"%ld", (long)self.berry.smoothness]},
            @{@"type": @"keyvalue", @"key": @"Soil Dryness",
              @"value": [NSString stringWithFormat:@"%ld", (long)self.berry.soilDryness]},
        ];
        [sects addObject:@{@"title": @"Growth Stats", @"rows": rows}];
    }

    // Flavor Profile
    {
        NSArray *flavorNames = @[@"spicy", @"dry", @"sweet", @"bitter", @"sour"];
        BOOL hasAnyFlavor = NO;
        for (NSString *name in flavorNames) {
            if ([self.berry.flavors[name] integerValue] > 0) {
                hasAnyFlavor = YES;
                break;
            }
        }
        if (hasAnyFlavor) {
            NSDictionary *colorMap = @{
                @"spicy":  @[@0.90, @0.25, @0.20],
                @"dry":    @[@0.85, @0.75, @0.20],
                @"sweet":  @[@0.90, @0.50, @0.65],
                @"bitter": @[@0.30, @0.70, @0.35],
                @"sour":   @[@0.30, @0.55, @0.85]
            };

            NSMutableArray *rows = [[NSMutableArray alloc] init];
            for (NSString *name in flavorNames) {
                NSInteger potency = [self.berry.flavors[name] integerValue];
                NSArray *rgb = colorMap[name];
                [rows addObject:@{
                    @"type": @"flavor",
                    @"name": name,
                    @"potency": @(potency),
                    @"r": rgb[0], @"g": rgb[1], @"b": rgb[2],
                    @"height": @(DETAIL_FLAVOR_HEIGHT)
                }];
            }
            [sects addObject:@{@"title": @"Flavor Profile", @"rows": rows}];
        }
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
        [cell configureWithText:row[@"text"]];
        return cell;
    }

    if ([type isEqualToString:@"keyvalue"]) {
        static NSString *kvID = @"KeyValueCell";
        KeyValueCell *cell = [tableView dequeueReusableCellWithIdentifier:kvID];
        if (!cell) {
            cell = [[KeyValueCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:kvID];
        }
        [cell configureWithKey:row[@"key"] value:row[@"value"]];
        return cell;
    }

    // flavor
    static NSString *flavorID = @"FlavorBarCell";
    FlavorBarCell *cell = [tableView dequeueReusableCellWithIdentifier:flavorID];
    if (!cell) {
        cell = [[FlavorBarCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:flavorID];
    }
    UIColor *barColor = [UIColor colorWithRed:[row[@"r"] floatValue]
                                        green:[row[@"g"] floatValue]
                                         blue:[row[@"b"] floatValue]
                                        alpha:1];
    [cell configureWithName:row[@"name"] potency:[row[@"potency"] integerValue]
                   barColor:barColor];
    return cell;
}

@end
