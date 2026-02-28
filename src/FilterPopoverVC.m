#import "FilterPopoverVC.h"
#import "PokemonType.h"
#import "TypeBadgeView.h"
#import <QuartzCore/QuartzCore.h>

#define POPOVER_WIDTH 380
#define POPOVER_HEIGHT 560
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
@end

@implementation FilterPopoverVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.contentSizeForViewInPopover = CGSizeMake(POPOVER_WIDTH, POPOVER_HEIGHT);
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];

    // Scroll view for content (above bottom bar)
    CGFloat scrollHeight = POPOVER_HEIGHT - BOTTOM_BAR_HEIGHT;
    _scrollView = [[UIScrollView alloc] initWithFrame:
        CGRectMake(0, 0, POPOVER_WIDTH, scrollHeight)];
    _scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:_scrollView];

    CGFloat y = SECTION_PADDING;

    // ─── Sort ───
    y = [self addSectionHeaderAtY:y title:@"Sort By"];

    NSArray *sortItems;
    if (_movesMode) {
        sortItems = @[@"Number", @"Name", @"Power"];
    } else {
        sortItems = @[@"Number", @"Name", @"Stat Total"];
    }
    _sortControl = [[UISegmentedControl alloc] initWithItems:sortItems];
    _sortControl.frame = CGRectMake(SECTION_PADDING, y,
        POPOVER_WIDTH - SECTION_PADDING * 2, 30);
    [self selectSortSegment];
    [_sortControl addTarget:self action:@selector(sortChanged:)
           forControlEvents:UIControlEventValueChanged];
    [_scrollView addSubview:_sortControl];
    y += 38;

    // ─── Type Grid ───
    y = [self addSectionHeaderAtY:y title:@"Type"];
    y = [self buildTypeGridAtY:y];

    // ─── Generation List ───
    y = [self addSectionHeaderAtY:y title:@"Generation"];
    y = [self buildGenerationListAtY:y];

    // ─── Category / Damage Class ───
    if (_movesMode) {
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

    _scrollView.contentSize = CGSizeMake(POPOVER_WIDTH, y + SECTION_PADDING);

    // ─── Bottom Bar ───
    [self buildBottomBar];
}

#pragma mark - Section Header

- (CGFloat)addSectionHeaderAtY:(CGFloat)y title:(NSString *)title {
    UILabel *label = [[UILabel alloc] initWithFrame:
        CGRectMake(SECTION_PADDING, y, POPOVER_WIDTH - SECTION_PADDING * 2, SECTION_HEADER_HEIGHT)];
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
    if ([sort isEqualToString:@"number"]) {
        _sortControl.selectedSegmentIndex = 0;
    } else if ([sort isEqualToString:@"name"]) {
        _sortControl.selectedSegmentIndex = 1;
    } else {
        _sortControl.selectedSegmentIndex = 2;
    }
}

- (void)sortChanged:(UISegmentedControl *)sender {
    NSArray *sortKeys;
    if (_movesMode) {
        sortKeys = @[@"number", @"name", @"power"];
    } else {
        sortKeys = @[@"number", @"name", @"stat_total"];
    }
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
    CGFloat startX = (POPOVER_WIDTH - totalW) / 2;

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
    CGFloat startX = (POPOVER_WIDTH - totalW) / 2;

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
    CGFloat startX = (POPOVER_WIDTH - totalW) / 2;

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

- (void)catToggled:(UIButton *)sender {
    NSArray *keys;
    if (_movesMode) {
        keys = @[@"physical", @"special", @"status"];
    } else {
        keys = @[@"legendary", @"mythical", @"baby"];
    }
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

#pragma mark - Bottom Bar

- (void)buildBottomBar {
    CGFloat barY = POPOVER_HEIGHT - BOTTOM_BAR_HEIGHT;
    UIView *bar = [[UIView alloc] initWithFrame:
        CGRectMake(0, barY, POPOVER_WIDTH, BOTTOM_BAR_HEIGHT)];
    bar.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];

    // Top separator
    UIView *sep = [[UIView alloc] initWithFrame:
        CGRectMake(0, 0, POPOVER_WIDTH, 0.5)];
    sep.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1];
    [bar addSubview:sep];

    // Reset button
    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    resetBtn.frame = CGRectMake(SECTION_PADDING, 8, 90, 32);
    [resetBtn setTitle:@"Reset" forState:UIControlStateNormal];
    resetBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [resetBtn setTitleColor:[UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1]
                   forState:UIControlStateNormal];
    [resetBtn addTarget:self action:@selector(resetTapped)
               forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:resetBtn];

    // Apply button
    UIButton *applyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    applyBtn.frame = CGRectMake(POPOVER_WIDTH - SECTION_PADDING - 90, 8, 90, 32);
    applyBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:1];
    applyBtn.layer.cornerRadius = 6;
    [applyBtn setTitle:@"Apply" forState:UIControlStateNormal];
    applyBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [applyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [applyBtn addTarget:self action:@selector(applyTapped)
               forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:applyBtn];

    [self.view addSubview:bar];
}

- (void)resetTapped {
    [_filterState reset];
    [self refreshAllControls];
}

- (void)applyTapped {
    [_delegate filterPopoverDidApply:_filterState];
}

#pragma mark - Refresh

- (void)refreshAllControls {
    [self selectSortSegment];

    NSArray *allTypes = [PokemonType allTypeNames];
    for (NSUInteger i = 0; i < _typeBadges.count; i++) {
        BOOL selected = [_filterState.selectedTypes containsObject:allTypes[i]];
        [self styleTypeButton:_typeBadges[i] selected:selected typeName:allTypes[i]];
    }

    NSArray *gens = generationNames();
    for (NSUInteger i = 0; i < _genButtons.count; i++) {
        BOOL selected = [_filterState.selectedGenerations containsObject:gens[i]];
        [self styleGenButton:_genButtons[i] selected:selected];
    }

    NSArray *catKeys;
    if (_movesMode) {
        catKeys = @[@"physical", @"special", @"status"];
    } else {
        catKeys = @[@"legendary", @"mythical", @"baby"];
    }
    for (NSUInteger i = 0; i < _catButtons.count; i++) {
        BOOL selected = [_filterState.selectedCategories containsObject:catKeys[i]];
        [self styleCatButton:_catButtons[i] selected:selected];
    }
}

@end
