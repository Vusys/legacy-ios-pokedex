#import "PokemonDetailVC.h"
#import "Pokemon.h"
#import "PokemonType.h"
#import "DataManager.h"
#import "TypeBadgeView.h"
#import "StatBarView.h"
#import "TexturedBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

#define CARD_MARGIN 16
#define CARD_PADDING 14
#define CARD_SPACING 14
#define CARD_CORNER 8
#define SECTION_FONT_SIZE 13
#define BODY_FONT_SIZE 14

@interface PokemonDetailVC ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) TexturedBackgroundView *backgroundView;
@property (nonatomic, strong) Pokemon *pokemon;
@property (nonatomic, assign) CGFloat lastBuiltWidth;
@property (nonatomic, assign) BOOL showShiny;
@property (nonatomic, assign) BOOL showFemale;
@end

@implementation PokemonDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lastBuiltWidth = 0;

    // Textured background
    self.backgroundView = [[TexturedBackgroundView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.backgroundView];

    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleHeight;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    // Style nav bar
    [self styleNavBar];

    // Load data
    if (self.pokemonID > 0) {
        CFAbsoluteTime loadStart = CFAbsoluteTimeGetCurrent();
        self.pokemon = [[DataManager sharedManager] pokemonDetailWithID:self.pokemonID];
        NSLog(@"[PERF] PokemonDetailVC loadData: %.1fms (id=%ld, name=%@)",
              (CFAbsoluteTimeGetCurrent() - loadStart) * 1000,
              (long)self.pokemonID, self.pokemon.name ?: @"nil");
        self.title = self.pokemon.name ?: @"Pokédex";
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self styleNavBar];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    if (w > 0 && w != self.lastBuiltWidth) {
        CGFloat oldWidth = self.lastBuiltWidth;
        self.lastBuiltWidth = w;
        NSLog(@"[PERF] PokemonDetailVC viewDidLayoutSubviews: width %.0f -> %.0f (pokemon=%@)",
              oldWidth, w, self.pokemon.name ?: @"nil");
        [self rebuildLayout];
    }
}

- (void)styleNavBar {
    CGSize navSize = CGSizeMake(1, 44);
    UIGraphicsBeginImageContextWithOptions(navSize, YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] = {
        0.55, 0.0, 0.0, 1.0,
        0.80, 0.0, 0.0, 1.0
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
    CGContextDrawLinearGradient(ctx, gradient,
        CGPointMake(0, 0), CGPointMake(0, navSize.height), 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    UIImage *navImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self.navigationController.navigationBar setBackgroundImage:navImage
        forBarMetrics:UIBarMetricsDefault];

    self.navigationController.navigationBar.titleTextAttributes = @{
        UITextAttributeTextColor: [UIColor whiteColor],
        UITextAttributeTextShadowColor: [UIColor colorWithWhite:0 alpha:0.6],
        UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
        UITextAttributeFont: [UIFont boldSystemFontOfSize:20]
    };
}

#pragma mark - Layout Builder

- (void)rebuildLayout {
    // Clear scroll view
    for (UIView *sub in [self.scrollView.subviews copy]) {
        [sub removeFromSuperview];
    }

    if (!self.pokemon) {
        // Empty state
        CGFloat w = self.scrollView.bounds.size.width;
        UILabel *empty = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, w, 40)];
        empty.text = @"Select a Pokémon";
        empty.textAlignment = NSTextAlignmentCenter;
        empty.font = [UIFont systemFontOfSize:18];
        empty.textColor = [UIColor grayColor];
        empty.backgroundColor = [UIColor clearColor];
        [self.scrollView addSubview:empty];
        self.scrollView.contentSize = CGSizeMake(w, 200);
        return;
    }

    CGFloat contentWidth = self.scrollView.bounds.size.width;
    CGFloat cardWidth = contentWidth - (CARD_MARGIN * 2);
    CGFloat y = CARD_SPACING;

    CFAbsoluteTime totalStart = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime cardStart;

    // ─── Header Card ────────────────────────────────────────
    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildHeaderCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   header: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    // ─── Flavor Text Card ───────────────────────────────────
    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildFlavorTextCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   flavor: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    // ─── Base Stats Card ────────────────────────────────────
    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildStatsCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   stats: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    // ─── Type Effectiveness Card ────────────────────────────
    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildTypeEffectivenessCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   type_eff: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    // ─── Info Card ──────────────────────────────────────────
    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildInfoCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   info: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    // ─── Wild Held Items Card ───────────────────────────────
    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildHeldItemsCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   held_items: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    // ─── Abilities Card ─────────────────────────────────────
    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildAbilitiesCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   abilities: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    // ─── Breeding Card ──────────────────────────────────────
    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildBreedingCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   breeding: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    // ─── Evolution Chain Card ───────────────────────────────
    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildEvolutionCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   evolution: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    // ─── Moves Card ─────────────────────────────────────────
    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildMovesCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   moves: %.1fms (%lu moves)",
          (CFAbsoluteTimeGetCurrent() - cardStart) * 1000,
          (unsigned long)self.pokemon.moves.count);

    y += CARD_SPACING;
    self.scrollView.contentSize = CGSizeMake(contentWidth, y);

    NSLog(@"[PERF] PokemonDetailVC rebuildLayout TOTAL: %.1fms (pokemon=%@, width=%.0f)",
          (CFAbsoluteTimeGetCurrent() - totalStart) * 1000,
          self.pokemon.name ?: @"nil", contentWidth);
}

#pragma mark - Card Builders

- (UIView *)createCardAtY:(CGFloat)y width:(CGFloat)width height:(CGFloat)height {
    UIView *card = [[UIView alloc] initWithFrame:
        CGRectMake(CARD_MARGIN, y, width, height)];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = CARD_CORNER;
    card.layer.borderWidth = 0.5;
    card.layer.borderColor = [[UIColor colorWithWhite:0.80 alpha:1] CGColor];
    card.layer.shadowColor = [[UIColor blackColor] CGColor];
    card.layer.shadowOffset = CGSizeMake(0, 2);
    card.layer.shadowOpacity = 0.12;
    card.layer.shadowRadius = 3;
    card.clipsToBounds = NO;
    return card;
}

- (UILabel *)sectionHeaderWithTitle:(NSString *)title inCard:(UIView *)card atY:(CGFloat)y {
    CGFloat w = card.bounds.size.width - (CARD_PADDING * 2);
    UILabel *header = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, y, w, 18)];
    header.text = [title uppercaseString];
    header.font = [UIFont boldSystemFontOfSize:SECTION_FONT_SIZE];
    header.textColor = [UIColor colorWithWhite:0.35 alpha:1];
    header.backgroundColor = [UIColor clearColor];
    header.shadowColor = [UIColor colorWithWhite:1 alpha:0.8];
    header.shadowOffset = CGSizeMake(0, 1);
    [card addSubview:header];

    // Separator line
    UIView *sep = [[UIView alloc] initWithFrame:
        CGRectMake(CARD_PADDING, y + 20, w, 0.5)];
    sep.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
    [card addSubview:sep];

    return header;
}

- (CGFloat)buildHeaderCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    DataManager *dm = [DataManager sharedManager];
    NSInteger pid = self.pokemon.pokemonID;

    // ── Determine artwork image ──
    UIImage *artworkImage = [dm artworkForPokemonID:pid];
    BOOL hasArtwork = (artworkImage != nil);
    // Scale artwork to 65% of card width, capped
    CGFloat artworkDisplaySize = hasArtwork ?
        MIN(floorf(cardWidth * 0.65), 280) : 96;

    // ── Determine front/back sprite images (respecting shiny + gender toggles) ──
    UIImage *frontImage;
    UIImage *backImage;
    if (self.showFemale && self.pokemon.hasFemaleSprite) {
        frontImage = [dm femaleSpriteForPokemonID:pid];
    } else if (self.showShiny) {
        frontImage = [dm shinySpriteForPokemonID:pid];
    } else {
        frontImage = [dm spriteForPokemonID:pid];
    }
    backImage = [dm backSpriteForPokemonID:pid];

    // If no artwork, fall back to front sprite as hero image
    if (!hasArtwork) {
        artworkImage = frontImage;
    }

    // ── Layout calculations ──
    CGFloat innerWidth = cardWidth - CARD_PADDING * 2;

    // Info row: number(18) + name(28) + genus(22) + badge(20) + gap(8)
    CGFloat infoHeight = 96;
    // Artwork row
    CGFloat artworkRowHeight = artworkDisplaySize + 8;
    // Sprite strip row (front/back + toggle buttons)
    CGFloat spriteStripH = 88;

    CGFloat cardHeight = CARD_PADDING + infoHeight + artworkRowHeight + spriteStripH + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    CGFloat cy = CARD_PADDING;

    // ── Info section (number, name, genus, types) ──
    // Number + Name on same line
    UILabel *numberLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, cy, innerWidth, 18)];
    numberLabel.text = [self.pokemon formattedID];
    numberLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
    if (!numberLabel.font) numberLabel.font = [UIFont boldSystemFontOfSize:14];
    numberLabel.textColor = [UIColor grayColor];
    numberLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:numberLabel];
    cy += 18;

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, cy, innerWidth, 28)];
    nameLabel.text = self.pokemon.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:nameLabel];
    cy += 28;

    UILabel *genusLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, cy, innerWidth, 18)];
    genusLabel.text = self.pokemon.genus;
    genusLabel.font = [UIFont italicSystemFontOfSize:13];
    genusLabel.textColor = [UIColor grayColor];
    genusLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:genusLabel];
    cy += 22;

    // Type badges
    CGFloat badgeX = CARD_PADDING;
    for (NSString *type in self.pokemon.types) {
        TypeBadgeView *badge = [[TypeBadgeView alloc] initWithTypeName:type];
        badge.frame = CGRectMake(badgeX, cy,
                                 [TypeBadgeView badgeWidth], [TypeBadgeView badgeHeight]);
        [card addSubview:badge];
        badgeX += [TypeBadgeView badgeWidth] + 6;
    }
    cy += [TypeBadgeView badgeHeight] + 8;

    // ── Artwork (centered) ──
    CGFloat artworkX = (cardWidth - artworkDisplaySize) / 2.0;
    UIImageView *artworkView = [[UIImageView alloc] initWithFrame:
        CGRectMake(artworkX, cy, artworkDisplaySize, artworkDisplaySize)];
    artworkView.contentMode = UIViewContentModeScaleAspectFit;
    artworkView.image = artworkImage;
    artworkView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    artworkView.layer.cornerRadius = 8;
    artworkView.layer.borderWidth = 0.5;
    artworkView.layer.borderColor = [[UIColor colorWithWhite:0.88 alpha:1] CGColor];
    [card addSubview:artworkView];
    cy += artworkDisplaySize + 8;

    // ── Sprite strip: front + back sprites and toggle buttons ──
    CGFloat stripY = cy;
    CGFloat smallSprite = 80;

    // Front sprite
    CGFloat stripX = CARD_PADDING;
    CGFloat spriteOffY = stripY + (spriteStripH - smallSprite) / 2.0;
    UIImageView *frontView = [[UIImageView alloc] initWithFrame:
        CGRectMake(stripX, spriteOffY, smallSprite, smallSprite)];
    frontView.contentMode = UIViewContentModeScaleAspectFit;
    frontView.image = frontImage;
    frontView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    frontView.layer.cornerRadius = 4;
    frontView.layer.borderWidth = 0.5;
    frontView.layer.borderColor = [[UIColor colorWithWhite:0.85 alpha:1] CGColor];
    [card addSubview:frontView];
    stripX += smallSprite + 6;

    // Back sprite
    if (backImage) {
        UIImageView *backView = [[UIImageView alloc] initWithFrame:
            CGRectMake(stripX, spriteOffY, smallSprite, smallSprite)];
        backView.contentMode = UIViewContentModeScaleAspectFit;
        backView.image = backImage;
        backView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        backView.layer.cornerRadius = 4;
        backView.layer.borderWidth = 0.5;
        backView.layer.borderColor = [[UIColor colorWithWhite:0.85 alpha:1] CGColor];
        [card addSubview:backView];
        stripX += smallSprite + 6;
    }

    // Toggle buttons (right-aligned, vertically centered in strip)
    CGFloat btnH = 28;
    CGFloat btnY = stripY + (spriteStripH - btnH) / 2.0;
    CGFloat btnRight = cardWidth - CARD_PADDING;

    // Gender toggle (only if female sprite exists)
    if (self.pokemon.hasFemaleSprite) {
        NSString *genderTitle = self.showFemale ? @"\u2640" : @"\u2642";
        UIButton *genderBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        genderBtn.frame = CGRectMake(btnRight - 36, btnY, 36, btnH);
        [genderBtn setTitle:genderTitle forState:UIControlStateNormal];
        [genderBtn setTitleColor:(self.showFemale ?
            [UIColor colorWithRed:0.95 green:0.3 blue:0.5 alpha:1] :
            [UIColor colorWithRed:0.2 green:0.4 blue:0.9 alpha:1])
            forState:UIControlStateNormal];
        genderBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        genderBtn.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
        genderBtn.layer.cornerRadius = 4;
        genderBtn.layer.borderWidth = 0.5;
        genderBtn.layer.borderColor = [[UIColor colorWithWhite:0.80 alpha:1] CGColor];
        [genderBtn addTarget:self action:@selector(toggleGender)
            forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:genderBtn];
        btnRight -= 42;
    }

    // Shiny toggle
    {
        UIButton *shinyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        shinyBtn.frame = CGRectMake(btnRight - 56, btnY, 56, btnH);
        [shinyBtn setTitle:@"\u2605 Shiny" forState:UIControlStateNormal];
        [shinyBtn setTitleColor:(self.showShiny ?
            [UIColor colorWithRed:0.85 green:0.65 blue:0.0 alpha:1] :
            [UIColor colorWithWhite:0.45 alpha:1])
            forState:UIControlStateNormal];
        shinyBtn.titleLabel.font = [UIFont boldSystemFontOfSize:11];
        shinyBtn.backgroundColor = self.showShiny ?
            [UIColor colorWithRed:1.0 green:0.97 blue:0.85 alpha:1] :
            [UIColor colorWithWhite:0.94 alpha:1];
        shinyBtn.layer.cornerRadius = 4;
        shinyBtn.layer.borderWidth = 0.5;
        shinyBtn.layer.borderColor = (self.showShiny ?
            [[UIColor colorWithRed:0.85 green:0.65 blue:0.0 alpha:0.5] CGColor] :
            [[UIColor colorWithWhite:0.80 alpha:1] CGColor]);
        [shinyBtn addTarget:self action:@selector(toggleShiny)
            forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:shinyBtn];
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (void)toggleShiny {
    self.showShiny = !self.showShiny;
    self.showFemale = NO;
    CGPoint offset = self.scrollView.contentOffset;
    [self rebuildLayout];
    self.scrollView.contentOffset = offset;
}

- (void)toggleGender {
    self.showFemale = !self.showFemale;
    self.showShiny = NO;
    CGPoint offset = self.scrollView.contentOffset;
    [self rebuildLayout];
    self.scrollView.contentOffset = offset;
}

- (CGFloat)buildFlavorTextCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSString *text = self.pokemon.flavorText;
    if (text.length == 0) return y;

    CGFloat textWidth = cardWidth - (CARD_PADDING * 2);
    UIFont *font = [UIFont italicSystemFontOfSize:BODY_FONT_SIZE];
    CGSize textSize = [text sizeWithFont:font
                       constrainedToSize:CGSizeMake(textWidth, 999)
                           lineBreakMode:NSLineBreakByWordWrapping];

    CGFloat cardHeight = CARD_PADDING + textSize.height + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    UILabel *textLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, CARD_PADDING, textWidth, textSize.height)];
    textLabel.text = text;
    textLabel.font = font;
    textLabel.textColor = [UIColor colorWithWhite:0.30 alpha:1];
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.numberOfLines = 0;
    textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [card addSubview:textLabel];

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildStatsCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSDictionary *stats = self.pokemon.stats;
    if (!stats || stats.count == 0) return y;

    NSArray *statOrder = @[@"hp", @"attack", @"defense",
                           @"special-attack", @"special-defense", @"speed"];
    NSDictionary *statNames = @{
        @"hp": @"HP",
        @"attack": @"Atk",
        @"defense": @"Def",
        @"special-attack": @"Sp.Atk",
        @"special-defense": @"Sp.Def",
        @"speed": @"Speed"
    };

    CGFloat barHeight = 22;
    CGFloat headerHeight = 26;
    CGFloat totalRowHeight = 20;
    CGFloat contentHeight = headerHeight + (barHeight * statOrder.count) + totalRowHeight;
    CGFloat cardHeight = CARD_PADDING + contentHeight + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Base Stats" inCard:card atY:CARD_PADDING];

    CGFloat barWidth = cardWidth - (CARD_PADDING * 2);
    CGFloat barY = CARD_PADDING + headerHeight;
    NSInteger total = 0;

    for (NSString *key in statOrder) {
        NSInteger value = [stats[key] integerValue];
        total += value;

        StatBarView *bar = [[StatBarView alloc] initWithFrame:
            CGRectMake(CARD_PADDING, barY, barWidth, barHeight)];
        [bar configureWithName:statNames[key] value:value];
        [card addSubview:bar];

        barY += barHeight;
    }

    // Total
    UILabel *totalLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, barY + 4, 52, 18)];
    totalLabel.text = @"Total";
    totalLabel.font = [UIFont boldSystemFontOfSize:12];
    totalLabel.textColor = [UIColor colorWithWhite:0.35 alpha:1];
    totalLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:totalLabel];

    UILabel *totalValue = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING + 52, barY + 4, 34, 18)];
    totalValue.text = [NSString stringWithFormat:@"%ld", (long)total];
    totalValue.font = [UIFont boldSystemFontOfSize:12];
    totalValue.textColor = [UIColor darkTextColor];
    totalValue.textAlignment = NSTextAlignmentRight;
    totalValue.backgroundColor = [UIColor clearColor];
    [card addSubview:totalValue];

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildInfoCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSArray *rows = @[
        @[@"Height",    [self.pokemon formattedHeight]],
        @[@"Weight",    [self.pokemon formattedWeight]],
        @[@"Habitat",   [self titleCase:self.pokemon.habitat]],
        @[@"Catch Rate", [NSString stringWithFormat:@"%ld", (long)self.pokemon.captureRate]],
        @[@"Base Exp",  [NSString stringWithFormat:@"%ld", (long)self.pokemon.baseExperience]],
        @[@"Generation",[self formatGeneration:self.pokemon.generation]],
    ];

    CGFloat rowHeight = 24;
    CGFloat headerHeight = 26;
    CGFloat cardHeight = CARD_PADDING + headerHeight + (rowHeight * rows.count) + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Info" inCard:card atY:CARD_PADDING];

    CGFloat rowY = CARD_PADDING + headerHeight;
    CGFloat labelWidth = 100;
    CGFloat valueX = CARD_PADDING + labelWidth;
    CGFloat valueWidth = cardWidth - valueX - CARD_PADDING;

    for (NSArray *row in rows) {
        UILabel *label = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, rowY, labelWidth, rowHeight)];
        label.text = row[0];
        label.font = [UIFont boldSystemFontOfSize:BODY_FONT_SIZE];
        label.textColor = [UIColor colorWithWhite:0.35 alpha:1];
        label.backgroundColor = [UIColor clearColor];
        [card addSubview:label];

        UILabel *value = [[UILabel alloc] initWithFrame:
            CGRectMake(valueX, rowY, valueWidth, rowHeight)];
        value.text = row[1];
        value.font = [UIFont systemFontOfSize:BODY_FONT_SIZE];
        value.textColor = [UIColor darkTextColor];
        value.backgroundColor = [UIColor clearColor];
        [card addSubview:value];

        rowY += rowHeight;
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildAbilitiesCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSArray *abilities = self.pokemon.abilities;
    if (!abilities || abilities.count == 0) return y;

    CGFloat rowHeight = 24;
    CGFloat headerHeight = 26;
    CGFloat cardHeight = CARD_PADDING + headerHeight + (rowHeight * abilities.count) + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Abilities" inCard:card atY:CARD_PADDING];

    CGFloat rowY = CARD_PADDING + headerHeight;
    for (NSDictionary *ability in abilities) {
        NSString *name = ability[@"name"] ?: @"";
        BOOL isHidden = [ability[@"is_hidden"] boolValue];

        NSString *display = isHidden ?
            [NSString stringWithFormat:@"%@ (Hidden)", name] : name;

        UILabel *label = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, rowY, cardWidth - CARD_PADDING * 2, rowHeight)];
        label.text = display;
        label.font = [UIFont systemFontOfSize:BODY_FONT_SIZE];
        label.textColor = isHidden ?
            [UIColor grayColor] : [UIColor darkTextColor];
        label.backgroundColor = [UIColor clearColor];
        [card addSubview:label];

        rowY += rowHeight;
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildBreedingCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSArray *rows = @[
        @[@"Egg Groups", [[self.pokemon.eggGroups componentsJoinedByString:@", "]
                          length] > 0 ?
            [self.pokemon.eggGroups componentsJoinedByString:@", "] : @"None"],
        @[@"Gender",     [self.pokemon genderString]],
        @[@"Hatch Steps", [NSString stringWithFormat:@"~%ld",
            (long)(self.pokemon.hatchCounter * 256)]],
        @[@"Base Happy", [NSString stringWithFormat:@"%ld",
            (long)self.pokemon.baseHappiness]],
    ];

    CGFloat rowHeight = 24;
    CGFloat headerHeight = 26;
    CGFloat cardHeight = CARD_PADDING + headerHeight + (rowHeight * rows.count) + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Breeding" inCard:card atY:CARD_PADDING];

    CGFloat rowY = CARD_PADDING + headerHeight;
    CGFloat labelWidth = 100;
    CGFloat valueX = CARD_PADDING + labelWidth;
    CGFloat valueWidth = cardWidth - valueX - CARD_PADDING;

    for (NSArray *row in rows) {
        UILabel *label = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, rowY, labelWidth, rowHeight)];
        label.text = row[0];
        label.font = [UIFont boldSystemFontOfSize:BODY_FONT_SIZE];
        label.textColor = [UIColor colorWithWhite:0.35 alpha:1];
        label.backgroundColor = [UIColor clearColor];
        [card addSubview:label];

        UILabel *value = [[UILabel alloc] initWithFrame:
            CGRectMake(valueX, rowY, valueWidth, rowHeight)];
        value.text = row[1];
        value.font = [UIFont systemFontOfSize:BODY_FONT_SIZE];
        value.textColor = [UIColor darkTextColor];
        value.backgroundColor = [UIColor clearColor];
        [card addSubview:value];

        rowY += rowHeight;
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildTypeEffectivenessCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSArray *pokemonTypes = self.pokemon.types;
    if (!pokemonTypes || pokemonTypes.count == 0) return y;

    NSArray *allTypes = [[DataManager sharedManager] allTypes];
    if (allTypes.count == 0) return y;

    // Build damage_relations lookup: typeName → relations dict
    NSMutableDictionary *relationsMap = [[NSMutableDictionary alloc] init];
    for (NSDictionary *typeData in allTypes) {
        NSString *name = typeData[@"name"];
        if (name) {
            relationsMap[name] = typeData[@"damage_relations"] ?: @{};
        }
    }

    // For each attacking type, compute defensive multiplier
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

    // Group into categories
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

    // Build category display array
    NSMutableArray *categories = [[NSMutableArray alloc] init];
    if (weak4x.count > 0) [categories addObject:@[@"4\u00D7 Weak", weak4x]];
    if (weak2x.count > 0) [categories addObject:@[@"2\u00D7 Weak", weak2x]];
    if (resist2x.count > 0) [categories addObject:@[@"\u00BD\u00D7 Resist", resist2x]];
    if (resist4x.count > 0) [categories addObject:@[@"\u00BC\u00D7 Resist", resist4x]];
    if (immune.count > 0) [categories addObject:@[@"Immune", immune]];

    if (categories.count == 0) return y;

    // Calculate card height
    CGFloat headerHeight = 26;
    CGFloat categoryLabelHeight = 20;
    CGFloat badgeRowHeight = [TypeBadgeView badgeHeight] + 6;
    CGFloat contentHeight = headerHeight;
    for (NSArray *cat in categories) {
        contentHeight += categoryLabelHeight + badgeRowHeight;
    }
    CGFloat cardHeight = CARD_PADDING + contentHeight + CARD_PADDING;

    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];
    [self sectionHeaderWithTitle:@"Type Effectiveness" inCard:card atY:CARD_PADDING];

    CGFloat innerWidth = cardWidth - CARD_PADDING * 2;
    CGFloat rowY = CARD_PADDING + headerHeight;

    for (NSArray *cat in categories) {
        NSString *label = cat[0];
        NSArray *types = cat[1];

        UILabel *catLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, rowY, innerWidth, categoryLabelHeight)];
        catLabel.text = label;
        catLabel.font = [UIFont boldSystemFontOfSize:11];
        catLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1];
        catLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:catLabel];
        rowY += categoryLabelHeight;

        CGFloat badgeX = CARD_PADDING;
        CGFloat badgeW = [TypeBadgeView badgeWidth];
        CGFloat badgeH = [TypeBadgeView badgeHeight];
        for (NSString *type in types) {
            // Wrap to next line if needed
            if (badgeX + badgeW > cardWidth - CARD_PADDING) {
                badgeX = CARD_PADDING;
                rowY += badgeH + 4;
                // Expand card height
                CGRect frame = card.frame;
                frame.size.height += badgeH + 4;
                card.frame = frame;
                cardHeight += badgeH + 4;
            }
            TypeBadgeView *badge = [[TypeBadgeView alloc] initWithTypeName:type];
            badge.frame = CGRectMake(badgeX, rowY, badgeW, badgeH);
            [card addSubview:badge];
            badgeX += badgeW + 4;
        }
        rowY += badgeRowHeight;
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildHeldItemsCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSArray *items = self.pokemon.heldItems;
    if (!items || items.count == 0) return y;

    CGFloat headerHeight = 26;
    CGFloat rowHeight = 28;
    CGFloat cardHeight = CARD_PADDING + headerHeight + (rowHeight * items.count) + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Wild Held Items" inCard:card atY:CARD_PADDING];

    CGFloat rowY = CARD_PADDING + headerHeight;
    DataManager *dm = [DataManager sharedManager];
    CGFloat innerWidth = cardWidth - CARD_PADDING * 2;

    for (NSDictionary *item in items) {
        NSString *name = item[@"name"] ?: @"";
        NSString *apiName = item[@"api_name"] ?: @"";
        NSInteger rarity = [item[@"rarity"] integerValue];

        // Item sprite
        UIImage *sprite = [dm spriteForItemName:apiName];
        if (sprite) {
            UIImageView *spriteView = [[UIImageView alloc] initWithFrame:
                CGRectMake(CARD_PADDING, rowY + 2, 24, 24)];
            spriteView.contentMode = UIViewContentModeScaleAspectFit;
            spriteView.image = sprite;
            [card addSubview:spriteView];
        }

        // Item name
        CGFloat nameX = CARD_PADDING + (sprite ? 30 : 0);
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(nameX, rowY, innerWidth - 60, rowHeight)];
        nameLabel.text = name;
        nameLabel.font = [UIFont systemFontOfSize:BODY_FONT_SIZE];
        nameLabel.textColor = [UIColor darkTextColor];
        nameLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:nameLabel];

        // Rarity percentage (right-aligned)
        UILabel *rarityLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(cardWidth - CARD_PADDING - 50, rowY, 50, rowHeight)];
        rarityLabel.text = [NSString stringWithFormat:@"%ld%%", (long)rarity];
        rarityLabel.font = [UIFont systemFontOfSize:12];
        rarityLabel.textColor = [UIColor grayColor];
        rarityLabel.textAlignment = NSTextAlignmentRight;
        rarityLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:rarityLabel];

        rowY += rowHeight;
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildEvolutionCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSArray *chain = self.pokemon.evolutionChain;
    if (!chain || chain.count < 2) return y;

    // Build evolution pairs from from_id relationships
    NSMutableArray *pairs = [[NSMutableArray alloc] init];
    // Build lookup: id → entry
    NSMutableDictionary *entryById = [[NSMutableDictionary alloc] init];
    for (NSDictionary *entry in chain) {
        NSNumber *eid = entry[@"id"];
        if (eid) entryById[eid] = entry;
    }

    for (NSDictionary *entry in chain) {
        id fromId = entry[@"from_id"];
        if (!fromId || fromId == [NSNull null]) continue;
        // Null in plist is stored as empty string
        if ([fromId isKindOfClass:[NSString class]] && [fromId length] == 0) continue;
        NSDictionary *fromEntry = entryById[@([fromId integerValue])];
        if (!fromEntry) continue;
        [pairs addObject:@[fromEntry, entry]];
    }

    if (pairs.count == 0) return y;

    CGFloat headerHeight = 26;
    CGFloat pairRowHeight = 40;
    CGFloat cardHeight = CARD_PADDING + headerHeight + (pairRowHeight * pairs.count) + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Evolution" inCard:card atY:CARD_PADDING];

    CGFloat rowY = CARD_PADDING + headerHeight;
    DataManager *dm = [DataManager sharedManager];
    CGFloat innerWidth = cardWidth - CARD_PADDING * 2;

    for (NSArray *pair in pairs) {
        NSDictionary *from = pair[0];
        NSDictionary *to = pair[1];
        NSInteger fromID = [from[@"id"] integerValue];
        NSInteger toID = [to[@"id"] integerValue];
        NSString *fromName = from[@"name"] ?: @"";
        NSString *toName = to[@"name"] ?: @"";
        NSString *condition = [self evolutionConditionText:to];

        CGFloat spriteSize = 32;
        CGFloat nameW = 50;
        CGFloat arrowW = 14;
        CGFloat spriteY = rowY + (pairRowHeight - spriteSize) / 2;

        // Left section: [fromSprite][fromName]
        CGFloat leftX = CARD_PADDING;

        UIImage *fromSprite = [dm spriteForPokemonID:fromID];
        if (fromSprite) {
            UIButton *fromBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            fromBtn.frame = CGRectMake(leftX, spriteY, spriteSize, spriteSize);
            [fromBtn setImage:fromSprite forState:UIControlStateNormal];
            fromBtn.tag = fromID;
            [fromBtn addTarget:self action:@selector(evolutionSpriteTapped:)
                forControlEvents:UIControlEventTouchUpInside];
            fromBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
            [card addSubview:fromBtn];
        }
        leftX += spriteSize + 2;

        UILabel *fromLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(leftX, rowY, nameW, pairRowHeight)];
        fromLabel.text = fromName;
        fromLabel.font = [UIFont systemFontOfSize:10];
        fromLabel.textColor = [UIColor darkTextColor];
        fromLabel.backgroundColor = [UIColor clearColor];
        fromLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [card addSubview:fromLabel];
        leftX += nameW;

        // Right section: [toSprite][toName] (right-aligned)
        CGFloat rightX = cardWidth - CARD_PADDING - nameW;

        UILabel *toLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(rightX, rowY, nameW, pairRowHeight)];
        toLabel.text = toName;
        toLabel.font = [UIFont systemFontOfSize:10];
        toLabel.textColor = [UIColor darkTextColor];
        toLabel.textAlignment = NSTextAlignmentRight;
        toLabel.backgroundColor = [UIColor clearColor];
        toLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [card addSubview:toLabel];
        rightX -= (spriteSize + 2);

        UIImage *toSprite = [dm spriteForPokemonID:toID];
        if (toSprite) {
            UIButton *toBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            toBtn.frame = CGRectMake(rightX, spriteY, spriteSize, spriteSize);
            [toBtn setImage:toSprite forState:UIControlStateNormal];
            toBtn.tag = toID;
            [toBtn addTarget:self action:@selector(evolutionSpriteTapped:)
                forControlEvents:UIControlEventTouchUpInside];
            toBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
            [card addSubview:toBtn];
        }

        // Middle section: [arrow][condition][arrow]
        CGFloat midStart = leftX;
        CGFloat midEnd = rightX;
        CGFloat condWidth = midEnd - midStart - arrowW * 2;

        UILabel *arrow = [[UILabel alloc] initWithFrame:
            CGRectMake(midStart, rowY, arrowW, pairRowHeight)];
        arrow.text = @"\u2192";
        arrow.font = [UIFont systemFontOfSize:12];
        arrow.textColor = [UIColor grayColor];
        arrow.textAlignment = NSTextAlignmentCenter;
        arrow.backgroundColor = [UIColor clearColor];
        [card addSubview:arrow];

        UILabel *condLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(midStart + arrowW, rowY, condWidth, pairRowHeight)];
        condLabel.text = condition;
        condLabel.font = [UIFont systemFontOfSize:10];
        condLabel.textColor = [UIColor grayColor];
        condLabel.textAlignment = NSTextAlignmentCenter;
        condLabel.backgroundColor = [UIColor clearColor];
        condLabel.numberOfLines = 2;
        condLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [card addSubview:condLabel];

        UILabel *arrow2 = [[UILabel alloc] initWithFrame:
            CGRectMake(midEnd - arrowW, rowY, arrowW, pairRowHeight)];
        arrow2.text = @"\u2192";
        arrow2.font = [UIFont systemFontOfSize:12];
        arrow2.textColor = [UIColor grayColor];
        arrow2.textAlignment = NSTextAlignmentCenter;
        arrow2.backgroundColor = [UIColor clearColor];
        [card addSubview:arrow2];

        rowY += pairRowHeight;
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (void)evolutionSpriteTapped:(UIButton *)sender {
    NSInteger pokemonID = sender.tag;
    if (pokemonID <= 0 || pokemonID == self.pokemon.pokemonID) return;

    PokemonDetailVC *detailVC = [[PokemonDetailVC alloc] init];
    detailVC.pokemonID = pokemonID;
    UINavigationController *detailNav = [[UINavigationController alloc]
        initWithRootViewController:detailVC];

    UISplitViewController *splitVC = self.splitViewController;
    if (splitVC) {
        splitVC.viewControllers = @[splitVC.viewControllers[0], detailNav];
    } else {
        [self.navigationController pushViewController:detailVC animated:YES];
    }
}

- (NSString *)evolutionConditionText:(NSDictionary *)entry {
    NSMutableArray *parts = [[NSMutableArray alloc] init];

    NSString *trigger = entry[@"trigger"] ?: @"";

    id minLevel = entry[@"min_level"];
    if (minLevel && minLevel != [NSNull null] && [minLevel integerValue] > 0) {
        [parts addObject:[NSString stringWithFormat:@"Lv. %@", minLevel]];
    } else if ([trigger isEqualToString:@"level-up"] && parts.count == 0) {
        // Will add "Level Up" at end if no other conditions apply
    }

    if (entry[@"item"] && entry[@"item"] != [NSNull null]) {
        [parts addObject:entry[@"item"]];
    }
    if (entry[@"held_item"] && entry[@"held_item"] != [NSNull null]) {
        [parts addObject:[NSString stringWithFormat:@"Hold %@", entry[@"held_item"]]];
    }
    if (entry[@"known_move"] && entry[@"known_move"] != [NSNull null]) {
        [parts addObject:[NSString stringWithFormat:@"Know %@", entry[@"known_move"]]];
    }
    if (entry[@"known_move_type"] && entry[@"known_move_type"] != [NSNull null]) {
        [parts addObject:[NSString stringWithFormat:@"%@ move", entry[@"known_move_type"]]];
    }
    if (entry[@"min_happiness"] && entry[@"min_happiness"] != [NSNull null]) {
        [parts addObject:@"Happiness"];
    }
    if (entry[@"min_beauty"] && entry[@"min_beauty"] != [NSNull null]) {
        [parts addObject:@"Beauty"];
    }
    if (entry[@"min_affection"] && entry[@"min_affection"] != [NSNull null]) {
        [parts addObject:@"Affection"];
    }
    if (entry[@"time_of_day"] && entry[@"time_of_day"] != [NSNull null]) {
        NSString *tod = entry[@"time_of_day"];
        if (tod.length > 0) {
            [parts addObject:[self titleCase:tod]];
        }
    }
    if ([entry[@"needs_overworld_rain"] boolValue]) {
        [parts addObject:@"Rain"];
    }
    if ([entry[@"turn_upside_down"] boolValue]) {
        [parts addObject:@"Upside Down"];
    }
    if (entry[@"trade_species"] && entry[@"trade_species"] != [NSNull null]) {
        [parts addObject:[NSString stringWithFormat:@"Trade w/ %@", entry[@"trade_species"]]];
    }
    id gender = entry[@"gender"];
    if (gender && gender != [NSNull null]) {
        NSInteger g = [gender integerValue];
        if (g == 1) [parts addObject:@"\u2640"];
        else if (g == 2) [parts addObject:@"\u2642"];
    }

    if ([trigger isEqualToString:@"trade"] && parts.count == 0) {
        [parts addObject:@"Trade"];
    }
    if ([trigger isEqualToString:@"use-item"] && parts.count == 0) {
        [parts addObject:@"Use Item"];
    }
    if ([trigger isEqualToString:@"level-up"] && parts.count == 0) {
        [parts addObject:@"Level Up"];
    }

    if (parts.count == 0) {
        return [self titleCase:trigger];
    }
    return [parts componentsJoinedByString:@", "];
}

- (CGFloat)buildMovesCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSArray *allMoves = self.pokemon.moves;
    if (!allMoves || allMoves.count == 0) return y;

    // Group moves by method
    NSMutableArray *levelUp = [[NSMutableArray alloc] init];
    NSMutableArray *machine = [[NSMutableArray alloc] init];
    NSMutableArray *egg = [[NSMutableArray alloc] init];
    NSMutableArray *tutor = [[NSMutableArray alloc] init];
    NSMutableArray *other = [[NSMutableArray alloc] init];

    for (NSDictionary *move in allMoves) {
        NSString *method = move[@"method"] ?: @"";
        if ([method isEqualToString:@"level-up"]) {
            [levelUp addObject:move];
        } else if ([method isEqualToString:@"machine"]) {
            [machine addObject:move];
        } else if ([method isEqualToString:@"egg"]) {
            [egg addObject:move];
        } else if ([method isEqualToString:@"tutor"]) {
            [tutor addObject:move];
        } else {
            [other addObject:move];
        }
    }

    // Build sections array
    NSMutableArray *sections = [[NSMutableArray alloc] init];
    if (levelUp.count > 0) [sections addObject:@[@"Level-Up Moves", levelUp]];
    if (machine.count > 0) [sections addObject:@[@"TM/HM Moves", machine]];
    if (egg.count > 0) [sections addObject:@[@"Egg Moves", egg]];
    if (tutor.count > 0) [sections addObject:@[@"Tutor Moves", tutor]];
    if (other.count > 0) [sections addObject:@[@"Other Moves", other]];

    if (sections.count == 0) return y;

    // Cap rows per section to limit view creation
    NSInteger maxPerSection = 10;
    CGFloat moveRowHeight = 22;
    CGFloat moreRowHeight = 20;
    CGFloat sectionHeaderHeight = 24;
    CGFloat mainHeaderHeight = 26;
    CGFloat colHeaderHeight = 18;

    // Calculate card height with caps
    CGFloat totalHeight = CARD_PADDING + mainHeaderHeight + colHeaderHeight;
    for (NSArray *section in sections) {
        NSArray *moves = section[1];
        NSInteger showing = MIN((NSInteger)moves.count, maxPerSection);
        totalHeight += sectionHeaderHeight + (moveRowHeight * showing);
        if ((NSInteger)moves.count > maxPerSection) {
            totalHeight += moreRowHeight;
        }
    }
    totalHeight += CARD_PADDING;

    UIView *card = [self createCardAtY:y width:cardWidth height:totalHeight];
    [self sectionHeaderWithTitle:@"Moves" inCard:card atY:CARD_PADDING];

    CGFloat innerWidth = cardWidth - CARD_PADDING * 2;
    CGFloat rowY = CARD_PADDING + mainHeaderHeight;

    // Column headers
    CGFloat typeColW = 50;
    CGFloat powColW = 36;
    CGFloat accColW = 36;
    CGFloat ppColW = 30;
    CGFloat statsW = typeColW + powColW + accColW + ppColW;
    CGFloat nameColW = innerWidth - statsW;

    NSArray *colHeaders = @[
        @[@"Move", [NSNumber numberWithFloat:0],
          [NSNumber numberWithFloat:nameColW], [NSNumber numberWithInt:NSTextAlignmentLeft]],
        @[@"Type", [NSNumber numberWithFloat:nameColW],
          [NSNumber numberWithFloat:typeColW], [NSNumber numberWithInt:NSTextAlignmentCenter]],
        @[@"Pow", [NSNumber numberWithFloat:nameColW + typeColW],
          [NSNumber numberWithFloat:powColW], [NSNumber numberWithInt:NSTextAlignmentCenter]],
        @[@"Acc", [NSNumber numberWithFloat:nameColW + typeColW + powColW],
          [NSNumber numberWithFloat:accColW], [NSNumber numberWithInt:NSTextAlignmentCenter]],
        @[@"PP", [NSNumber numberWithFloat:nameColW + typeColW + powColW + accColW],
          [NSNumber numberWithFloat:ppColW], [NSNumber numberWithInt:NSTextAlignmentCenter]],
    ];

    for (NSArray *col in colHeaders) {
        UILabel *colLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING + [col[1] floatValue], rowY,
                       [col[2] floatValue], colHeaderHeight)];
        colLabel.text = col[0];
        colLabel.font = [UIFont boldSystemFontOfSize:9];
        colLabel.textColor = [UIColor grayColor];
        colLabel.textAlignment = [col[3] integerValue];
        colLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:colLabel];
    }
    rowY += colHeaderHeight;

    // Sections
    for (NSArray *section in sections) {
        NSString *sectionTitle = section[0];
        NSArray *moves = section[1];
        NSInteger showing = MIN((NSInteger)moves.count, maxPerSection);

        // Section sub-header
        UILabel *subHeader = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, rowY, innerWidth, sectionHeaderHeight)];
        subHeader.text = sectionTitle;
        subHeader.font = [UIFont boldSystemFontOfSize:11];
        subHeader.textColor = [UIColor colorWithWhite:0.45 alpha:1];
        subHeader.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
        [card addSubview:subHeader];
        rowY += sectionHeaderHeight;

        // Move rows (capped)
        for (NSInteger i = 0; i < showing; i++) {
            NSDictionary *move = moves[i];
            NSString *moveName = move[@"name"] ?: @"";
            NSInteger level = [move[@"level"] integerValue];
            NSString *moveType = move[@"type"] ?: @"";

            // Name (with level for level-up moves)
            NSString *displayName = moveName;
            if (level > 0) {
                displayName = [NSString stringWithFormat:@"Lv.%ld %@",
                               (long)level, moveName];
            }

            UILabel *nameLabel = [[UILabel alloc] initWithFrame:
                CGRectMake(CARD_PADDING, rowY, nameColW, moveRowHeight)];
            nameLabel.text = displayName;
            nameLabel.font = [UIFont systemFontOfSize:11];
            nameLabel.textColor = [UIColor darkTextColor];
            nameLabel.backgroundColor = [UIColor clearColor];
            nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            [card addSubview:nameLabel];

            // Type
            if (moveType.length > 0) {
                UILabel *typeLabel = [[UILabel alloc] initWithFrame:
                    CGRectMake(CARD_PADDING + nameColW, rowY, typeColW, moveRowHeight)];
                NSString *abbrev = [[moveType uppercaseString]
                    substringToIndex:MIN(moveType.length, (NSUInteger)4)];
                typeLabel.text = abbrev;
                typeLabel.font = [UIFont boldSystemFontOfSize:9];
                typeLabel.textColor = [PokemonType colorForTypeName:moveType];
                typeLabel.textAlignment = NSTextAlignmentCenter;
                typeLabel.backgroundColor = [UIColor clearColor];
                [card addSubview:typeLabel];
            }

            // Power
            id power = move[@"power"];
            UILabel *powLabel = [[UILabel alloc] initWithFrame:
                CGRectMake(CARD_PADDING + nameColW + typeColW, rowY,
                           powColW, moveRowHeight)];
            powLabel.text = (power && power != [NSNull null]) ?
                [NSString stringWithFormat:@"%@", power] : @"—";
            powLabel.font = [UIFont systemFontOfSize:11];
            powLabel.textColor = [UIColor darkTextColor];
            powLabel.textAlignment = NSTextAlignmentCenter;
            powLabel.backgroundColor = [UIColor clearColor];
            [card addSubview:powLabel];

            // Accuracy
            id accuracy = move[@"accuracy"];
            UILabel *accLabel = [[UILabel alloc] initWithFrame:
                CGRectMake(CARD_PADDING + nameColW + typeColW + powColW, rowY,
                           accColW, moveRowHeight)];
            accLabel.text = (accuracy && accuracy != [NSNull null]) ?
                [NSString stringWithFormat:@"%@", accuracy] : @"—";
            accLabel.font = [UIFont systemFontOfSize:11];
            accLabel.textColor = [UIColor darkTextColor];
            accLabel.textAlignment = NSTextAlignmentCenter;
            accLabel.backgroundColor = [UIColor clearColor];
            [card addSubview:accLabel];

            // PP
            id pp = move[@"pp"];
            UILabel *ppLabel = [[UILabel alloc] initWithFrame:
                CGRectMake(CARD_PADDING + nameColW + typeColW + powColW + accColW,
                           rowY, ppColW, moveRowHeight)];
            ppLabel.text = pp ? [NSString stringWithFormat:@"%@", pp] : @"—";
            ppLabel.font = [UIFont systemFontOfSize:11];
            ppLabel.textColor = [UIColor darkTextColor];
            ppLabel.textAlignment = NSTextAlignmentCenter;
            ppLabel.backgroundColor = [UIColor clearColor];
            [card addSubview:ppLabel];

            rowY += moveRowHeight;
        }

        // "...and X more" if truncated
        if ((NSInteger)moves.count > maxPerSection) {
            UILabel *moreLabel = [[UILabel alloc] initWithFrame:
                CGRectMake(CARD_PADDING, rowY, innerWidth, moreRowHeight)];
            moreLabel.text = [NSString stringWithFormat:@"...and %ld more",
                              (long)(moves.count - maxPerSection)];
            moreLabel.font = [UIFont italicSystemFontOfSize:11];
            moreLabel.textColor = [UIColor grayColor];
            moreLabel.backgroundColor = [UIColor clearColor];
            [card addSubview:moreLabel];
            rowY += moreRowHeight;
        }
    }

    [self.scrollView addSubview:card];
    return y + totalHeight + CARD_SPACING;
}

#pragma mark - Helpers

- (NSString *)titleCase:(NSString *)str {
    if (!str || str.length == 0) return @"—";
    return [[[str substringToIndex:1] uppercaseString]
        stringByAppendingString:[str substringFromIndex:1]];
}

- (NSString *)formatGeneration:(NSString *)gen {
    if (!gen || gen.length == 0) return @"—";
    // "generation-i" → "Gen I"
    NSString *numeral = [[gen componentsSeparatedByString:@"-"] lastObject];
    return [NSString stringWithFormat:@"Gen %@", [numeral uppercaseString]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:nil
        forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.titleTextAttributes = nil;
}

@end
