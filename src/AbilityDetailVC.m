#import "AbilityDetailVC.h"
#import "Ability.h"
#import "DataManager.h"
#import "TextBlockCell.h"
#import "DetailSpriteCell.h"
#import "DetailConstants.h"

@interface AbilityDetailVC ()
@property (nonatomic, strong) Ability *ability;
@end

@implementation AbilityDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.abilityID > 0) {
        self.ability = [[DataManager sharedManager] abilityDetailWithID:self.abilityID];
        self.title = self.ability.name ?: @"Ability";
        [self buildSections];
        [self setupHeaderView];
        [self.tableView reloadData];
    } else {
        [self showEmptyState];
    }
}

- (BOOL)hasData {
    return self.ability != nil;
}

- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom {
    top[0] = 0.15; top[1] = 0.40; top[2] = 0.20; top[3] = 1.0;
    bottom[0] = 0.25; bottom[1] = 0.55; bottom[2] = 0.30; bottom[3] = 1.0;
}

- (NSString *)emptyStateText {
    return @"Select an Ability";
}

#pragma mark - Header View

- (void)setupHeaderView {
    if (!self.ability) return;
    NSLog(@"[DEBUG] AbilityDetailVC setupHeaderView: tableWidth=%.0f", self.tableView.bounds.size.width);

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
        self.tableView.bounds.size.width, 70)];

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(DETAIL_CELL_PADDING, 14, header.bounds.size.width - DETAIL_CELL_PADDING * 2, 28)];
    nameLabel.text = self.ability.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:nameLabel];

    UILabel *genLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(DETAIL_CELL_PADDING, 48, 200, 20)];
    genLabel.text = [self.ability generationDisplay];
    genLabel.font = [UIFont systemFontOfSize:14];
    genLabel.textColor = [UIColor grayColor];
    genLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:genLabel];

    self.tableView.tableHeaderView = header;
}

#pragma mark - Build Sections

- (void)buildSections {
    if (!self.ability) {
        self.sections = @[];
        return;
    }

    NSMutableArray *sects = [[NSMutableArray alloc] init];

    // Section 0: Effect text (no title)
    {
        NSString *effect = self.ability.effect;
        NSString *flavor = self.ability.flavorText;
        NSMutableString *text = [[NSMutableString alloc] init];
        if (effect.length > 0) [text appendString:effect];
        if (flavor.length > 0 && ![flavor isEqualToString:effect]) {
            if (text.length > 0) [text appendString:@"\n\n"];
            [text appendString:flavor];
        }

        if (text.length > 0) {
            CGFloat h = [TextBlockCell heightForText:text
                                               width:self.tableView.bounds.size.width];
            [sects addObject:@{
                @"rows": @[@{
                    @"type": @"text",
                    @"text": [text copy],
                    @"height": @(h)
                }]
            }];
        }
    }

    // Section 1: Pokemon
    {
        NSArray *pokemon = self.ability.pokemon;
        if (pokemon && pokemon.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            for (NSDictionary *p in pokemon) {
                NSMutableDictionary *row = [@{
                    @"type": @"sprite",
                    @"id": p[@"id"] ?: @0,
                    @"name": p[@"name"] ?: @"???",
                    @"height": @(DETAIL_SPRITE_ROW_HEIGHT)
                } mutableCopy];
                if ([p[@"is_hidden"] boolValue]) {
                    row[@"badge"] = @"Hidden";
                }
                [rows addObject:row];
            }
            [sects addObject:@{@"title": @"Pok\u00e9mon", @"rows": rows}];
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

    // sprite
    static NSString *spriteID = @"DetailSpriteCell";
    DetailSpriteCell *cell = [tableView dequeueReusableCellWithIdentifier:spriteID];
    if (!cell) {
        cell = [[DetailSpriteCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:spriteID];
    }

    NSInteger pokemonID = [row[@"id"] integerValue];
    UIImage *sprite = [[DataManager sharedManager] spriteForPokemonID:pokemonID];
    NSString *badge = row[@"badge"];
    if (badge) {
        [cell configureWithSprite:sprite numberID:pokemonID name:row[@"name"]
                        badgeText:badge];
    } else {
        [cell configureWithSprite:sprite numberID:pokemonID name:row[@"name"]];
    }
    return cell;
}

@end
