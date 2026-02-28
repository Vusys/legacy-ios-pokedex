#import "EggGroupDetailVC.h"
#import "EggGroup.h"
#import "DataManager.h"
#import "TexturedBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

#define CARD_MARGIN 16
#define CARD_PADDING 14
#define CARD_SPACING 14
#define CARD_CORNER 8
#define SECTION_FONT_SIZE 13
#define BODY_FONT_SIZE 14

@interface EggGroupDetailVC ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) TexturedBackgroundView *backgroundView;
@property (nonatomic, strong) EggGroup *eggGroup;
@property (nonatomic, assign) CGFloat lastBuiltWidth;
@end

@implementation EggGroupDetailVC

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

    if (self.eggGroupID > 0) {
        self.eggGroup = [[DataManager sharedManager] eggGroupDetailWithID:self.eggGroupID];
        self.title = self.eggGroup.name ?: @"Egg Group";
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
        0.15, 0.45, 0.50, 1.0,   // teal top
        0.25, 0.60, 0.65, 1.0    // lighter teal bottom
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

    if (!self.eggGroup) {
        CGFloat w = self.scrollView.bounds.size.width;
        UILabel *empty = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, w, 40)];
        empty.text = @"Select an Egg Group";
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

    // Egg group name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, CARD_PADDING, cardWidth - CARD_PADDING * 2, 28)];
    nameLabel.text = self.eggGroup.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:nameLabel];

    // Pokemon count subtitle
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, CARD_PADDING + 34, 200, 20)];
    subtitleLabel.text = [NSString stringWithFormat:@"%ld Pok\u00e9mon",
                          (long)self.eggGroup.pokemon.count];
    subtitleLabel.font = [UIFont systemFontOfSize:14];
    subtitleLabel.textColor = [UIColor grayColor];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:subtitleLabel];

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildPokemonCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSArray *pokemon = self.eggGroup.pokemon;
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

    [self sectionHeaderWithTitle:@"Pok\u00e9mon" inCard:card atY:CARD_PADDING];

    // Count
    UILabel *countLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, CARD_PADDING + headerHeight,
                   cardWidth - CARD_PADDING * 2, countHeight)];
    countLabel.text = [NSString stringWithFormat:@"%ld Pok\u00e9mon in this egg group",
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

        UILabel *nameLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(nameX, rowY, nameW, rowHeight)];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:nil
        forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.titleTextAttributes = nil;
}

@end
