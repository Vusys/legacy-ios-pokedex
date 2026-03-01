#import "PokemonDetailVC.h"
#import "Pokemon.h"
#import "PokemonType.h"
#import "DataManager.h"
#import "TypeBadgeView.h"
#import "StatBarView.h"
#import "TextBlockCell.h"
#import "KeyValueCell.h"
#import "DetailSpriteCell.h"
#import "StatBarCell.h"
#import "TypeGridCell.h"
#import "DetailMoveCell.h"
#import "EvolutionCell.h"
#import "DetailConstants.h"
#import <QuartzCore/QuartzCore.h>

@interface PokemonDetailVC ()
@property (nonatomic, strong) Pokemon *pokemon;
@property (nonatomic, assign) BOOL showShiny;
@property (nonatomic, assign) BOOL showFemale;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *artworkView;
@property (nonatomic, strong) UIImageView *frontSpriteView;
@property (nonatomic, strong) UIImageView *backSpriteView;
@property (nonatomic, strong) UIButton *shinyButton;
@property (nonatomic, strong) UIButton *genderButton;
@end

@implementation PokemonDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.pokemonID > 0) {
        CFAbsoluteTime loadStart = CFAbsoluteTimeGetCurrent();
        self.pokemon = [[DataManager sharedManager] pokemonDetailWithID:self.pokemonID];
        NSLog(@"[PERF] PokemonDetailVC loadData: %.1fms (id=%ld, name=%@)",
              (CFAbsoluteTimeGetCurrent() - loadStart) * 1000,
              (long)self.pokemonID, self.pokemon.name ?: @"nil");
        self.title = self.pokemon.name ?: @"Pok\u00e9dex";
        NSLog(@"[DEBUG] PokemonDetailVC viewDidLoad: about to build, tableView.width=%.0f view.width=%.0f",
              self.tableView.bounds.size.width, self.view.bounds.size.width);
        [self buildSections];
        [self setupHeaderView];
        [self.tableView reloadData];
        [self setupFavouriteButton];
    } else {
        [self showEmptyState];
    }
}

- (BOOL)hasData {
    return self.pokemon != nil;
}

- (NSString *)favouriteEntityType { return @"pokemon"; }
- (NSInteger)favouriteEntityID { return self.pokemonID; }

- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom {
    top[0] = 0.55; top[1] = 0.0; top[2] = 0.0; top[3] = 1.0;
    bottom[0] = 0.80; bottom[1] = 0.0; bottom[2] = 0.0; bottom[3] = 1.0;
}

- (NSString *)emptyStateText {
    return @"Select a Pok\u00e9mon";
}

#pragma mark - Header View

- (void)setupHeaderView {
    if (!self.pokemon) return;

    DataManager *dm = [DataManager sharedManager];
    NSInteger pid = self.pokemon.pokemonID;
    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat width = self.tableView.bounds.size.width;
    CGFloat innerWidth = width - pad * 2;

    NSLog(@"[DEBUG] PokemonDetailVC setupHeaderView: tableWidth=%.0f innerWidth=%.0f (pokemon=%@)",
          width, innerWidth, self.pokemon.name);

    // Artwork
    UIImage *artworkImage = [dm artworkForPokemonID:pid];
    BOOL hasArtwork = (artworkImage != nil);
    CGFloat artworkDisplaySize = hasArtwork ? MIN(floorf(innerWidth * 0.65), 280) : 96;

    // Front/back sprites
    UIImage *frontImage = [self currentFrontSprite];
    UIImage *backImage = [dm backSpriteForPokemonID:pid];
    if (!hasArtwork) artworkImage = frontImage;

    // Layout height calculation
    CGFloat infoHeight = 96;
    BOOL hasClassification = self.pokemon.isLegendary || self.pokemon.isMythical || self.pokemon.isBaby;
    CGFloat classificationHeight = hasClassification ? 22 : 0;
    CGFloat artworkRowHeight = artworkDisplaySize + 8;
    CGFloat spriteStripH = 88;
    CGFloat headerHeight = pad + infoHeight + classificationHeight + artworkRowHeight + spriteStripH + pad;

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, headerHeight)];
    CGFloat cy = pad;

    // Number
    UILabel *numberLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(pad, cy, innerWidth, 18)];
    numberLabel.text = [self.pokemon formattedID];
    numberLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
    if (!numberLabel.font) numberLabel.font = [UIFont boldSystemFontOfSize:14];
    numberLabel.textColor = [UIColor grayColor];
    numberLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:numberLabel];
    cy += 18;

    // Name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(pad, cy, innerWidth, 28)];
    nameLabel.text = self.pokemon.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:nameLabel];
    cy += 28;

    // Genus
    UILabel *genusLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(pad, cy, innerWidth, 18)];
    genusLabel.text = self.pokemon.genus;
    genusLabel.font = [UIFont italicSystemFontOfSize:13];
    genusLabel.textColor = [UIColor grayColor];
    genusLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:genusLabel];
    cy += 22;

    // Type badges
    CGFloat badgeX = pad;
    for (NSString *type in self.pokemon.types) {
        TypeBadgeView *badge = [[TypeBadgeView alloc] initWithTypeName:type];
        badge.frame = CGRectMake(badgeX, cy,
                                 [TypeBadgeView badgeWidth], [TypeBadgeView badgeHeight]);
        [header addSubview:badge];
        badgeX += [TypeBadgeView badgeWidth] + 6;
    }
    cy += [TypeBadgeView badgeHeight] + 8;

    // Classification badges
    if (hasClassification) {
        CGFloat classBadgeX = pad;
        CGFloat classBadgeH = 18;
        UIFont *classBadgeFont = [UIFont boldSystemFontOfSize:9];

        NSMutableArray *badgeInfo = [[NSMutableArray alloc] init];
        if (self.pokemon.isLegendary)
            [badgeInfo addObject:@[@"LEGENDARY",
                [UIColor colorWithRed:0.83 green:0.63 blue:0.09 alpha:1]]];
        if (self.pokemon.isMythical)
            [badgeInfo addObject:@[@"MYTHICAL",
                [UIColor colorWithRed:0.55 green:0.36 blue:0.96 alpha:1]]];
        if (self.pokemon.isBaby)
            [badgeInfo addObject:@[@"BABY",
                [UIColor colorWithRed:0.96 green:0.45 blue:0.71 alpha:1]]];

        for (NSArray *info in badgeInfo) {
            NSString *text = info[0];
            UIColor *color = info[1];
            CGSize textSize = [text sizeWithFont:classBadgeFont];
            CGFloat badgeW = textSize.width + 12;

            UIView *classBadge = [[UIView alloc] initWithFrame:
                CGRectMake(classBadgeX, cy, badgeW, classBadgeH)];
            classBadge.backgroundColor = color;
            classBadge.layer.cornerRadius = 3;

            UILabel *badgeLabel = [[UILabel alloc] initWithFrame:classBadge.bounds];
            badgeLabel.text = text;
            badgeLabel.font = classBadgeFont;
            badgeLabel.textColor = [UIColor whiteColor];
            badgeLabel.textAlignment = NSTextAlignmentCenter;
            badgeLabel.backgroundColor = [UIColor clearColor];
            [classBadge addSubview:badgeLabel];
            [header addSubview:classBadge];
            classBadgeX += badgeW + 4;
        }
        cy += classBadgeH + 4;
    }

    // Artwork (centered)
    CGFloat artworkX = (width - artworkDisplaySize) / 2.0;
    self.artworkView = [[UIImageView alloc] initWithFrame:
        CGRectMake(artworkX, cy, artworkDisplaySize, artworkDisplaySize)];
    self.artworkView.contentMode = UIViewContentModeScaleAspectFit;
    self.artworkView.image = artworkImage;
    self.artworkView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    self.artworkView.layer.cornerRadius = 8;
    self.artworkView.layer.borderWidth = 0.5;
    self.artworkView.layer.borderColor = [[UIColor colorWithWhite:0.88 alpha:1] CGColor];
    [header addSubview:self.artworkView];
    cy += artworkDisplaySize + 8;

    // Sprite strip
    CGFloat stripY = cy;
    CGFloat smallSprite = 80;
    CGFloat stripX = pad;
    CGFloat spriteOffY = stripY + (spriteStripH - smallSprite) / 2.0;

    self.frontSpriteView = [[UIImageView alloc] initWithFrame:
        CGRectMake(stripX, spriteOffY, smallSprite, smallSprite)];
    self.frontSpriteView.contentMode = UIViewContentModeScaleAspectFit;
    self.frontSpriteView.image = frontImage;
    self.frontSpriteView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.frontSpriteView.layer.cornerRadius = 4;
    self.frontSpriteView.layer.borderWidth = 0.5;
    self.frontSpriteView.layer.borderColor = [[UIColor colorWithWhite:0.85 alpha:1] CGColor];
    [header addSubview:self.frontSpriteView];
    stripX += smallSprite + 6;

    if (backImage) {
        self.backSpriteView = [[UIImageView alloc] initWithFrame:
            CGRectMake(stripX, spriteOffY, smallSprite, smallSprite)];
        self.backSpriteView.contentMode = UIViewContentModeScaleAspectFit;
        self.backSpriteView.image = backImage;
        self.backSpriteView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        self.backSpriteView.layer.cornerRadius = 4;
        self.backSpriteView.layer.borderWidth = 0.5;
        self.backSpriteView.layer.borderColor = [[UIColor colorWithWhite:0.85 alpha:1] CGColor];
        [header addSubview:self.backSpriteView];
        stripX += smallSprite + 6;
    }

    // Toggle buttons
    CGFloat btnH = 28;
    CGFloat btnY = stripY + (spriteStripH - btnH) / 2.0;
    CGFloat btnRight = width - pad;

    if (self.pokemon.hasFemaleSprite) {
        NSString *genderTitle = self.showFemale ? @"\u2640" : @"\u2642";
        self.genderButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.genderButton.frame = CGRectMake(btnRight - 36, btnY, 36, btnH);
        [self.genderButton setTitle:genderTitle forState:UIControlStateNormal];
        [self.genderButton setTitleColor:(self.showFemale ?
            [UIColor colorWithRed:0.95 green:0.3 blue:0.5 alpha:1] :
            [UIColor colorWithRed:0.2 green:0.4 blue:0.9 alpha:1])
            forState:UIControlStateNormal];
        self.genderButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        self.genderButton.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
        self.genderButton.layer.cornerRadius = 4;
        self.genderButton.layer.borderWidth = 0.5;
        self.genderButton.layer.borderColor = [[UIColor colorWithWhite:0.80 alpha:1] CGColor];
        [self.genderButton addTarget:self action:@selector(toggleGender)
            forControlEvents:UIControlEventTouchUpInside];
        [header addSubview:self.genderButton];
        btnRight -= 42;
    }

    self.shinyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.shinyButton.frame = CGRectMake(btnRight - 56, btnY, 56, btnH);
    [self.shinyButton setTitle:@"\u2605 Shiny" forState:UIControlStateNormal];
    [self.shinyButton setTitleColor:(self.showShiny ?
        [UIColor colorWithRed:0.85 green:0.65 blue:0.0 alpha:1] :
        [UIColor colorWithWhite:0.45 alpha:1])
        forState:UIControlStateNormal];
    self.shinyButton.titleLabel.font = [UIFont boldSystemFontOfSize:11];
    self.shinyButton.backgroundColor = self.showShiny ?
        [UIColor colorWithRed:1.0 green:0.97 blue:0.85 alpha:1] :
        [UIColor colorWithWhite:0.94 alpha:1];
    self.shinyButton.layer.cornerRadius = 4;
    self.shinyButton.layer.borderWidth = 0.5;
    self.shinyButton.layer.borderColor = (self.showShiny ?
        [[UIColor colorWithRed:0.85 green:0.65 blue:0.0 alpha:0.5] CGColor] :
        [[UIColor colorWithWhite:0.80 alpha:1] CGColor]);
    [self.shinyButton addTarget:self action:@selector(toggleShiny)
        forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:self.shinyButton];

    NSLog(@"[DEBUG] PokemonDetailVC header: size=%@ artworkSize=%.0f artworkX=%.0f "
          @"spriteStripY=%.0f btnY=%.0f shinyBtnX=%.0f",
          NSStringFromCGSize(header.frame.size), artworkDisplaySize, artworkX,
          stripY, btnY, self.shinyButton.frame.origin.x);

    self.headerView = header;
    self.tableView.tableHeaderView = header;
}

- (UIImage *)currentFrontSprite {
    DataManager *dm = [DataManager sharedManager];
    NSInteger pid = self.pokemon.pokemonID;
    if (self.showFemale && self.pokemon.hasFemaleSprite) {
        return [dm femaleSpriteForPokemonID:pid];
    } else if (self.showShiny) {
        return [dm shinySpriteForPokemonID:pid];
    }
    return [dm spriteForPokemonID:pid];
}

- (void)updateSpriteImages {
    DataManager *dm = [DataManager sharedManager];
    NSInteger pid = self.pokemon.pokemonID;
    UIImage *frontImage = [self currentFrontSprite];
    self.frontSpriteView.image = frontImage;

    UIImage *artworkImage = [dm artworkForPokemonID:pid];
    if (!artworkImage) artworkImage = frontImage;
    self.artworkView.image = artworkImage;

    // Update shiny button appearance
    [self.shinyButton setTitleColor:(self.showShiny ?
        [UIColor colorWithRed:0.85 green:0.65 blue:0.0 alpha:1] :
        [UIColor colorWithWhite:0.45 alpha:1])
        forState:UIControlStateNormal];
    self.shinyButton.backgroundColor = self.showShiny ?
        [UIColor colorWithRed:1.0 green:0.97 blue:0.85 alpha:1] :
        [UIColor colorWithWhite:0.94 alpha:1];
    self.shinyButton.layer.borderColor = (self.showShiny ?
        [[UIColor colorWithRed:0.85 green:0.65 blue:0.0 alpha:0.5] CGColor] :
        [[UIColor colorWithWhite:0.80 alpha:1] CGColor]);

    // Update gender button appearance
    if (self.genderButton) {
        NSString *genderTitle = self.showFemale ? @"\u2640" : @"\u2642";
        [self.genderButton setTitle:genderTitle forState:UIControlStateNormal];
        [self.genderButton setTitleColor:(self.showFemale ?
            [UIColor colorWithRed:0.95 green:0.3 blue:0.5 alpha:1] :
            [UIColor colorWithRed:0.2 green:0.4 blue:0.9 alpha:1])
            forState:UIControlStateNormal];
    }
}

- (void)toggleShiny {
    self.showShiny = !self.showShiny;
    self.showFemale = NO;
    [self updateSpriteImages];
}

- (void)toggleGender {
    self.showFemale = !self.showFemale;
    self.showShiny = NO;
    [self updateSpriteImages];
}

#pragma mark - Build Sections

- (void)buildSections {
    if (!self.pokemon) {
        self.sections = @[];
        return;
    }

    NSMutableArray *sects = [[NSMutableArray alloc] init];
    CGFloat tableWidth = self.tableView.bounds.size.width;

    CFAbsoluteTime totalStart = CFAbsoluteTimeGetCurrent();

    // Flavor text entries
    {
        NSArray *entries = self.pokemon.flavorTextEntries;
        NSString *fallbackText = self.pokemon.flavorText;
        if (!entries || entries.count == 0) {
            if (fallbackText.length > 0) {
                entries = @[@{@"text": fallbackText, @"versions": @[]}];
            }
        }
        if (entries.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            NSDictionary *versionNames = [self versionDisplayNames];
            UIFont *italicFont = [UIFont italicSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
            UIFont *boldFont = [UIFont boldSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
            for (NSUInteger i = 0; i < entries.count; i++) {
                NSDictionary *entry = entries[i];
                NSString *text = entry[@"text"] ?: @"";
                NSString *versionStr = @"";

                if (i > 0) {
                    NSArray *versions = entry[@"versions"] ?: @[];
                    NSMutableArray *displayVersions = [[NSMutableArray alloc] init];
                    for (NSString *v in versions) {
                        [displayVersions addObject:(versionNames[v] ?: v)];
                    }
                    versionStr = [displayVersions componentsJoinedByString:@" / "];
                }

                CGFloat h = [TextBlockCell heightForText:text width:tableWidth font:italicFont];
                if (versionStr.length > 0) {
                    CGFloat vh = [TextBlockCell heightForText:versionStr width:tableWidth font:boldFont];
                    h = h + vh - 8; // subtract one padding since they share the cell
                }
                [rows addObject:@{
                    @"type": @"flavortext",
                    @"text": text,
                    @"versionStr": versionStr,
                    @"height": @(h)
                }];
            }
            [sects addObject:@{@"rows": rows}];
        }
    }

    // Base Stats
    {
        NSDictionary *stats = self.pokemon.stats;
        if (stats && stats.count > 0) {
            NSArray *statOrder = @[@"hp", @"attack", @"defense",
                                   @"special-attack", @"special-defense", @"speed"];
            NSDictionary *statNames = @{
                @"hp": @"HP", @"attack": @"Atk", @"defense": @"Def",
                @"special-attack": @"Sp.Atk", @"special-defense": @"Sp.Def",
                @"speed": @"Speed"
            };

            NSMutableArray *rows = [[NSMutableArray alloc] init];
            NSInteger total = 0;
            for (NSString *key in statOrder) {
                NSInteger value = [stats[key] integerValue];
                total += value;
                [rows addObject:@{
                    @"type": @"statbar",
                    @"name": statNames[key],
                    @"value": @(value),
                    @"height": @(DETAIL_STAT_HEIGHT)
                }];
            }
            [rows addObject:@{
                @"type": @"keyvalue",
                @"key": @"Total",
                @"value": [NSString stringWithFormat:@"%ld", (long)total],
                @"height": @(28)
            }];
            [sects addObject:@{@"title": @"Base Stats", @"rows": rows}];
        }
    }

    // Type Effectiveness
    [self buildTypeEffectivenessSection:sects width:tableWidth];

    // Info
    {
        NSArray *rows = @[
            @{@"type": @"keyvalue", @"key": @"Height", @"value": [self.pokemon formattedHeight]},
            @{@"type": @"keyvalue", @"key": @"Weight", @"value": [self.pokemon formattedWeight]},
            @{@"type": @"keyvalue", @"key": @"Color", @"value": [self titleCase:self.pokemon.color]},
            @{@"type": @"keyvalue", @"key": @"Shape", @"value": [self formatShape:self.pokemon.shape]},
            @{@"type": @"keyvalue", @"key": @"Habitat", @"value": [self titleCase:self.pokemon.habitat]},
            @{@"type": @"keyvalue", @"key": @"Catch Rate",
              @"value": [NSString stringWithFormat:@"%ld", (long)self.pokemon.captureRate]},
            @{@"type": @"keyvalue", @"key": @"Base Exp",
              @"value": [NSString stringWithFormat:@"%ld", (long)self.pokemon.baseExperience]},
            @{@"type": @"keyvalue", @"key": @"Generation",
              @"value": [self formatGeneration:self.pokemon.generation]},
        ];
        [sects addObject:@{@"title": @"Info", @"rows": rows}];
    }

    // Pokedex Numbers
    {
        NSArray *numbers = self.pokemon.pokedexNumbers;
        if (numbers && numbers.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            for (NSDictionary *entry in numbers) {
                NSInteger num = [entry[@"number"] integerValue];
                [rows addObject:@{
                    @"type": @"keyvalue",
                    @"key": entry[@"name"] ?: @"",
                    @"value": [NSString stringWithFormat:@"#%03ld", (long)num],
                    @"valueFont": @"mono"
                }];
            }
            [sects addObject:@{@"title": @"Pok\u00e9dex Numbers", @"rows": rows}];
        }
    }

    // Localized Names
    {
        NSArray *names = self.pokemon.localizedNames;
        if (names && names.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            for (NSDictionary *entry in names) {
                [rows addObject:@{
                    @"type": @"keyvalue",
                    @"key": entry[@"language"] ?: @"",
                    @"value": entry[@"name"] ?: @""
                }];
            }
            [sects addObject:@{@"title": @"Names", @"rows": rows}];
        }
    }

    // Wild Held Items
    {
        NSArray *items = self.pokemon.heldItems;
        if (items && items.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            for (NSDictionary *item in items) {
                [rows addObject:@{
                    @"type": @"helditem",
                    @"name": item[@"name"] ?: @"",
                    @"api_name": item[@"api_name"] ?: @"",
                    @"rarity": item[@"rarity"] ?: @0,
                    @"height": @(DETAIL_ROW_HEIGHT)
                }];
            }
            [sects addObject:@{@"title": @"Wild Held Items", @"rows": rows}];
        }
    }

    // Abilities
    {
        NSArray *abilities = self.pokemon.abilities;
        if (abilities && abilities.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            for (NSDictionary *ability in abilities) {
                NSString *name = ability[@"name"] ?: @"";
                BOOL isHidden = [ability[@"is_hidden"] boolValue];
                NSString *display = isHidden ?
                    [NSString stringWithFormat:@"%@ (Hidden)", name] : name;
                [rows addObject:@{
                    @"type": @"ability",
                    @"display": display,
                    @"isHidden": @(isHidden)
                }];
            }
            [sects addObject:@{@"title": @"Abilities", @"rows": rows}];
        }
    }

    // Breeding
    {
        NSArray *rows = @[
            @{@"type": @"keyvalue", @"key": @"Egg Groups",
              @"value": ([[self.pokemon.eggGroups componentsJoinedByString:@", "] length] > 0 ?
                  [self.pokemon.eggGroups componentsJoinedByString:@", "] : @"None")},
            @{@"type": @"keyvalue", @"key": @"Gender", @"value": [self.pokemon genderString]},
            @{@"type": @"keyvalue", @"key": @"Hatch Steps",
              @"value": [NSString stringWithFormat:@"~%ld", (long)(self.pokemon.hatchCounter * 256)]},
            @{@"type": @"keyvalue", @"key": @"Base Happy",
              @"value": [NSString stringWithFormat:@"%ld", (long)self.pokemon.baseHappiness]},
            @{@"type": @"keyvalue", @"key": @"Growth Rate", @"value": [self.pokemon formattedGrowthRate]},
        ];
        [sects addObject:@{@"title": @"Breeding", @"rows": rows}];
    }

    // Encounters
    [self buildEncounterSections:sects];

    // Evolution
    [self buildEvolutionSection:sects];

    // Moves (one section per learn method)
    [self buildMoveSections:sects];

    self.sections = sects;

    NSLog(@"[DEBUG] PokemonDetailVC buildSections: %lu sections, tableWidth=%.0f",
          (unsigned long)sects.count, tableWidth);
    NSLog(@"[PERF] PokemonDetailVC buildSections TOTAL: %.1fms (pokemon=%@)",
          (CFAbsoluteTimeGetCurrent() - totalStart) * 1000,
          self.pokemon.name ?: @"nil");
}

- (void)buildTypeEffectivenessSection:(NSMutableArray *)sects width:(CGFloat)tableWidth {
    NSArray *pokemonTypes = self.pokemon.types;
    if (!pokemonTypes || pokemonTypes.count == 0) return;

    NSArray *allTypes = [[DataManager sharedManager] allTypes];
    if (allTypes.count == 0) return;

    NSMutableDictionary *relationsMap = [[NSMutableDictionary alloc] init];
    for (NSDictionary *typeData in allTypes) {
        NSString *name = typeData[@"name"];
        if (name) relationsMap[name] = typeData[@"damage_relations"] ?: @{};
    }

    NSMutableDictionary *multipliers = [[NSMutableDictionary alloc] init];
    for (NSDictionary *typeData in allTypes) {
        NSString *attackType = typeData[@"name"];
        if (!attackType) continue;
        CGFloat mult = 1.0;
        for (NSString *defType in pokemonTypes) {
            NSDictionary *defRelations = relationsMap[defType];
            if (!defRelations) continue;
            NSArray *doubleDamageFrom = defRelations[@"double_damage_from"] ?: @[];
            NSArray *halfDamageFrom = defRelations[@"half_damage_from"] ?: @[];
            NSArray *noDamageFrom = defRelations[@"no_damage_from"] ?: @[];
            BOOL found = NO;
            for (NSString *t in noDamageFrom) {
                if ([t isEqualToString:attackType]) { mult *= 0; found = YES; break; }
            }
            if (!found) {
                for (NSString *t in doubleDamageFrom) {
                    if ([t isEqualToString:attackType]) { mult *= 2; found = YES; break; }
                }
            }
            if (!found) {
                for (NSString *t in halfDamageFrom) {
                    if ([t isEqualToString:attackType]) { mult *= 0.5; break; }
                }
            }
        }
        multipliers[attackType] = @(mult);
    }

    NSMutableArray *weak4x = [[NSMutableArray alloc] init];
    NSMutableArray *weak2x = [[NSMutableArray alloc] init];
    NSMutableArray *resist2x = [[NSMutableArray alloc] init];
    NSMutableArray *resist4x = [[NSMutableArray alloc] init];
    NSMutableArray *immune = [[NSMutableArray alloc] init];

    for (NSDictionary *typeData in allTypes) {
        NSString *name = typeData[@"name"];
        CGFloat m = [multipliers[name] floatValue];
        if (m >= 3.9) [weak4x addObject:name];
        else if (m >= 1.9) [weak2x addObject:name];
        else if (m <= 0.01) [immune addObject:name];
        else if (m <= 0.26) [resist4x addObject:name];
        else if (m <= 0.51) [resist2x addObject:name];
    }

    NSMutableArray *categories = [[NSMutableArray alloc] init];
    if (weak4x.count > 0) [categories addObject:@[@"4\u00D7 Weak", weak4x]];
    if (weak2x.count > 0) [categories addObject:@[@"2\u00D7 Weak", weak2x]];
    if (resist2x.count > 0) [categories addObject:@[@"\u00BD\u00D7 Resist", resist2x]];
    if (resist4x.count > 0) [categories addObject:@[@"\u00BC\u00D7 Resist", resist4x]];
    if (immune.count > 0) [categories addObject:@[@"Immune", immune]];

    if (categories.count == 0) return;

    NSMutableArray *rows = [[NSMutableArray alloc] init];
    for (NSArray *cat in categories) {
        CGFloat h = [TypeGridCell heightForLabel:cat[0] types:cat[1] width:tableWidth];
        [rows addObject:@{
            @"type": @"typegrid",
            @"label": cat[0],
            @"types": cat[1],
            @"height": @(h)
        }];
    }
    [sects addObject:@{@"title": @"Type Effectiveness", @"rows": rows}];
}

- (void)buildEncounterSections:(NSMutableArray *)sects {
    NSArray *encounters = [[DataManager sharedManager] encounterDataForPokemonID:self.pokemonID];
    if (!encounters || encounters.count == 0) return;

    NSUInteger maxVersions = 8;
    NSUInteger maxLocationsPerVersion = 10;
    NSUInteger totalVersions = encounters.count;
    NSUInteger versionsToShow = MIN(totalVersions, maxVersions);

    for (NSUInteger i = 0; i < versionsToShow; i++) {
        NSDictionary *versionEntry = encounters[i];
        NSString *versionName = versionEntry[@"version"] ?: @"Unknown";
        NSArray *locations = versionEntry[@"locations"] ?: @[];

        NSMutableArray *rows = [[NSMutableArray alloc] init];
        NSUInteger locCount = MIN(locations.count, maxLocationsPerVersion);

        for (NSUInteger j = 0; j < locCount; j++) {
            NSDictionary *loc = locations[j];
            NSString *locationName = loc[@"location"] ?: @"Unknown";
            NSString *method = loc[@"method"] ?: @"";
            NSInteger minLevel = [loc[@"min_level"] integerValue];
            NSInteger maxLevel = [loc[@"max_level"] integerValue];
            NSInteger chance = [loc[@"chance"] integerValue];

            NSMutableString *detail = [[NSMutableString alloc] init];
            if (method.length > 0) {
                [detail appendString:method];
            }
            if (minLevel > 0 || maxLevel > 0) {
                if (detail.length > 0) [detail appendString:@", "];
                if (minLevel == maxLevel) {
                    [detail appendFormat:@"Lv. %ld", (long)minLevel];
                } else {
                    [detail appendFormat:@"Lv. %ld\u2013%ld", (long)minLevel, (long)maxLevel];
                }
            }
            if (chance > 0) {
                [detail appendFormat:@" (%ld%%)", (long)chance];
            }

            [rows addObject:@{
                @"type": @"keyvalue",
                @"key": locationName,
                @"value": detail
            }];
        }

        if (locations.count > maxLocationsPerVersion) {
            NSUInteger extra = locations.count - maxLocationsPerVersion;
            [rows addObject:@{
                @"type": @"keyvalue",
                @"key": @"",
                @"value": [NSString stringWithFormat:@"...and %lu more location%s",
                    (unsigned long)extra, extra == 1 ? "" : "s"]
            }];
        }

        // First version section gets "Encounters" prefix in title
        NSString *title;
        if (i == 0) {
            title = [NSString stringWithFormat:@"Encounters \u2014 %@", versionName];
        } else {
            title = versionName;
        }
        [sects addObject:@{@"title": title, @"rows": rows}];
    }

    if (totalVersions > maxVersions) {
        NSUInteger extra = totalVersions - maxVersions;
        NSMutableArray *rows = [[NSMutableArray alloc] init];
        [rows addObject:@{
            @"type": @"keyvalue",
            @"key": @"",
            @"value": [NSString stringWithFormat:@"Also appears in %lu other game%s",
                (unsigned long)extra, extra == 1 ? "" : "s"]
        }];
        [sects addObject:@{@"rows": rows}];
    }
}

- (void)buildEvolutionSection:(NSMutableArray *)sects {
    NSArray *chain = self.pokemon.evolutionChain;
    if (!chain || chain.count < 2) return;

    NSMutableDictionary *entryById = [[NSMutableDictionary alloc] init];
    for (NSDictionary *entry in chain) {
        NSNumber *eid = entry[@"id"];
        if (eid) entryById[eid] = entry;
    }

    NSMutableArray *pairs = [[NSMutableArray alloc] init];
    for (NSDictionary *entry in chain) {
        id fromId = entry[@"from_id"];
        if (!fromId || fromId == [NSNull null]) continue;
        if ([fromId isKindOfClass:[NSString class]] && [fromId length] == 0) continue;
        NSDictionary *fromEntry = entryById[@([fromId integerValue])];
        if (!fromEntry) continue;
        [pairs addObject:@[fromEntry, entry]];
    }

    if (pairs.count == 0) return;

    NSMutableArray *rows = [[NSMutableArray alloc] init];
    for (NSArray *pair in pairs) {
        NSDictionary *from = pair[0];
        NSDictionary *to = pair[1];
        [rows addObject:@{
            @"type": @"evolution",
            @"fromID": from[@"id"] ?: @0,
            @"fromName": from[@"name"] ?: @"",
            @"toID": to[@"id"] ?: @0,
            @"toName": to[@"name"] ?: @"",
            @"condition": [self evolutionConditionText:to],
            @"height": @(DETAIL_EVOLUTION_HEIGHT)
        }];
    }
    [sects addObject:@{@"title": @"Evolution", @"rows": rows}];
}

- (void)buildMoveSections:(NSMutableArray *)sects {
    NSArray *allMoves = self.pokemon.moves;
    if (!allMoves || allMoves.count == 0) return;

    NSMutableArray *levelUp = [[NSMutableArray alloc] init];
    NSMutableArray *machine = [[NSMutableArray alloc] init];
    NSMutableArray *egg = [[NSMutableArray alloc] init];
    NSMutableArray *tutor = [[NSMutableArray alloc] init];
    NSMutableArray *other = [[NSMutableArray alloc] init];

    for (NSDictionary *move in allMoves) {
        NSString *method = move[@"method"] ?: @"";
        if ([method isEqualToString:@"level-up"]) [levelUp addObject:move];
        else if ([method isEqualToString:@"machine"]) [machine addObject:move];
        else if ([method isEqualToString:@"egg"]) [egg addObject:move];
        else if ([method isEqualToString:@"tutor"]) [tutor addObject:move];
        else [other addObject:move];
    }

    NSArray *moveSections = @[
        @[@"Level-Up Moves", levelUp],
        @[@"TM/HM Moves", machine],
        @[@"Egg Moves", egg],
        @[@"Tutor Moves", tutor],
        @[@"Other Moves", other]
    ];

    for (NSArray *ms in moveSections) {
        NSString *title = ms[0];
        NSArray *moves = ms[1];
        if (moves.count == 0) continue;

        NSMutableArray *rows = [[NSMutableArray alloc] init];
        for (NSDictionary *move in moves) {
            [rows addObject:@{
                @"type": @"move",
                @"name": move[@"name"] ?: @"",
                @"level": move[@"level"] ?: @0,
                @"moveType": move[@"type"] ?: @"",
                @"power": move[@"power"] ?: [NSNull null],
                @"accuracy": move[@"accuracy"] ?: [NSNull null],
                @"pp": move[@"pp"] ?: [NSNull null],
                @"height": @(DETAIL_MOVE_HEIGHT)
            }];
        }
        [sects addObject:@{@"title": title, @"rows": rows}];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *section = self.sections[(NSUInteger)indexPath.section];
    NSArray *rows = section[@"rows"];
    NSDictionary *row = rows[(NSUInteger)indexPath.row];
    NSString *type = row[@"type"];

    if ([type isEqualToString:@"flavortext"]) {
        return [self flavorTextCellForRow:row tableView:tableView];
    }
    if ([type isEqualToString:@"statbar"]) {
        static NSString *statID = @"StatBarCell";
        StatBarCell *cell = [tableView dequeueReusableCellWithIdentifier:statID];
        if (!cell) {
            cell = [[StatBarCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:statID];
        }
        [cell configureWithName:row[@"name"] value:[row[@"value"] integerValue]];
        return cell;
    }
    if ([type isEqualToString:@"typegrid"]) {
        static NSString *tgID = @"TypeGridCell";
        TypeGridCell *cell = [tableView dequeueReusableCellWithIdentifier:tgID];
        if (!cell) {
            cell = [[TypeGridCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:tgID];
        }
        [cell configureWithLabel:row[@"label"] types:row[@"types"]];
        return cell;
    }
    if ([type isEqualToString:@"keyvalue"]) {
        static NSString *kvID = @"KeyValueCell";
        KeyValueCell *cell = [tableView dequeueReusableCellWithIdentifier:kvID];
        if (!cell) {
            cell = [[KeyValueCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:kvID];
        }
        if ([row[@"valueFont"] isEqualToString:@"mono"]) {
            UIFont *mono = [UIFont fontWithName:@"Courier-Bold" size:DETAIL_BODY_FONT_SIZE];
            if (!mono) mono = [UIFont boldSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
            [cell configureWithKey:row[@"key"] value:row[@"value"]
                        valueColor:[UIColor darkTextColor] valueFont:mono];
        } else {
            [cell configureWithKey:row[@"key"] value:row[@"value"]];
        }
        return cell;
    }
    if ([type isEqualToString:@"helditem"]) {
        return [self heldItemCellForRow:row tableView:tableView];
    }
    if ([type isEqualToString:@"ability"]) {
        static NSString *abilityID = @"AbilityCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:abilityID];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:abilityID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE];
        }
        cell.textLabel.text = row[@"display"];
        cell.textLabel.textColor = [row[@"isHidden"] boolValue] ?
            [UIColor grayColor] : [UIColor darkTextColor];
        return cell;
    }
    if ([type isEqualToString:@"evolution"]) {
        static NSString *evoID = @"EvolutionCell";
        EvolutionCell *cell = [tableView dequeueReusableCellWithIdentifier:evoID];
        if (!cell) {
            cell = [[EvolutionCell alloc] initWithStyle:UITableViewCellStyleDefault
                                         reuseIdentifier:evoID];
        }
        DataManager *dm = [DataManager sharedManager];
        NSInteger fromID = [row[@"fromID"] integerValue];
        NSInteger toID = [row[@"toID"] integerValue];
        [cell configureWithFromSprite:[dm spriteForPokemonID:fromID]
                             fromName:row[@"fromName"]
                               fromID:fromID
                             toSprite:[dm spriteForPokemonID:toID]
                               toName:row[@"toName"]
                                 toID:toID
                            condition:row[@"condition"]];
        [cell.fromButton addTarget:self action:@selector(evolutionSpriteTapped:)
              forControlEvents:UIControlEventTouchUpInside];
        [cell.toButton addTarget:self action:@selector(evolutionSpriteTapped:)
            forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    if ([type isEqualToString:@"move"]) {
        static NSString *moveID = @"DetailMoveCell";
        DetailMoveCell *cell = [tableView dequeueReusableCellWithIdentifier:moveID];
        if (!cell) {
            cell = [[DetailMoveCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:moveID];
        }
        [cell configureWithName:row[@"name"]
                          level:[row[@"level"] integerValue]
                           type:row[@"moveType"]
                          power:row[@"power"]
                       accuracy:row[@"accuracy"]
                             pp:row[@"pp"]];
        return cell;
    }
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

    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)flavorTextCellForRow:(NSDictionary *)row
                                tableView:(UITableView *)tableView {
    static NSString *ftID = @"FlavorTextCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ftID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:ftID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *sub in cell.contentView.subviews) [sub removeFromSuperview];

    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat w = cell.contentView.bounds.size.width - pad * 2;
    CGFloat cy = 8;
    NSString *versionStr = row[@"versionStr"];
    NSString *text = row[@"text"];

    if (versionStr.length > 0) {
        UIFont *boldFont = [UIFont boldSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
        CGSize vSize = [versionStr sizeWithFont:boldFont
                              constrainedToSize:CGSizeMake(w, 9999)
                                  lineBreakMode:NSLineBreakByWordWrapping];
        UILabel *vLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(pad, cy, w, vSize.height)];
        vLabel.text = versionStr;
        vLabel.font = boldFont;
        vLabel.textColor = [UIColor colorWithWhite:0.20 alpha:1];
        vLabel.backgroundColor = [UIColor clearColor];
        vLabel.numberOfLines = 0;
        vLabel.lineBreakMode = NSLineBreakByWordWrapping;
        vLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [cell.contentView addSubview:vLabel];
        cy += vSize.height + 2;
    }

    UIFont *italicFont = [UIFont italicSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
    CGSize tSize = [text sizeWithFont:italicFont
                    constrainedToSize:CGSizeMake(w, 9999)
                        lineBreakMode:NSLineBreakByWordWrapping];
    UILabel *tLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(pad, cy, w, tSize.height)];
    tLabel.text = text;
    tLabel.font = italicFont;
    tLabel.textColor = [UIColor colorWithWhite:0.30 alpha:1];
    tLabel.backgroundColor = [UIColor clearColor];
    tLabel.numberOfLines = 0;
    tLabel.lineBreakMode = NSLineBreakByWordWrapping;
    tLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [cell.contentView addSubview:tLabel];

    return cell;
}

- (UITableViewCell *)heldItemCellForRow:(NSDictionary *)row
                              tableView:(UITableView *)tableView {
    static NSString *heldID = @"HeldItemCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:heldID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:heldID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *sub in cell.contentView.subviews) [sub removeFromSuperview];

    DataManager *dm = [DataManager sharedManager];
    NSString *name = row[@"name"];
    NSString *apiName = row[@"api_name"];
    NSInteger rarity = [row[@"rarity"] integerValue];
    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat h = 44;

    UIImage *sprite = [dm spriteForItemName:apiName];
    CGFloat nameX = pad;
    if (sprite) {
        UIImageView *sv = [[UIImageView alloc] initWithFrame:
            CGRectMake(pad, (h - 24) / 2, 24, 24)];
        sv.contentMode = UIViewContentModeScaleAspectFit;
        sv.image = sprite;
        [cell.contentView addSubview:sv];
        nameX = pad + 30;
    }

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(nameX, 0, cell.contentView.bounds.size.width - nameX - 66, h)];
    nameLabel.text = name;
    nameLabel.font = [UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [cell.contentView addSubview:nameLabel];

    UILabel *rarityLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(cell.contentView.bounds.size.width - pad - 50, 0, 50, h)];
    rarityLabel.text = [NSString stringWithFormat:@"%ld%%", (long)rarity];
    rarityLabel.font = [UIFont systemFontOfSize:12];
    rarityLabel.textColor = [UIColor grayColor];
    rarityLabel.textAlignment = NSTextAlignmentRight;
    rarityLabel.backgroundColor = [UIColor clearColor];
    rarityLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [cell.contentView addSubview:rarityLabel];

    return cell;
}

#pragma mark - Evolution Navigation

- (void)evolutionSpriteTapped:(UIButton *)sender {
    NSInteger targetID = sender.tag;
    if (targetID <= 0 || targetID == self.pokemon.pokemonID) return;

    PokemonDetailVC *detailVC = [[PokemonDetailVC alloc] init];
    detailVC.pokemonID = targetID;
    UINavigationController *detailNav = [[UINavigationController alloc]
        initWithRootViewController:detailVC];

    UISplitViewController *splitVC = self.splitViewController;
    if (splitVC) {
        splitVC.viewControllers = @[splitVC.viewControllers[0], detailNav];
    } else {
        [self.navigationController pushViewController:detailVC animated:YES];
    }
}

#pragma mark - Helpers

- (NSString *)titleCase:(NSString *)str {
    if (!str || str.length == 0) return @"\u2014";
    return [[[str substringToIndex:1] uppercaseString]
        stringByAppendingString:[str substringFromIndex:1]];
}

- (NSString *)formatShape:(NSString *)shape {
    if (!shape || shape.length == 0) return @"\u2014";
    NSDictionary *shapeNames = @{
        @"ball": @"Ball", @"squiggle": @"Squiggle", @"fish": @"Fish",
        @"arms": @"Arms", @"blob": @"Blob", @"upright": @"Upright",
        @"legs": @"Legs", @"quadruped": @"Quadruped", @"wings": @"Wings",
        @"tentacles": @"Tentacles", @"heads": @"Multiple Bodies",
        @"humanoid": @"Humanoid", @"bug-wings": @"Bug Wings", @"armor": @"Armor",
    };
    return shapeNames[shape] ?: [self titleCase:shape];
}

- (NSString *)formatGeneration:(NSString *)gen {
    if (!gen || gen.length == 0) return @"\u2014";
    NSString *numeral = [[gen componentsSeparatedByString:@"-"] lastObject];
    return [NSString stringWithFormat:@"Gen %@", [numeral uppercaseString]];
}

- (NSString *)evolutionConditionText:(NSDictionary *)entry {
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    NSString *trigger = entry[@"trigger"] ?: @"";

    id minLevel = entry[@"min_level"];
    if (minLevel && minLevel != [NSNull null] && [minLevel integerValue] > 0) {
        [parts addObject:[NSString stringWithFormat:@"Lv. %@", minLevel]];
    }

    if (entry[@"item"] && entry[@"item"] != [NSNull null])
        [parts addObject:entry[@"item"]];
    if (entry[@"held_item"] && entry[@"held_item"] != [NSNull null])
        [parts addObject:[NSString stringWithFormat:@"Hold %@", entry[@"held_item"]]];
    if (entry[@"known_move"] && entry[@"known_move"] != [NSNull null])
        [parts addObject:[NSString stringWithFormat:@"Know %@", entry[@"known_move"]]];
    if (entry[@"known_move_type"] && entry[@"known_move_type"] != [NSNull null])
        [parts addObject:[NSString stringWithFormat:@"%@ move", entry[@"known_move_type"]]];
    if (entry[@"min_happiness"] && entry[@"min_happiness"] != [NSNull null])
        [parts addObject:@"Happiness"];
    if (entry[@"min_beauty"] && entry[@"min_beauty"] != [NSNull null])
        [parts addObject:@"Beauty"];
    if (entry[@"min_affection"] && entry[@"min_affection"] != [NSNull null])
        [parts addObject:@"Affection"];
    if (entry[@"time_of_day"] && entry[@"time_of_day"] != [NSNull null]) {
        NSString *tod = entry[@"time_of_day"];
        if (tod.length > 0) [parts addObject:[self titleCase:tod]];
    }
    if ([entry[@"needs_overworld_rain"] boolValue]) [parts addObject:@"Rain"];
    if ([entry[@"turn_upside_down"] boolValue]) [parts addObject:@"Upside Down"];
    if (entry[@"trade_species"] && entry[@"trade_species"] != [NSNull null])
        [parts addObject:[NSString stringWithFormat:@"Trade w/ %@", entry[@"trade_species"]]];
    id gender = entry[@"gender"];
    if (gender && gender != [NSNull null]) {
        NSInteger g = [gender integerValue];
        if (g == 1) [parts addObject:@"\u2640"];
        else if (g == 2) [parts addObject:@"\u2642"];
    }

    if ([trigger isEqualToString:@"trade"] && parts.count == 0) [parts addObject:@"Trade"];
    if ([trigger isEqualToString:@"use-item"] && parts.count == 0) [parts addObject:@"Use Item"];
    if ([trigger isEqualToString:@"level-up"] && parts.count == 0) [parts addObject:@"Level Up"];

    if (parts.count == 0) return [self titleCase:trigger];
    return [parts componentsJoinedByString:@", "];
}

- (NSDictionary *)versionDisplayNames {
    return @{
        @"red": @"Red", @"blue": @"Blue", @"yellow": @"Yellow",
        @"gold": @"Gold", @"silver": @"Silver", @"crystal": @"Crystal",
        @"ruby": @"Ruby", @"sapphire": @"Sapphire", @"emerald": @"Emerald",
        @"firered": @"FireRed", @"leafgreen": @"LeafGreen",
        @"diamond": @"Diamond", @"pearl": @"Pearl", @"platinum": @"Platinum",
        @"heartgold": @"HeartGold", @"soulsilver": @"SoulSilver",
        @"black": @"Black", @"white": @"White",
        @"black-2": @"Black 2", @"white-2": @"White 2",
        @"x": @"X", @"y": @"Y",
        @"omega-ruby": @"Omega Ruby", @"alpha-sapphire": @"Alpha Sapphire",
        @"sun": @"Sun", @"moon": @"Moon",
        @"ultra-sun": @"Ultra Sun", @"ultra-moon": @"Ultra Moon",
        @"lets-go-pikachu": @"Let's Go Pikachu",
        @"lets-go-eevee": @"Let's Go Eevee",
        @"sword": @"Sword", @"shield": @"Shield",
        @"legends-arceus": @"Legends: Arceus",
        @"scarlet": @"Scarlet", @"violet": @"Violet",
    };
}

@end
