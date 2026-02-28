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
        self.pokemon = [[DataManager sharedManager] pokemonDetailWithID:self.pokemonID];
        self.title = self.pokemon.name ?: @"Pokédex";
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    if (w > 0 && w != self.lastBuiltWidth) {
        self.lastBuiltWidth = w;
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

    // ─── Header Card ────────────────────────────────────────
    y = [self buildHeaderCard:y cardWidth:cardWidth];

    // ─── Flavor Text Card ───────────────────────────────────
    y = [self buildFlavorTextCard:y cardWidth:cardWidth];

    // ─── Base Stats Card ────────────────────────────────────
    y = [self buildStatsCard:y cardWidth:cardWidth];

    // ─── Info Card ──────────────────────────────────────────
    y = [self buildInfoCard:y cardWidth:cardWidth];

    // ─── Abilities Card ─────────────────────────────────────
    y = [self buildAbilitiesCard:y cardWidth:cardWidth];

    // ─── Breeding Card ──────────────────────────────────────
    y = [self buildBreedingCard:y cardWidth:cardWidth];

    y += CARD_SPACING;
    self.scrollView.contentSize = CGSizeMake(contentWidth, y);
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
    CGFloat spriteSize = 96;
    CGFloat cardHeight = MAX(spriteSize + CARD_PADDING * 2, 130);
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    // Sprite
    UIImageView *sprite = [[UIImageView alloc] initWithFrame:
        CGRectMake(CARD_PADDING, CARD_PADDING, spriteSize, spriteSize)];
    sprite.contentMode = UIViewContentModeScaleAspectFit;
    sprite.image = [self.pokemon spriteImage];
    sprite.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    sprite.layer.cornerRadius = 6;
    sprite.layer.borderWidth = 0.5;
    sprite.layer.borderColor = [[UIColor colorWithWhite:0.88 alpha:1] CGColor];
    [card addSubview:sprite];

    CGFloat textX = CARD_PADDING + spriteSize + 14;
    CGFloat textW = cardWidth - textX - CARD_PADDING;

    // Number
    UILabel *numberLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(textX, CARD_PADDING, textW, 18)];
    numberLabel.text = [self.pokemon formattedID];
    numberLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
    if (!numberLabel.font) numberLabel.font = [UIFont boldSystemFontOfSize:14];
    numberLabel.textColor = [UIColor grayColor];
    numberLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:numberLabel];

    // Name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(textX, CARD_PADDING + 20, textW, 26)];
    nameLabel.text = self.pokemon.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:22];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:nameLabel];

    // Genus
    UILabel *genusLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(textX, CARD_PADDING + 48, textW, 18)];
    genusLabel.text = self.pokemon.genus;
    genusLabel.font = [UIFont italicSystemFontOfSize:13];
    genusLabel.textColor = [UIColor grayColor];
    genusLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:genusLabel];

    // Type badges
    CGFloat badgeX = textX;
    CGFloat badgeY = CARD_PADDING + 70;
    for (NSString *type in self.pokemon.types) {
        TypeBadgeView *badge = [[TypeBadgeView alloc] initWithTypeName:type];
        badge.frame = CGRectMake(badgeX, badgeY,
                                 [TypeBadgeView badgeWidth], [TypeBadgeView badgeHeight]);
        [card addSubview:badge];
        badgeX += [TypeBadgeView badgeWidth] + 6;
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
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
