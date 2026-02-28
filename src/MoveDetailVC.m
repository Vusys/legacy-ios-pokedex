#import "MoveDetailVC.h"
#import "Move.h"
#import "DataManager.h"
#import "PokemonType.h"
#import "TypeBadgeView.h"
#import "TexturedBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

#define CARD_MARGIN 16
#define CARD_PADDING 14
#define CARD_SPACING 14
#define CARD_CORNER 8
#define SECTION_FONT_SIZE 13
#define BODY_FONT_SIZE 14

@interface MoveDetailVC ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) TexturedBackgroundView *backgroundView;
@property (nonatomic, strong) Move *move;
@property (nonatomic, assign) CGFloat lastBuiltWidth;
@end

@implementation MoveDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lastBuiltWidth = 0;

    self.backgroundView = [[TexturedBackgroundView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.backgroundView];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleHeight;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    [self styleNavBar];

    if (self.moveID > 0) {
        CFAbsoluteTime loadStart = CFAbsoluteTimeGetCurrent();
        self.move = [[DataManager sharedManager] moveDetailWithID:self.moveID];
        NSLog(@"[PERF] MoveDetailVC loadData: %.1fms (id=%ld, name=%@)",
              (CFAbsoluteTimeGetCurrent() - loadStart) * 1000,
              (long)self.moveID, self.move.name ?: @"nil");
        self.title = self.move.name ?: @"Move";
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    if (w > 0 && w != self.lastBuiltWidth) {
        CGFloat oldWidth = self.lastBuiltWidth;
        self.lastBuiltWidth = w;
        NSLog(@"[PERF] MoveDetailVC viewDidLayoutSubviews: width %.0f -> %.0f (move=%@)",
              oldWidth, w, self.move.name ?: @"nil");
        [self rebuildLayout];
    }
}

- (void)styleNavBar {
    CGSize navSize = CGSizeMake(1, 44);
    UIGraphicsBeginImageContextWithOptions(navSize, YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] = {
        0.15, 0.25, 0.50, 1.0,
        0.25, 0.40, 0.65, 1.0
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

#pragma mark - Layout

- (void)rebuildLayout {
    for (UIView *sub in [self.scrollView.subviews copy]) {
        [sub removeFromSuperview];
    }

    if (!self.move) {
        CGFloat w = self.scrollView.bounds.size.width;
        UILabel *empty = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, w, 40)];
        empty.text = @"Select a Move";
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

    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildHeaderCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   header: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildEffectCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   effect: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildStatsCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   stats: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildMetaCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   meta: %.1fms", (CFAbsoluteTimeGetCurrent() - cardStart) * 1000);

    cardStart = CFAbsoluteTimeGetCurrent();
    y = [self buildLearnedByCard:y cardWidth:cardWidth];
    NSLog(@"[PERF]   learnedBy: %.1fms (%lu pokemon)",
          (CFAbsoluteTimeGetCurrent() - cardStart) * 1000,
          (unsigned long)self.move.learnedBy.count);

    y += CARD_SPACING;
    self.scrollView.contentSize = CGSizeMake(contentWidth, y);

    NSLog(@"[PERF] MoveDetailVC rebuildLayout TOTAL: %.1fms (move=%@, width=%.0f)",
          (CFAbsoluteTimeGetCurrent() - totalStart) * 1000,
          self.move.name ?: @"nil", contentWidth);
}

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

    UIView *sep = [[UIView alloc] initWithFrame:
        CGRectMake(CARD_PADDING, y + 20, w, 0.5)];
    sep.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
    [card addSubview:sep];

    return header;
}

#pragma mark - Card Builders

- (CGFloat)buildHeaderCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    CGFloat cardHeight = 90;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    // Move name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, CARD_PADDING, cardWidth - CARD_PADDING * 2, 28)];
    nameLabel.text = self.move.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:nameLabel];

    // Type badge
    TypeBadgeView *badge = [[TypeBadgeView alloc] initWithTypeName:self.move.type];
    badge.frame = CGRectMake(CARD_PADDING, CARD_PADDING + 36,
                             [TypeBadgeView badgeWidth], [TypeBadgeView badgeHeight]);
    [card addSubview:badge];

    // Damage class label
    UILabel *classLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING + [TypeBadgeView badgeWidth] + 10, CARD_PADDING + 36,
                   120, [TypeBadgeView badgeHeight])];
    classLabel.text = [self.move damageClassDisplay];
    classLabel.font = [UIFont systemFontOfSize:14];
    classLabel.textColor = [UIColor grayColor];
    classLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:classLabel];

    // Generation
    NSString *gen = [self formatGeneration:self.move.generation];
    UILabel *genLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(cardWidth - CARD_PADDING - 80, CARD_PADDING + 36, 80, 20)];
    genLabel.text = gen;
    genLabel.font = [UIFont systemFontOfSize:12];
    genLabel.textColor = [UIColor grayColor];
    genLabel.textAlignment = NSTextAlignmentRight;
    genLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:genLabel];

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildEffectCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSString *effect = self.move.effect;
    NSString *flavor = self.move.flavorText;
    NSString *text = (effect.length > 0) ? effect : flavor;
    if (text.length == 0) return y;

    CGFloat textWidth = cardWidth - (CARD_PADDING * 2);
    UIFont *font = [UIFont systemFontOfSize:BODY_FONT_SIZE];
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
    NSArray *rows = @[
        @[@"Power",    [self.move powerString]],
        @[@"Accuracy", [self.move accuracyString]],
        @[@"PP",       [self.move ppString]],
        @[@"Priority", [NSString stringWithFormat:@"%ld", (long)self.move.priority]],
        @[@"Target",   [self titleCase:[self.move.target stringByReplacingOccurrencesOfString:@"-" withString:@" "]]],
    ];

    CGFloat rowHeight = 24;
    CGFloat headerHeight = 26;
    CGFloat cardHeight = CARD_PADDING + headerHeight + (rowHeight * rows.count) + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Stats" inCard:card atY:CARD_PADDING];

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

- (CGFloat)buildMetaCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSDictionary *meta = self.move.meta;
    NSArray *statChanges = self.move.statChanges;
    if ((!meta || meta.count == 0) && (!statChanges || statChanges.count == 0)) return y;

    NSMutableArray *rows = [[NSMutableArray alloc] init];

    // Meta fields
    if (meta[@"ailment"]) {
        NSString *ailment = meta[@"ailment"];
        NSInteger chance = [meta[@"ailment_chance"] integerValue];
        if (chance > 0 && chance < 100) {
            [rows addObject:@[@"Ailment", [NSString stringWithFormat:@"%@ (%ld%%)",
                               ailment, (long)chance]]];
        } else {
            [rows addObject:@[@"Ailment", ailment]];
        }
    }
    if (meta[@"drain"]) {
        [rows addObject:@[@"Drain", [NSString stringWithFormat:@"%ld%%",
                           (long)[meta[@"drain"] integerValue]]]];
    }
    if (meta[@"healing"]) {
        [rows addObject:@[@"Healing", [NSString stringWithFormat:@"%ld%%",
                           (long)[meta[@"healing"] integerValue]]]];
    }
    if (meta[@"crit_rate"]) {
        [rows addObject:@[@"Crit Rate", [NSString stringWithFormat:@"+%ld",
                           (long)[meta[@"crit_rate"] integerValue]]]];
    }
    if (meta[@"flinch_chance"]) {
        [rows addObject:@[@"Flinch", [NSString stringWithFormat:@"%ld%%",
                           (long)[meta[@"flinch_chance"] integerValue]]]];
    }
    if (meta[@"min_hits"] && meta[@"max_hits"]) {
        [rows addObject:@[@"Hits", [NSString stringWithFormat:@"%ld–%ld",
                           (long)[meta[@"min_hits"] integerValue],
                           (long)[meta[@"max_hits"] integerValue]]]];
    }

    // Stat changes
    for (NSDictionary *sc in statChanges) {
        NSString *stat = sc[@"stat"] ?: @"";
        NSInteger change = [sc[@"change"] integerValue];
        NSString *changeStr = change > 0 ?
            [NSString stringWithFormat:@"+%ld", (long)change] :
            [NSString stringWithFormat:@"%ld", (long)change];
        [rows addObject:@[[self titleCase:[stat stringByReplacingOccurrencesOfString:@"-" withString:@" "]],
                          changeStr]];
    }

    if (rows.count == 0) return y;

    CGFloat rowHeight = 24;
    CGFloat headerHeight = 26;
    CGFloat cardHeight = CARD_PADDING + headerHeight + (rowHeight * rows.count) + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Battle Effects" inCard:card atY:CARD_PADDING];

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

- (CGFloat)buildLearnedByCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSArray *learnedBy = self.move.learnedBy;
    if (!learnedBy || learnedBy.count == 0) return y;

    // Show up to 30 Pokemon, with a count header
    NSInteger maxShow = 30;
    NSInteger total = learnedBy.count;
    NSInteger showing = MIN(total, maxShow);

    CGFloat rowHeight = 28;
    CGFloat headerHeight = 26;
    CGFloat countHeight = 20;
    CGFloat cardHeight = CARD_PADDING + headerHeight + countHeight +
                         (rowHeight * showing) + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Learned By" inCard:card atY:CARD_PADDING];

    // Count
    UILabel *countLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, CARD_PADDING + headerHeight,
                   cardWidth - CARD_PADDING * 2, countHeight)];
    countLabel.text = [NSString stringWithFormat:@"%ld Pokémon can learn this move",
                       (long)total];
    countLabel.font = [UIFont systemFontOfSize:12];
    countLabel.textColor = [UIColor grayColor];
    countLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:countLabel];

    CGFloat rowY = CARD_PADDING + headerHeight + countHeight;
    DataManager *dm = [DataManager sharedManager];

    for (NSInteger i = 0; i < showing; i++) {
        NSInteger pokemonID = [learnedBy[i] integerValue];
        NSString *name = [dm pokemonNameForID:pokemonID];

        // Sprite (from shared cache)
        UIImageView *sprite = [[UIImageView alloc] initWithFrame:
            CGRectMake(CARD_PADDING, rowY + 2, 24, 24)];
        sprite.contentMode = UIViewContentModeScaleAspectFit;
        sprite.image = [dm spriteForPokemonID:pokemonID];
        [card addSubview:sprite];

        // Number
        UILabel *numLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING + 30, rowY, 50, rowHeight)];
        numLabel.text = [NSString stringWithFormat:@"#%03ld", (long)pokemonID];
        numLabel.font = [UIFont fontWithName:@"Courier-Bold" size:12];
        if (!numLabel.font) numLabel.font = [UIFont boldSystemFontOfSize:12];
        numLabel.textColor = [UIColor grayColor];
        numLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:numLabel];

        // Name
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING + 82, rowY, cardWidth - CARD_PADDING * 2 - 82, rowHeight)];
        nameLabel.text = name;
        nameLabel.font = [UIFont systemFontOfSize:BODY_FONT_SIZE];
        nameLabel.textColor = [UIColor darkTextColor];
        nameLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:nameLabel];

        rowY += rowHeight;
    }

    if (total > maxShow) {
        UILabel *moreLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, rowY, cardWidth - CARD_PADDING * 2, 20)];
        moreLabel.text = [NSString stringWithFormat:@"...and %ld more",
                          (long)(total - maxShow)];
        moreLabel.font = [UIFont italicSystemFontOfSize:12];
        moreLabel.textColor = [UIColor grayColor];
        moreLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:moreLabel];

        CGRect frame = card.frame;
        frame.size.height += 24;
        card.frame = frame;
        y += 24;
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
    if (!gen || gen.length == 0) return @"";
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
