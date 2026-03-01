#import "ItemDetailVC.h"
#import "Item.h"
#import "DataManager.h"
#import "TypeBadgeView.h"
#import "PokemonType.h"
#import "TextBlockCell.h"
#import "KeyValueCell.h"
#import "DetailSpriteCell.h"
#import "DetailConstants.h"

@interface ItemDetailVC ()
@property (nonatomic, strong) Item *item;
@end

@implementation ItemDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.itemID > 0) {
        self.item = [[DataManager sharedManager] itemDetailWithID:self.itemID];
        self.title = self.item.name ?: @"Item";
        [self buildSections];
        [self setupHeaderView];
        [self.tableView reloadData];
        [self setupFavouriteButton];
    } else {
        [self showEmptyState];
    }
}

- (BOOL)hasData {
    return self.item != nil;
}

- (NSString *)favouriteEntityType { return @"items"; }
- (NSInteger)favouriteEntityID { return self.itemID; }

- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom {
    top[0] = 0.60; top[1] = 0.35; top[2] = 0.10; top[3] = 1.0;
    bottom[0] = 0.75; bottom[1] = 0.50; bottom[2] = 0.15; bottom[3] = 1.0;
}

- (NSString *)emptyStateText {
    return @"Select an Item";
}

#pragma mark - Header View

- (void)setupHeaderView {
    if (!self.item) return;
    NSLog(@"[DEBUG] ItemDetailVC setupHeaderView: tableWidth=%.0f", self.tableView.bounds.size.width);

    BOOL hasSprite = self.item.hasSprite;
    CGFloat spriteSize = 48;
    CGFloat textX = DETAIL_CELL_PADDING + (hasSprite ? spriteSize + 10 : 0);
    CGFloat headerHeight = hasSprite ? MAX(90, DETAIL_CELL_PADDING + spriteSize + DETAIL_CELL_PADDING) : 90;

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
        self.tableView.bounds.size.width, headerHeight)];

    if (hasSprite) {
        UIImageView *spriteView = [[UIImageView alloc] initWithFrame:
            CGRectMake(DETAIL_CELL_PADDING, DETAIL_CELL_PADDING, spriteSize, spriteSize)];
        spriteView.contentMode = UIViewContentModeScaleAspectFit;
        spriteView.image = [[DataManager sharedManager] spriteForItemName:self.item.apiName];
        [header addSubview:spriteView];
    }

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(textX, DETAIL_CELL_PADDING,
                   header.bounds.size.width - textX - DETAIL_CELL_PADDING, 28)];
    nameLabel.text = self.item.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:nameLabel];

    UILabel *catLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(textX, DETAIL_CELL_PADDING + 32, 200, 18)];
    catLabel.text = [self.item categoryDisplay];
    catLabel.font = [UIFont systemFontOfSize:13];
    catLabel.textColor = [UIColor grayColor];
    catLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:catLabel];

    UILabel *costLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(textX, DETAIL_CELL_PADDING + 52, 200, 18)];
    costLabel.text = [self.item costString];
    costLabel.font = [UIFont systemFontOfSize:13];
    costLabel.textColor = [UIColor colorWithWhite:0.40 alpha:1];
    costLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:costLabel];

    self.tableView.tableHeaderView = header;
}

#pragma mark - Build Sections

- (void)buildSections {
    if (!self.item) {
        self.sections = @[];
        return;
    }

    NSMutableArray *sects = [[NSMutableArray alloc] init];
    CGFloat tableWidth = self.tableView.bounds.size.width;

    // Effect text (no title)
    {
        NSString *effect = self.item.effect;
        NSString *flavor = self.item.flavorText;
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

    // Teaches move
    {
        NSDictionary *teaches = self.item.teachesMove;
        if (teaches) {
            NSString *moveName = teaches[@"move_name"] ?: @"";
            NSString *moveType = teaches[@"move_type"] ?: @"";
            if (moveName.length > 0) {
                [sects addObject:@{
                    @"title": @"Teaches",
                    @"rows": @[@{
                        @"type": @"teaches",
                        @"moveName": moveName,
                        @"moveType": moveType
                    }]
                }];
            }
        }
    }

    // Fling
    {
        if (self.item.flingPower || self.item.flingEffect) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            if (self.item.flingPower) {
                [rows addObject:@{
                    @"type": @"keyvalue",
                    @"key": @"Fling Power",
                    @"value": [NSString stringWithFormat:@"%ld",
                               (long)[self.item.flingPower integerValue]]
                }];
            }
            if (self.item.flingEffect) {
                [rows addObject:@{
                    @"type": @"keyvalue",
                    @"key": @"Fling Effect",
                    @"value": [self titleCase:
                        [self.item.flingEffect stringByReplacingOccurrencesOfString:@"-"
                                                                         withString:@" "]]
                }];
            }
            [sects addObject:@{@"title": @"Fling", @"rows": rows}];
        }
    }

    // Held By
    {
        NSArray *heldBy = self.item.heldBy;
        if (heldBy && heldBy.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            for (NSDictionary *p in heldBy) {
                [rows addObject:@{
                    @"type": @"sprite",
                    @"id": p[@"id"] ?: @0,
                    @"name": p[@"name"] ?: @"???",
                    @"height": @(DETAIL_SPRITE_ROW_HEIGHT)
                }];
            }
            [sects addObject:@{@"title": @"Held By", @"rows": rows}];
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

    if ([type isEqualToString:@"teaches"]) {
        static NSString *teachID = @"TeachesCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:teachID];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:teachID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        // Remove old subviews
        for (UIView *sub in cell.contentView.subviews) [sub removeFromSuperview];

        CGFloat x = DETAIL_CELL_PADDING;
        NSString *moveType = row[@"moveType"];
        if (moveType.length > 0) {
            TypeBadgeView *badge = [[TypeBadgeView alloc] initWithTypeName:moveType];
            badge.frame = CGRectMake(x, (44 - [TypeBadgeView badgeHeight]) / 2,
                                     [TypeBadgeView badgeWidth], [TypeBadgeView badgeHeight]);
            [cell.contentView addSubview:badge];
            x += [TypeBadgeView badgeWidth] + 8;
        }

        UILabel *nameLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(x, 0, cell.contentView.bounds.size.width - x - DETAIL_CELL_PADDING, 44)];
        nameLabel.text = row[@"moveName"];
        nameLabel.font = [UIFont boldSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
        nameLabel.textColor = [UIColor darkTextColor];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [cell.contentView addSubview:nameLabel];
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

    // sprite
    static NSString *spriteID = @"DetailSpriteCell";
    DetailSpriteCell *cell = [tableView dequeueReusableCellWithIdentifier:spriteID];
    if (!cell) {
        cell = [[DetailSpriteCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:spriteID];
    }
    NSInteger pokemonID = [row[@"id"] integerValue];
    UIImage *sprite = [[DataManager sharedManager] spriteForPokemonID:pokemonID];
    [cell configureWithSprite:sprite numberID:pokemonID name:row[@"name"]];
    return cell;
}

#pragma mark - Helpers

- (NSString *)titleCase:(NSString *)str {
    if (!str || str.length == 0) return @"\u2014";
    return [[[str substringToIndex:1] uppercaseString]
        stringByAppendingString:[str substringFromIndex:1]];
}

@end
