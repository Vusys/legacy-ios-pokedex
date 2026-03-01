#import "EggGroupDetailVC.h"
#import "EggGroup.h"
#import "DataManager.h"
#import "DetailSpriteCell.h"
#import "DetailConstants.h"

@interface EggGroupDetailVC ()
@property (nonatomic, strong) EggGroup *eggGroup;
@end

@implementation EggGroupDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.eggGroupID > 0) {
        self.eggGroup = [[DataManager sharedManager] eggGroupDetailWithID:self.eggGroupID];
        self.title = self.eggGroup.name ?: @"Egg Group";
        [self buildSections];
        [self setupHeaderView];
        [self.tableView reloadData];
        [self setupFavouriteButton];
    } else {
        [self showEmptyState];
    }
}

- (BOOL)hasData {
    return self.eggGroup != nil;
}

- (NSString *)favouriteEntityType { return @"egg_groups"; }
- (NSInteger)favouriteEntityID { return self.eggGroupID; }

- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom {
    top[0] = 0.15; top[1] = 0.45; top[2] = 0.50; top[3] = 1.0;
    bottom[0] = 0.25; bottom[1] = 0.60; bottom[2] = 0.65; bottom[3] = 1.0;
}

- (NSString *)emptyStateText {
    return @"Select an Egg Group";
}

#pragma mark - Header View

- (void)setupHeaderView {
    if (!self.eggGroup) return;
    NSLog(@"[DEBUG] EggGroupDetailVC setupHeaderView: tableWidth=%.0f", self.tableView.bounds.size.width);

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
        self.tableView.bounds.size.width, 70)];

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(DETAIL_CELL_PADDING, 14, header.bounds.size.width - DETAIL_CELL_PADDING * 2, 28)];
    nameLabel.text = self.eggGroup.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:nameLabel];

    UILabel *countLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(DETAIL_CELL_PADDING, 48, 200, 20)];
    countLabel.text = [NSString stringWithFormat:@"%ld Pok\u00e9mon",
                       (long)self.eggGroup.pokemon.count];
    countLabel.font = [UIFont systemFontOfSize:14];
    countLabel.textColor = [UIColor grayColor];
    countLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:countLabel];

    self.tableView.tableHeaderView = header;
}

#pragma mark - Build Sections

- (void)buildSections {
    if (!self.eggGroup) {
        self.sections = @[];
        return;
    }

    NSArray *pokemon = self.eggGroup.pokemon;
    if (!pokemon || pokemon.count == 0) {
        self.sections = @[];
        return;
    }

    NSMutableArray *rows = [[NSMutableArray alloc] init];
    for (NSDictionary *p in pokemon) {
        [rows addObject:@{
            @"type": @"sprite",
            @"id": p[@"id"] ?: @0,
            @"name": p[@"name"] ?: @"???",
            @"height": @(DETAIL_SPRITE_ROW_HEIGHT)
        }];
    }

    self.sections = @[@{
        @"title": @"Pok\u00e9mon",
        @"rows": rows
    }];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *section = self.sections[(NSUInteger)indexPath.section];
    NSArray *rows = section[@"rows"];
    NSDictionary *row = rows[(NSUInteger)indexPath.row];

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

@end
