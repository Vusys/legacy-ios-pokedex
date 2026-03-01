#import "FavouritesVC.h"
#import "DataManager.h"
#import "PokemonDetailVC.h"
#import "MoveDetailVC.h"
#import "AbilityDetailVC.h"
#import "ItemDetailVC.h"
#import "NatureDetailVC.h"
#import "EggGroupDetailVC.h"
#import "BerryDetailVC.h"
#import "TexturedBackgroundView.h"

// Each section maps to one entity type
static NSString *const kEntityTypes[] = {
    @"pokemon", @"moves", @"abilities", @"items",
    @"natures", @"egg_groups", @"berries"
};
static NSString *const kSectionTitles[] = {
    @"Pok\u00e9mon", @"Moves", @"Abilities", @"Items",
    @"Natures", @"Egg Groups", @"Berries"
};
static const NSUInteger kEntityCount = 7;

@interface FavouritesVC ()
@property (nonatomic, strong) NSArray *sectionTypes;   // entity type strings with favourites
@property (nonatomic, strong) NSArray *sectionTitles;   // display titles
@property (nonatomic, strong) NSArray *sectionRows;     // arrays of summary dicts
@end

@implementation FavouritesVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Favourites";

    self.tableView.backgroundView = [[TexturedBackgroundView alloc]
        initWithFrame:self.tableView.bounds];

    [self reloadFavourites];

    [[NSNotificationCenter defaultCenter]
        addObserver:self selector:@selector(favouritesDidChange:)
               name:FavouritesChangedNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)favouritesDidChange:(NSNotification *)note {
    [self reloadFavourites];
    [self.tableView reloadData];
}

- (void)reloadFavourites {
    DataManager *dm = [DataManager sharedManager];
    NSMutableArray *types = [[NSMutableArray alloc] init];
    NSMutableArray *titles = [[NSMutableArray alloc] init];
    NSMutableArray *rows = [[NSMutableArray alloc] init];

    for (NSUInteger i = 0; i < kEntityCount; i++) {
        NSString *type = kEntityTypes[i];
        NSSet *favIDs = [dm favouriteIDsForType:type];
        if (favIDs.count == 0) continue;

        NSArray *allSummaries = [self summariesForType:type];
        NSArray *filtered = [dm filterSummaries:allSummaries byFavouritesOfType:type];
        if (filtered.count == 0) continue;

        [types addObject:type];
        [titles addObject:kSectionTitles[i]];
        [rows addObject:filtered];
    }

    self.sectionTypes = types;
    self.sectionTitles = titles;
    self.sectionRows = rows;
}

- (NSArray *)summariesForType:(NSString *)type {
    DataManager *dm = [DataManager sharedManager];
    if ([type isEqualToString:@"pokemon"])    return [dm allPokemonSummaries];
    if ([type isEqualToString:@"moves"])      return [dm allMoveSummaries];
    if ([type isEqualToString:@"abilities"])  return [dm allAbilitySummaries];
    if ([type isEqualToString:@"items"])      return [dm allItemSummaries];
    if ([type isEqualToString:@"natures"])    return [dm allNatureSummaries];
    if ([type isEqualToString:@"egg_groups"]) return [dm allEggGroupSummaries];
    if ([type isEqualToString:@"berries"])    return [dm allBerrySummaries];
    return @[];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.sectionTypes.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionTitles[(NSUInteger)section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *rows = self.sectionRows[(NSUInteger)section];
    return (NSInteger)rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"FavCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellID];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    NSArray *rows = self.sectionRows[(NSUInteger)indexPath.section];
    NSDictionary *summary = rows[(NSUInteger)indexPath.row];

    cell.textLabel.text = summary[@"name"] ?: @"???";

    NSString *type = self.sectionTypes[(NSUInteger)indexPath.section];
    NSInteger eid = [summary[@"id"] integerValue];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"#%ld", (long)eid];
    cell.detailTextLabel.textColor = [UIColor grayColor];

    // Show sprite for pokemon
    if ([type isEqualToString:@"pokemon"]) {
        cell.imageView.image = [[DataManager sharedManager] spriteForPokemonID:eid];
    } else if ([type isEqualToString:@"berries"]) {
        cell.imageView.image = [[DataManager sharedManager] spriteForBerryID:eid];
    } else if ([type isEqualToString:@"items"]) {
        NSString *apiName = summary[@"api_name"];
        cell.imageView.image = [[DataManager sharedManager] spriteForItemName:apiName];
    } else {
        cell.imageView.image = nil;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *type = self.sectionTypes[(NSUInteger)indexPath.section];
    NSArray *rows = self.sectionRows[(NSUInteger)indexPath.section];
    NSDictionary *summary = rows[(NSUInteger)indexPath.row];
    NSInteger eid = [summary[@"id"] integerValue];

    UIViewController *detailVC = [self detailVCForType:type entityID:eid];
    if (detailVC) {
        [self.navigationController pushViewController:detailVC animated:YES];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIViewController *)detailVCForType:(NSString *)type entityID:(NSInteger)eid {
    if ([type isEqualToString:@"pokemon"]) {
        PokemonDetailVC *vc = [[PokemonDetailVC alloc] init];
        vc.pokemonID = eid;
        return vc;
    }
    if ([type isEqualToString:@"moves"]) {
        MoveDetailVC *vc = [[MoveDetailVC alloc] init];
        vc.moveID = eid;
        return vc;
    }
    if ([type isEqualToString:@"abilities"]) {
        AbilityDetailVC *vc = [[AbilityDetailVC alloc] init];
        vc.abilityID = eid;
        return vc;
    }
    if ([type isEqualToString:@"items"]) {
        ItemDetailVC *vc = [[ItemDetailVC alloc] init];
        vc.itemID = eid;
        return vc;
    }
    if ([type isEqualToString:@"natures"]) {
        NatureDetailVC *vc = [[NatureDetailVC alloc] init];
        vc.natureID = eid;
        return vc;
    }
    if ([type isEqualToString:@"egg_groups"]) {
        EggGroupDetailVC *vc = [[EggGroupDetailVC alloc] init];
        vc.eggGroupID = eid;
        return vc;
    }
    if ([type isEqualToString:@"berries"]) {
        BerryDetailVC *vc = [[BerryDetailVC alloc] init];
        vc.berryID = eid;
        return vc;
    }
    return nil;
}

@end
