#import "LocationDetailVC.h"
#import "Location.h"
#import "DataManager.h"
#import "DetailSpriteCell.h"
#import "DetailConstants.h"

#define LOCATION_MAX_POKEMON_PER_VERSION 20

@interface LocationDetailVC ()
@property (nonatomic, strong) Location *location;
@end

@implementation LocationDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.locationID > 0) {
        self.location = [[DataManager sharedManager] locationDetailWithID:self.locationID];
        self.title = self.location.name ?: @"Location";
        [self buildSections];
        [self setupHeaderView];
        [self.tableView reloadData];
        [self setupFavouriteButton];
    } else {
        [self showEmptyState];
    }
}

- (BOOL)hasData {
    return self.location != nil;
}

- (NSString *)favouriteEntityType { return @"locations"; }
- (NSInteger)favouriteEntityID { return self.locationID; }

- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom {
    top[0] = 0.30; top[1] = 0.45; top[2] = 0.20; top[3] = 1.0;
    bottom[0] = 0.45; bottom[1] = 0.60; bottom[2] = 0.30; bottom[3] = 1.0;
}

- (NSString *)emptyStateText {
    return @"Select a Location";
}

#pragma mark - Header View

- (void)setupHeaderView {
    if (!self.location) return;

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
        self.tableView.bounds.size.width, 70)];

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(DETAIL_CELL_PADDING, 14, header.bounds.size.width - DETAIL_CELL_PADDING * 2, 28)];
    nameLabel.text = self.location.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:nameLabel];

    UILabel *regionLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(DETAIL_CELL_PADDING, 48, 300, 20)];
    regionLabel.text = self.location.region;
    regionLabel.font = [UIFont systemFontOfSize:14];
    regionLabel.textColor = [UIColor grayColor];
    regionLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:regionLabel];

    self.tableView.tableHeaderView = header;
}

#pragma mark - Build Sections

- (void)buildSections {
    if (!self.location) {
        self.sections = @[];
        return;
    }

    BOOL multiArea = self.location.areas.count > 1;
    NSMutableArray *allSections = [[NSMutableArray alloc] init];

    for (NSDictionary *versionEntry in self.location.versions) {
        NSString *versionName = versionEntry[@"version"] ?: @"Unknown";
        NSArray *pokemon = versionEntry[@"pokemon"] ?: @[];
        if (pokemon.count == 0) continue;

        NSMutableArray *rows = [[NSMutableArray alloc] init];
        NSInteger limit = MIN((NSInteger)pokemon.count, LOCATION_MAX_POKEMON_PER_VERSION);

        for (NSInteger i = 0; i < limit; i++) {
            NSDictionary *p = pokemon[i];
            NSString *method = p[@"method"] ?: @"";
            NSInteger minLvl = [p[@"min_level"] integerValue];
            NSInteger maxLvl = [p[@"max_level"] integerValue];
            NSString *area = multiArea ? (p[@"area"] ?: @"") : @"";

            // Build badge text: method + level range
            NSMutableString *badge = [[NSMutableString alloc] init];
            if (method.length > 0) {
                [badge appendString:method];
            }
            if (minLvl > 0 || maxLvl > 0) {
                if (badge.length > 0) [badge appendString:@" "];
                if (minLvl == maxLvl) {
                    [badge appendFormat:@"Lv%ld", (long)minLvl];
                } else {
                    [badge appendFormat:@"Lv%ld-%ld", (long)minLvl, (long)maxLvl];
                }
            }

            NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithDictionary:@{
                @"type": @"encounter",
                @"id": p[@"id"] ?: @0,
                @"name": p[@"name"] ?: @"???",
                @"badge": badge,
                @"height": @(DETAIL_SPRITE_ROW_HEIGHT)
            }];
            if (area.length > 0) {
                row[@"area"] = area;
            }
            [rows addObject:row];
        }

        // Add overflow row if needed
        if ((NSInteger)pokemon.count > LOCATION_MAX_POKEMON_PER_VERSION) {
            NSInteger extra = pokemon.count - LOCATION_MAX_POKEMON_PER_VERSION;
            [rows addObject:@{
                @"type": @"overflow",
                @"text": [NSString stringWithFormat:@"...and %ld more", (long)extra],
                @"height": @(DETAIL_ROW_HEIGHT)
            }];
        }

        [allSections addObject:@{
            @"title": versionName,
            @"rows": rows
        }];
    }

    self.sections = allSections;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *section = self.sections[(NSUInteger)indexPath.section];
    NSArray *rows = section[@"rows"];
    NSDictionary *row = rows[(NSUInteger)indexPath.row];

    NSString *rowType = row[@"type"];

    if ([rowType isEqualToString:@"overflow"]) {
        static NSString *overflowID = @"OverflowCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:overflowID];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:overflowID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [UIFont italicSystemFontOfSize:13];
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
        }
        cell.textLabel.text = row[@"text"];
        return cell;
    }

    // encounter row
    static NSString *spriteID = @"DetailSpriteCell";
    DetailSpriteCell *cell = [tableView dequeueReusableCellWithIdentifier:spriteID];
    if (!cell) {
        cell = [[DetailSpriteCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:spriteID];
    }

    NSInteger pokemonID = [row[@"id"] integerValue];
    UIImage *sprite = [[DataManager sharedManager] spriteForPokemonID:pokemonID];
    NSString *badge = row[@"badge"] ?: @"";
    [cell configureWithSprite:sprite numberID:pokemonID name:row[@"name"]
                    badgeText:badge];

    return cell;
}

@end
