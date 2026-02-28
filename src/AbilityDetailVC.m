#import "AbilityDetailVC.h"
#import "Ability.h"
#import "DataManager.h"
#import "TexturedBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

#define CARD_MARGIN 16
#define CARD_PADDING 14
#define CARD_SPACING 14
#define CARD_CORNER 8
#define SECTION_FONT_SIZE 13
#define BODY_FONT_SIZE 14

@interface AbilityDetailVC ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) TexturedBackgroundView *backgroundView;
@property (nonatomic, strong) Ability *ability;
@property (nonatomic, assign) CGFloat lastBuiltWidth;
@end

@implementation AbilityDetailVC

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

    if (self.abilityID > 0) {
        self.ability = [[DataManager sharedManager] abilityDetailWithID:self.abilityID];
        self.title = self.ability.name ?: @"Ability";
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
        0.15, 0.40, 0.20, 1.0,
        0.25, 0.55, 0.30, 1.0
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

    if (!self.ability) {
        CGFloat w = self.scrollView.bounds.size.width;
        UILabel *empty = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, w, 40)];
        empty.text = @"Select an Ability";
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

    y = [self buildHeaderCard:y cardWidth:cardWidth];
    y = [self buildEffectCard:y cardWidth:cardWidth];
    y = [self buildPokemonCard:y cardWidth:cardWidth];

    y += CARD_SPACING;
    self.scrollView.contentSize = CGSizeMake(contentWidth, y);
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
    CGFloat cardHeight = 70;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    // Ability name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, CARD_PADDING, cardWidth - CARD_PADDING * 2, 28)];
    nameLabel.text = self.ability.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:nameLabel];

    // Generation
    UILabel *genLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, CARD_PADDING + 34, 200, 20)];
    genLabel.text = [self.ability generationDisplay];
    genLabel.font = [UIFont systemFontOfSize:14];
    genLabel.textColor = [UIColor grayColor];
    genLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:genLabel];

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildEffectCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSString *effect = self.ability.effect;
    NSString *flavor = self.ability.flavorText;

    // Show effect first, then flavor below if both exist
    NSMutableString *text = [[NSMutableString alloc] init];
    if (effect.length > 0) {
        [text appendString:effect];
    }
    if (flavor.length > 0 && ![flavor isEqualToString:effect]) {
        if (text.length > 0) [text appendString:@"\n\n"];
        [text appendString:flavor];
    }
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

- (CGFloat)buildPokemonCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSArray *pokemon = self.ability.pokemon;
    if (!pokemon || pokemon.count == 0) return y;

    NSInteger maxShow = 30;
    NSInteger total = pokemon.count;
    NSInteger showing = MIN(total, maxShow);

    CGFloat rowHeight = 28;
    CGFloat headerHeight = 26;
    CGFloat countHeight = 20;
    CGFloat cardHeight = CARD_PADDING + headerHeight + countHeight +
                         (rowHeight * showing) + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Pokémon" inCard:card atY:CARD_PADDING];

    // Count
    UILabel *countLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, CARD_PADDING + headerHeight,
                   cardWidth - CARD_PADDING * 2, countHeight)];
    countLabel.text = [NSString stringWithFormat:@"%ld Pokémon with this ability",
                       (long)total];
    countLabel.font = [UIFont systemFontOfSize:12];
    countLabel.textColor = [UIColor grayColor];
    countLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:countLabel];

    CGFloat rowY = CARD_PADDING + headerHeight + countHeight;
    DataManager *dm = [DataManager sharedManager];

    for (NSInteger i = 0; i < showing; i++) {
        NSDictionary *p = pokemon[i];
        NSInteger pokemonID = [p[@"id"] integerValue];
        NSString *name = p[@"name"] ?: @"???";
        BOOL isHidden = [p[@"is_hidden"] boolValue];

        // Sprite
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
        CGFloat nameX = CARD_PADDING + 82;
        CGFloat nameW = cardWidth - nameX - CARD_PADDING;
        if (isHidden) nameW -= 60;

        UILabel *nameLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(nameX, rowY, nameW, rowHeight)];
        nameLabel.text = name;
        nameLabel.font = [UIFont systemFontOfSize:BODY_FONT_SIZE];
        nameLabel.textColor = [UIColor darkTextColor];
        nameLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:nameLabel];

        // Hidden badge
        if (isHidden) {
            UILabel *hiddenLabel = [[UILabel alloc] initWithFrame:
                CGRectMake(cardWidth - CARD_PADDING - 55, rowY + 4, 50, 20)];
            hiddenLabel.text = @"Hidden";
            hiddenLabel.font = [UIFont boldSystemFontOfSize:10];
            hiddenLabel.textColor = [UIColor whiteColor];
            hiddenLabel.textAlignment = NSTextAlignmentCenter;
            hiddenLabel.backgroundColor = [UIColor colorWithRed:0.6 green:0.4 blue:0.8 alpha:1];
            hiddenLabel.layer.cornerRadius = 4;
            hiddenLabel.clipsToBounds = YES;
            [card addSubview:hiddenLabel];
        }

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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:nil
        forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.titleTextAttributes = nil;
}

@end
