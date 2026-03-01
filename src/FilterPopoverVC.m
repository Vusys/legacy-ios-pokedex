#import "FilterPopoverVC.h"
#import "PokemonType.h"
#import "TypeBadgeView.h"
#import <QuartzCore/QuartzCore.h>

#define SECTION_PADDING 12
#define SECTION_HEADER_HEIGHT 24
#define BOTTOM_BAR_HEIGHT 48

static NSArray *generationNames() {
    return @[@"generation-i", @"generation-ii", @"generation-iii",
             @"generation-iv", @"generation-v", @"generation-vi",
             @"generation-vii", @"generation-viii", @"generation-ix"];
}

static NSString *generationDisplayName(NSString *gen) {
    NSDictionary *map = @{
        @"generation-i": @"Gen I",
        @"generation-ii": @"Gen II",
        @"generation-iii": @"Gen III",
        @"generation-iv": @"Gen IV",
        @"generation-v": @"Gen V",
        @"generation-vi": @"Gen VI",
        @"generation-vii": @"Gen VII",
        @"generation-viii": @"Gen VIII",
        @"generation-ix": @"Gen IX",
    };
    return map[gen] ?: gen;
}

@interface FilterPopoverVC ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UISegmentedControl *sortControl;
@property (nonatomic, strong) NSMutableArray *typeBadges;
@property (nonatomic, strong) NSMutableArray *genButtons;
@property (nonatomic, strong) NSMutableArray *catButtons;
@property (nonatomic, strong) UIButton *favButton;
@property (nonatomic, strong) UIView *bottomBar;
@end

@implementation FilterPopoverVC

- (BOOL)showTypes {
    return [_filterMode isEqualToString:@"pokemon"] ||
           [_filterMode isEqualToString:@"moves"] ||
           [_filterMode isEqualToString:@"berries"];
}

- (BOOL)showGenerations {
    return [_filterMode isEqualToString:@"pokemon"] ||
           [_filterMode isEqualToString:@"moves"] ||
           [_filterMode isEqualToString:@"abilities"];
}

- (BOOL)showCategories {
    return [_filterMode isEqualToString:@"pokemon"] || [_filterMode isEqualToString:@"moves"];
}

- (NSArray *)sortItemsForMode {
    if ([_filterMode isEqualToString:@"moves"])      return @[@"Number", @"Name", @"Power"];
    if ([_filterMode isEqualToString:@"abilities"])  return @[@"Number", @"Name"];
    if ([_filterMode isEqualToString:@"items"])      return @[@"Number", @"Name", @"Cost"];
    if ([_filterMode isEqualToString:@"natures"])    return @[@"Number", @"Name"];
    if ([_filterMode isEqualToString:@"egg_groups"]) return @[@"Number", @"Name"];
    if ([_filterMode isEqualToString:@"berries"])    return @[@"Number", @"Name", @"Power"];
    if ([_filterMode isEqualToString:@"locations"])  return @[@"Number", @"Name"];
    return @[@"Number", @"Name", @"Stat Total"]; // pokemon
}

- (NSArray *)sortKeysForMode {
    if ([_filterMode isEqualToString:@"moves"])      return @[@"number", @"name", @"power"];
    if ([_filterMode isEqualToString:@"abilities"])  return @[@"number", @"name"];
    if ([_filterMode isEqualToString:@"items"])      return @[@"number", @"name", @"cost"];
    if ([_filterMode isEqualToString:@"natures"])    return @[@"number", @"name"];
    if ([_filterMode isEqualToString:@"egg_groups"]) return @[@"number", @"name"];
    if ([_filterMode isEqualToString:@"berries"])    return @[@"number", @"name", @"power"];
    if ([_filterMode isEqualToString:@"locations"])  return @[@"number", @"name"];
    return @[@"number", @"name", @"stat_total"]; // pokemon
}

- (CGFloat)contentWidth {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 380;
    }
    return self.view.bounds.size.width;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (!_filterMode) _filterMode = @"pokemon";

    // Add Cancel/Apply buttons on iPhone (modal presentation)
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
            target:self action:@selector(cancelTapped)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithTitle:@"Apply"
                    style:UIBarButtonItemStyleDone
                   target:self action:@selector(applyTapped)];
        self.title = @"Filter";
    }

    // Compute popover height based on content
    CGFloat contentHeight = SECTION_PADDING;
    contentHeight += 42; // favourites toggle
    contentHeight += SECTION_HEADER_HEIGHT + 38; // sort
    if ([self showTypes]) contentHeight += SECTION_HEADER_HEIGHT + 170; // type grid ~5 rows
    if ([self showGenerations]) contentHeight += SECTION_HEADER_HEIGHT + 105; // gen grid ~3 rows
    if ([self showCategories]) contentHeight += SECTION_HEADER_HEIGHT + 42; // cat buttons
    contentHeight += SECTION_PADDING;
    CGFloat popoverHeight = MIN(contentHeight + BOTTOM_BAR_HEIGHT, 560);

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.contentSizeForViewInPopover = CGSizeMake(380, popoverHeight);
    }
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];

    // Scroll view for content (above bottom bar)
    CGFloat scrollHeight = popoverHeight - BOTTOM_BAR_HEIGHT;
    _scrollView = [[UIScrollView alloc] initWithFrame:
        CGRectMake(0, 0, [self contentWidth], scrollHeight)];
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_scrollView];

    CGFloat y = SECTION_PADDING;

    // ─── Favourites ───
    {
        CGFloat btnW = 140;
        CGFloat btnH = 30;
        CGFloat startX = ([self contentWidth] - btnW) / 2;
        _favButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _favButton.frame = CGRectMake(startX, y, btnW, btnH);
        _favButton.layer.cornerRadius = 4;
        _favButton.layer.borderWidth = 1;
        _favButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        [_favButton setTitle:@"\u2605 Favourites Only" forState:UIControlStateNormal];
        [_favButton addTarget:self action:@selector(favToggled:)
              forControlEvents:UIControlEventTouchUpInside];
        [self styleFavButton:_favButton selected:_filterState.showFavouritesOnly];
        [_scrollView addSubview:_favButton];
        y += btnH + SECTION_PADDING;
    }

    // ─── Sort ───
    y = [self addSectionHeaderAtY:y title:@"Sort By"];

    _sortControl = [[UISegmentedControl alloc] initWithItems:[self sortItemsForMode]];
    _sortControl.frame = CGRectMake(SECTION_PADDING, y,
        [self contentWidth] - SECTION_PADDING * 2, 30);
    [self selectSortSegment];
    [_sortControl addTarget:self action:@selector(sortChanged:)
           forControlEvents:UIControlEventValueChanged];
    [_scrollView addSubview:_sortControl];
    y += 38;

    // ─── Type Grid (pokemon + moves only) ───
    if ([self showTypes]) {
        y = [self addSectionHeaderAtY:y title:@"Type"];
        y = [self buildTypeGridAtY:y];
    }

    // ─── Generation List (pokemon + moves + abilities) ───
    if ([self showGenerations]) {
        y = [self addSectionHeaderAtY:y title:@"Generation"];
        y = [self buildGenerationListAtY:y];
    }

    // ─── Category / Damage Class (pokemon + moves only) ───
    if ([self showCategories]) {
        if ([_filterMode isEqualToString:@"moves"]) {
            y = [self addSectionHeaderAtY:y title:@"Damage Class"];
            y = [self buildCategoryButtonsAtY:y
                                       labels:@[@"Physical", @"Special", @"Status"]
                                         keys:@[@"physical", @"special", @"status"]];
        } else {
            y = [self addSectionHeaderAtY:y title:@"Category"];
            y = [self buildCategoryButtonsAtY:y
                                       labels:@[@"Legendary", @"Mythical", @"Baby"]
                                         keys:@[@"legendary", @"mythical", @"baby"]];
        }
    }

    _scrollView.contentSize = CGSizeMake([self contentWidth], y + SECTION_PADDING);

    // ─── Bottom Bar ───
    [self buildBottomBarAtY:popoverHeight - BOTTOM_BAR_HEIGHT];
}

#pragma mark - Section Header

- (CGFloat)addSectionHeaderAtY:(CGFloat)y title:(NSString *)title {
    UILabel *label = [[UILabel alloc] initWithFrame:
        CGRectMake(SECTION_PADDING, y, [self contentWidth] - SECTION_PADDING * 2, SECTION_HEADER_HEIGHT)];
    label.text = title;
    label.font = [UIFont boldSystemFontOfSize:13];
    label.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    label.backgroundColor = [UIColor clearColor];
    [_scrollView addSubview:label];
    return y + SECTION_HEADER_HEIGHT;
}

#pragma mark - Sort Control

- (void)selectSortSegment {
    NSString *sort = _filterState.sortBy ?: @"number";
    NSArray *keys = [self sortKeysForMode];
    NSUInteger idx = [keys indexOfObject:sort];
    _sortControl.selectedSegmentIndex = (idx != NSNotFound) ? (NSInteger)idx : 0;
}

- (void)sortChanged:(UISegmentedControl *)sender {
    NSArray *sortKeys = [self sortKeysForMode];
    NSInteger idx = sender.selectedSegmentIndex;
    if (idx >= 0 && idx < (NSInteger)sortKeys.count) {
        _filterState.sortBy = sortKeys[idx];
    }
}

#pragma mark - Type Grid

- (CGFloat)buildTypeGridAtY:(CGFloat)y {
    _typeBadges = [[NSMutableArray alloc] init];
    NSArray *allTypes = [PokemonType allTypeNames];

    CGFloat badgeW = 70;
    CGFloat badgeH = 28;
    CGFloat hPad = 6;
    CGFloat vPad = 6;
    NSInteger cols = 4;
    CGFloat totalW = cols * badgeW + (cols - 1) * hPad;
    CGFloat startX = ([self contentWidth] - totalW) / 2;

    for (NSUInteger i = 0; i < allTypes.count; i++) {
        NSString *typeName = allTypes[i];
        NSInteger row = i / cols;
        NSInteger col = i % cols;

        CGFloat x = startX + col * (badgeW + hPad);
        CGFloat ty = y + row * (badgeH + vPad);

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(x, ty, badgeW, badgeH);
        btn.tag = i;
        btn.layer.cornerRadius = 4;
        btn.layer.borderWidth = 2;
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:11];
        [btn setTitle:[[typeName uppercaseString]
            substringToIndex:MIN(typeName.length, (NSUInteger)8)]
             forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.3];
        btn.titleLabel.shadowOffset = CGSizeMake(0, -0.5);
        btn.backgroundColor = [PokemonType colorForTypeName:typeName];
        [btn addTarget:self action:@selector(typeToggled:)
              forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:btn];
        [_typeBadges addObject:btn];

        BOOL selected = [_filterState.selectedTypes containsObject:typeName];
        [self styleTypeButton:btn selected:selected typeName:typeName];
    }

    NSInteger rows = (allTypes.count + cols - 1) / cols;
    return y + rows * (badgeH + vPad);
}

- (void)typeToggled:(UIButton *)sender {
    NSArray *allTypes = [PokemonType allTypeNames];
    NSString *typeName = allTypes[sender.tag];

    if ([_filterState.selectedTypes containsObject:typeName]) {
        [_filterState.selectedTypes removeObject:typeName];
        [self styleTypeButton:sender selected:NO typeName:typeName];
    } else {
        [_filterState.selectedTypes addObject:typeName];
        [self styleTypeButton:sender selected:YES typeName:typeName];
    }
}

- (void)styleTypeButton:(UIButton *)btn selected:(BOOL)selected typeName:(NSString *)typeName {
    if (selected) {
        btn.alpha = 1.0;
        btn.layer.borderColor = [[UIColor whiteColor] CGColor];
    } else {
        btn.alpha = 0.4;
        btn.layer.borderColor = [[UIColor clearColor] CGColor];
    }
}

#pragma mark - Generation List

- (CGFloat)buildGenerationListAtY:(CGFloat)y {
    _genButtons = [[NSMutableArray alloc] init];
    NSArray *gens = generationNames();

    CGFloat btnW = 80;
    CGFloat btnH = 28;
    CGFloat hPad = 4;
    CGFloat vPad = 4;
    NSInteger cols = 3;
    CGFloat totalW = cols * btnW + (cols - 1) * hPad;
    CGFloat startX = ([self contentWidth] - totalW) / 2;

    for (NSUInteger i = 0; i < gens.count; i++) {
        NSString *gen = gens[i];
        NSInteger row = i / cols;
        NSInteger col = i % cols;

        CGFloat x = startX + col * (btnW + hPad);
        CGFloat ty = y + row * (btnH + vPad);

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(x, ty, btnW, btnH);
        btn.tag = i;
        btn.layer.cornerRadius = 4;
        btn.layer.borderWidth = 1;
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        [btn setTitle:generationDisplayName(gen) forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(genToggled:)
              forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:btn];
        [_genButtons addObject:btn];

        BOOL selected = [_filterState.selectedGenerations containsObject:gen];
        [self styleGenButton:btn selected:selected];
    }

    NSInteger rows = (gens.count + cols - 1) / cols;
    return y + rows * (btnH + vPad) + 4;
}

- (void)genToggled:(UIButton *)sender {
    NSArray *gens = generationNames();
    NSString *gen = gens[sender.tag];

    if ([_filterState.selectedGenerations containsObject:gen]) {
        [_filterState.selectedGenerations removeObject:gen];
        [self styleGenButton:sender selected:NO];
    } else {
        [_filterState.selectedGenerations addObject:gen];
        [self styleGenButton:sender selected:YES];
    }
}

- (void)styleGenButton:(UIButton *)btn selected:(BOOL)selected {
    if (selected) {
        btn.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1];
        btn.layer.borderColor = [[UIColor colorWithRed:0.15 green:0.3 blue:0.7 alpha:1] CGColor];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        btn.backgroundColor = [UIColor whiteColor];
        btn.layer.borderColor = [[UIColor colorWithWhite:0.75 alpha:1] CGColor];
        [btn setTitleColor:[UIColor colorWithWhite:0.3 alpha:1] forState:UIControlStateNormal];
    }
}

#pragma mark - Category / Damage Class Buttons

- (CGFloat)buildCategoryButtonsAtY:(CGFloat)y
                             labels:(NSArray *)labels
                               keys:(NSArray *)keys {
    _catButtons = [[NSMutableArray alloc] init];

    CGFloat btnW = 100;
    CGFloat btnH = 30;
    CGFloat hPad = 8;
    CGFloat totalW = labels.count * btnW + (labels.count - 1) * hPad;
    CGFloat startX = ([self contentWidth] - totalW) / 2;

    for (NSUInteger i = 0; i < labels.count; i++) {
        CGFloat x = startX + i * (btnW + hPad);

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(x, y, btnW, btnH);
        btn.tag = i;
        btn.layer.cornerRadius = 4;
        btn.layer.borderWidth = 1;
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        [btn setTitle:labels[i] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(catToggled:)
              forControlEvents:UIControlEventTouchUpInside];
        [_scrollView addSubview:btn];
        [_catButtons addObject:btn];

        BOOL selected = [_filterState.selectedCategories containsObject:keys[i]];
        [self styleCatButton:btn selected:selected];
    }

    return y + btnH + 8;
}

- (NSArray *)categoryKeysForMode {
    if ([_filterMode isEqualToString:@"moves"]) {
        return @[@"physical", @"special", @"status"];
    }
    return @[@"legendary", @"mythical", @"baby"];
}

- (void)catToggled:(UIButton *)sender {
    NSArray *keys = [self categoryKeysForMode];
    if (sender.tag >= (NSInteger)keys.count) return;
    NSString *key = keys[sender.tag];

    if ([_filterState.selectedCategories containsObject:key]) {
        [_filterState.selectedCategories removeObject:key];
        [self styleCatButton:sender selected:NO];
    } else {
        [_filterState.selectedCategories addObject:key];
        [self styleCatButton:sender selected:YES];
    }
}

- (void)styleCatButton:(UIButton *)btn selected:(BOOL)selected {
    if (selected) {
        btn.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1];
        btn.layer.borderColor = [[UIColor colorWithRed:0.15 green:0.3 blue:0.7 alpha:1] CGColor];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        btn.backgroundColor = [UIColor whiteColor];
        btn.layer.borderColor = [[UIColor colorWithWhite:0.75 alpha:1] CGColor];
        [btn setTitleColor:[UIColor colorWithWhite:0.3 alpha:1] forState:UIControlStateNormal];
    }
}

#pragma mark - Favourites Toggle

- (void)favToggled:(UIButton *)sender {
    _filterState.showFavouritesOnly = !_filterState.showFavouritesOnly;
    [self styleFavButton:sender selected:_filterState.showFavouritesOnly];
}

- (void)styleFavButton:(UIButton *)btn selected:(BOOL)selected {
    if (selected) {
        btn.backgroundColor = [UIColor colorWithRed:0.85 green:0.65 blue:0.0 alpha:1];
        btn.layer.borderColor = [[UIColor colorWithRed:0.70 green:0.50 blue:0.0 alpha:1] CGColor];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        btn.backgroundColor = [UIColor whiteColor];
        btn.layer.borderColor = [[UIColor colorWithWhite:0.75 alpha:1] CGColor];
        [btn setTitleColor:[UIColor colorWithWhite:0.3 alpha:1] forState:UIControlStateNormal];
    }
}

#pragma mark - Bottom Bar

- (void)buildBottomBarAtY:(CGFloat)barY {
    _bottomBar = [[UIView alloc] initWithFrame:
        CGRectMake(0, barY, [self contentWidth], BOTTOM_BAR_HEIGHT)];
    _bottomBar.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
    _bottomBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

    // Top separator
    UIView *sep = [[UIView alloc] initWithFrame:
        CGRectMake(0, 0, [self contentWidth], 0.5)];
    sep.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    sep.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1];
    [_bottomBar addSubview:sep];

    // Reset button
    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    resetBtn.frame = CGRectMake(SECTION_PADDING, 8, 90, 32);
    [resetBtn setTitle:@"Reset" forState:UIControlStateNormal];
    resetBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [resetBtn setTitleColor:[UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1]
                   forState:UIControlStateNormal];
    [resetBtn addTarget:self action:@selector(resetTapped)
               forControlEvents:UIControlEventTouchUpInside];
    [_bottomBar addSubview:resetBtn];

    // Apply button
    UIButton *applyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    applyBtn.frame = CGRectMake([self contentWidth] - SECTION_PADDING - 90, 8, 90, 32);
    applyBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    applyBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:1];
    applyBtn.layer.cornerRadius = 6;
    [applyBtn setTitle:@"Apply" forState:UIControlStateNormal];
    applyBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [applyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [applyBtn addTarget:self action:@selector(applyTapped)
               forControlEvents:UIControlEventTouchUpInside];
    [_bottomBar addSubview:applyBtn];

    [self.view addSubview:_bottomBar];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat viewH = self.view.bounds.size.height;
    CGFloat viewW = self.view.bounds.size.width;
    _bottomBar.frame = CGRectMake(0, viewH - BOTTOM_BAR_HEIGHT, viewW, BOTTOM_BAR_HEIGHT);
    _scrollView.frame = CGRectMake(0, 0, viewW, viewH - BOTTOM_BAR_HEIGHT);
}

- (void)resetTapped {
    [_filterState reset];
    [self refreshAllControls];
}

- (void)applyTapped {
    [_delegate filterPopoverDidApply:_filterState];
}

- (void)cancelTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Refresh

- (void)refreshAllControls {
    [self styleFavButton:_favButton selected:_filterState.showFavouritesOnly];
    [self selectSortSegment];

    if ([self showTypes]) {
        NSArray *allTypes = [PokemonType allTypeNames];
        for (NSUInteger i = 0; i < _typeBadges.count; i++) {
            BOOL selected = [_filterState.selectedTypes containsObject:allTypes[i]];
            [self styleTypeButton:_typeBadges[i] selected:selected typeName:allTypes[i]];
        }
    }

    if ([self showGenerations]) {
        NSArray *gens = generationNames();
        for (NSUInteger i = 0; i < _genButtons.count; i++) {
            BOOL selected = [_filterState.selectedGenerations containsObject:gens[i]];
            [self styleGenButton:_genButtons[i] selected:selected];
        }
    }

    if ([self showCategories]) {
        NSArray *catKeys = [self categoryKeysForMode];
        for (NSUInteger i = 0; i < _catButtons.count; i++) {
            BOOL selected = [_filterState.selectedCategories containsObject:catKeys[i]];
            [self styleCatButton:_catButtons[i] selected:selected];
        }
    }
}

@end
