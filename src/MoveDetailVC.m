#import "MoveDetailVC.h"
#import "Move.h"
#import "DataManager.h"
#import "PokemonType.h"
#import "TypeBadgeView.h"
#import "TextBlockCell.h"
#import "KeyValueCell.h"
#import "DetailSpriteCell.h"
#import "DetailConstants.h"

@interface MoveDetailVC ()
@property (nonatomic, strong) Move *move;
@end

@implementation MoveDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.moveID > 0) {
        CFAbsoluteTime loadStart = CFAbsoluteTimeGetCurrent();
        self.move = [[DataManager sharedManager] moveDetailWithID:self.moveID];
        NSLog(@"[PERF] MoveDetailVC loadData: %.1fms (id=%ld, name=%@)",
              (CFAbsoluteTimeGetCurrent() - loadStart) * 1000,
              (long)self.moveID, self.move.name ?: @"nil");
        self.title = self.move.name ?: @"Move";
        [self buildSections];
        [self setupHeaderView];
        [self.tableView reloadData];
    } else {
        [self showEmptyState];
    }
}

- (BOOL)hasData {
    return self.move != nil;
}

- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom {
    top[0] = 0.15; top[1] = 0.25; top[2] = 0.50; top[3] = 1.0;
    bottom[0] = 0.25; bottom[1] = 0.40; bottom[2] = 0.65; bottom[3] = 1.0;
}

- (NSString *)emptyStateText {
    return @"Select a Move";
}

#pragma mark - Header View

- (void)setupHeaderView {
    if (!self.move) return;
    NSLog(@"[DEBUG] MoveDetailVC setupHeaderView: tableWidth=%.0f", self.tableView.bounds.size.width);

    CGFloat headerHeight = 90;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
        self.tableView.bounds.size.width, headerHeight)];

    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat innerW = header.bounds.size.width - pad * 2;

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(pad, pad, innerW, 28)];
    nameLabel.text = self.move.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:nameLabel];

    TypeBadgeView *badge = [[TypeBadgeView alloc] initWithTypeName:self.move.type];
    badge.frame = CGRectMake(pad, pad + 36,
                             [TypeBadgeView badgeWidth], [TypeBadgeView badgeHeight]);
    [header addSubview:badge];

    UILabel *classLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(pad + [TypeBadgeView badgeWidth] + 10, pad + 36,
                   120, [TypeBadgeView badgeHeight])];
    classLabel.text = [self.move damageClassDisplay];
    classLabel.font = [UIFont systemFontOfSize:14];
    classLabel.textColor = [UIColor grayColor];
    classLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:classLabel];

    NSString *gen = [self formatGeneration:self.move.generation];
    UILabel *genLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(header.bounds.size.width - pad - 80, pad + 36, 80, 20)];
    genLabel.text = gen;
    genLabel.font = [UIFont systemFontOfSize:12];
    genLabel.textColor = [UIColor grayColor];
    genLabel.textAlignment = NSTextAlignmentRight;
    genLabel.backgroundColor = [UIColor clearColor];
    genLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [header addSubview:genLabel];

    self.tableView.tableHeaderView = header;
}

#pragma mark - Build Sections

- (void)buildSections {
    if (!self.move) {
        self.sections = @[];
        return;
    }

    NSMutableArray *sects = [[NSMutableArray alloc] init];
    CGFloat tableWidth = self.tableView.bounds.size.width;

    // Effect text
    {
        NSString *effect = self.move.effect;
        NSString *flavor = self.move.flavorText;
        NSString *text = (effect.length > 0) ? effect : flavor;
        if (text.length > 0) {
            CGFloat h = [TextBlockCell heightForText:text width:tableWidth];
            [sects addObject:@{
                @"rows": @[@{@"type": @"text", @"text": text, @"height": @(h)}]
            }];
        }
    }

    // Stats
    {
        NSArray *rows = @[
            @{@"type": @"keyvalue", @"key": @"Power", @"value": [self.move powerString]},
            @{@"type": @"keyvalue", @"key": @"Accuracy", @"value": [self.move accuracyString]},
            @{@"type": @"keyvalue", @"key": @"PP", @"value": [self.move ppString]},
            @{@"type": @"keyvalue", @"key": @"Priority",
              @"value": [NSString stringWithFormat:@"%ld", (long)self.move.priority]},
            @{@"type": @"keyvalue", @"key": @"Target",
              @"value": [self titleCase:[self.move.target
                  stringByReplacingOccurrencesOfString:@"-" withString:@" "]]},
        ];
        [sects addObject:@{@"title": @"Stats", @"rows": rows}];
    }

    // Battle Effects (meta + stat changes)
    {
        NSMutableArray *rows = [[NSMutableArray alloc] init];
        NSDictionary *meta = self.move.meta;
        NSArray *statChanges = self.move.statChanges;

        if (meta[@"ailment"]) {
            NSString *ailment = meta[@"ailment"];
            NSInteger chance = [meta[@"ailment_chance"] integerValue];
            NSString *val = (chance > 0 && chance < 100) ?
                [NSString stringWithFormat:@"%@ (%ld%%)", ailment, (long)chance] : ailment;
            [rows addObject:@{@"type": @"keyvalue", @"key": @"Ailment", @"value": val}];
        }
        if (meta[@"drain"]) {
            [rows addObject:@{@"type": @"keyvalue", @"key": @"Drain",
                @"value": [NSString stringWithFormat:@"%ld%%", (long)[meta[@"drain"] integerValue]]}];
        }
        if (meta[@"healing"]) {
            [rows addObject:@{@"type": @"keyvalue", @"key": @"Healing",
                @"value": [NSString stringWithFormat:@"%ld%%", (long)[meta[@"healing"] integerValue]]}];
        }
        if (meta[@"crit_rate"]) {
            [rows addObject:@{@"type": @"keyvalue", @"key": @"Crit Rate",
                @"value": [NSString stringWithFormat:@"+%ld", (long)[meta[@"crit_rate"] integerValue]]}];
        }
        if (meta[@"flinch_chance"]) {
            [rows addObject:@{@"type": @"keyvalue", @"key": @"Flinch",
                @"value": [NSString stringWithFormat:@"%ld%%", (long)[meta[@"flinch_chance"] integerValue]]}];
        }
        if (meta[@"min_hits"] && meta[@"max_hits"]) {
            [rows addObject:@{@"type": @"keyvalue", @"key": @"Hits",
                @"value": [NSString stringWithFormat:@"%ld\u2013%ld",
                    (long)[meta[@"min_hits"] integerValue],
                    (long)[meta[@"max_hits"] integerValue]]}];
        }

        for (NSDictionary *sc in statChanges) {
            NSString *stat = sc[@"stat"] ?: @"";
            NSInteger change = [sc[@"change"] integerValue];
            NSString *changeStr = change > 0 ?
                [NSString stringWithFormat:@"+%ld", (long)change] :
                [NSString stringWithFormat:@"%ld", (long)change];
            [rows addObject:@{@"type": @"keyvalue",
                @"key": [self titleCase:[stat stringByReplacingOccurrencesOfString:@"-" withString:@" "]],
                @"value": changeStr}];
        }

        if (rows.count > 0) {
            [sects addObject:@{@"title": @"Battle Effects", @"rows": rows}];
        }
    }

    // Learned By
    {
        NSArray *learnedBy = self.move.learnedBy;
        if (learnedBy && learnedBy.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            DataManager *dm = [DataManager sharedManager];
            for (NSNumber *pid in learnedBy) {
                NSInteger pokemonID = [pid integerValue];
                NSString *name = [dm pokemonNameForID:pokemonID];
                [rows addObject:@{
                    @"type": @"sprite",
                    @"id": @(pokemonID),
                    @"name": name ?: @"???",
                    @"height": @(DETAIL_SPRITE_ROW_HEIGHT)
                }];
            }
            [sects addObject:@{@"title": @"Learned By", @"rows": rows}];
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

- (NSString *)formatGeneration:(NSString *)gen {
    if (!gen || gen.length == 0) return @"";
    NSString *numeral = [[gen componentsSeparatedByString:@"-"] lastObject];
    return [NSString stringWithFormat:@"Gen %@", [numeral uppercaseString]];
}

@end
