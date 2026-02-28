#import "BerryDetailVC.h"
#import "Berry.h"
#import "DataManager.h"
#import "TexturedBackgroundView.h"
#import "TypeBadgeView.h"
#import <QuartzCore/QuartzCore.h>

#define CARD_MARGIN 16
#define CARD_PADDING 14
#define CARD_SPACING 14
#define CARD_CORNER 8
#define SECTION_FONT_SIZE 13
#define BODY_FONT_SIZE 14

@interface BerryDetailVC ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) TexturedBackgroundView *backgroundView;
@property (nonatomic, strong) Berry *berry;
@property (nonatomic, assign) CGFloat lastBuiltWidth;
@end

@implementation BerryDetailVC

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

    if (self.berryID > 0) {
        self.berry = [[DataManager sharedManager] berryDetailWithID:self.berryID];
        self.title = self.berry.name ?: @"Berry";
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
        0.70, 0.25, 0.35, 1.0,   // pink/berry top
        0.85, 0.40, 0.50, 1.0    // lighter pink bottom
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

    if (!self.berry) {
        CGFloat w = self.scrollView.bounds.size.width;
        UILabel *empty = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, w, 40)];
        empty.text = @"Select a Berry";
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
    y = [self buildGrowthStatsCard:y cardWidth:cardWidth];
    y = [self buildFlavorProfileCard:y cardWidth:cardWidth];

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
    BOOL hasSprite = self.berry.hasSprite;
    CGFloat spriteSize = 48;
    CGFloat textX = CARD_PADDING + (hasSprite ? spriteSize + 10 : 0);
    CGFloat nameLineY = CARD_PADDING;
    CGFloat firmnessLineY = CARD_PADDING + 30;
    CGFloat typeLineY = firmnessLineY + 20;

    BOOL hasType = self.berry.naturalGiftType.length > 0;
    CGFloat cardHeight = hasType ? typeLineY + [TypeBadgeView badgeHeight] + CARD_PADDING
                                 : firmnessLineY + 18 + CARD_PADDING;
    if (hasSprite) {
        cardHeight = MAX(cardHeight, CARD_PADDING + spriteSize + CARD_PADDING);
    }

    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    // Berry sprite
    if (hasSprite) {
        UIImageView *spriteView = [[UIImageView alloc] initWithFrame:
            CGRectMake(CARD_PADDING, CARD_PADDING, spriteSize, spriteSize)];
        spriteView.contentMode = UIViewContentModeScaleAspectFit;
        spriteView.image = [[DataManager sharedManager] spriteForBerryID:self.berry.berryID];
        [card addSubview:spriteView];
    }

    // Berry name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(textX, nameLineY, cardWidth - textX - CARD_PADDING, 28)];
    nameLabel.text = self.berry.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:nameLabel];

    // Firmness
    UILabel *firmnessLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(textX, firmnessLineY, 200, 18)];
    firmnessLabel.text = [self.berry firmnessDisplay];
    firmnessLabel.font = [UIFont systemFontOfSize:14];
    firmnessLabel.textColor = [UIColor grayColor];
    firmnessLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:firmnessLabel];

    // Natural gift type badge + power
    if (hasType) {
        TypeBadgeView *badge = [[TypeBadgeView alloc]
            initWithTypeName:self.berry.naturalGiftType];
        CGRect badgeFrame = badge.frame;
        badgeFrame.origin.x = textX;
        badgeFrame.origin.y = typeLineY;
        badge.frame = badgeFrame;
        [card addSubview:badge];

        UILabel *powerLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(textX + [TypeBadgeView badgeWidth] + 8, typeLineY,
                       120, [TypeBadgeView badgeHeight])];
        powerLabel.text = [NSString stringWithFormat:@"Power: %ld",
                           (long)self.berry.naturalGiftPower];
        powerLabel.font = [UIFont systemFontOfSize:13];
        powerLabel.textColor = [UIColor colorWithWhite:0.40 alpha:1];
        powerLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:powerLabel];
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildEffectCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    NSString *effect = self.berry.effect;
    NSString *flavor = self.berry.flavorText;

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

- (CGFloat)buildGrowthStatsCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    CGFloat rowHeight = 24;
    CGFloat headerHeight = 26;
    NSInteger rowCount = 5;
    CGFloat cardHeight = CARD_PADDING + headerHeight + (rowHeight * rowCount) + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Growth Stats" inCard:card atY:CARD_PADDING];

    NSArray *rows = @[
        @[@"Growth Time", [self.berry growthTimeDisplay]],
        @[@"Max Harvest", [NSString stringWithFormat:@"%ld", (long)self.berry.maxHarvest]],
        @[@"Size", [self.berry sizeDisplay]],
        @[@"Smoothness", [NSString stringWithFormat:@"%ld", (long)self.berry.smoothness]],
        @[@"Soil Dryness", [NSString stringWithFormat:@"%ld", (long)self.berry.soilDryness]]
    ];

    CGFloat rowY = CARD_PADDING + headerHeight;
    CGFloat labelWidth = 120;
    CGFloat valueWidth = cardWidth - CARD_PADDING * 2 - labelWidth;

    for (NSArray *row in rows) {
        UILabel *label = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, rowY, labelWidth, rowHeight)];
        label.text = row[0];
        label.font = [UIFont systemFontOfSize:13];
        label.textColor = [UIColor grayColor];
        label.backgroundColor = [UIColor clearColor];
        [card addSubview:label];

        UILabel *value = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING + labelWidth, rowY, valueWidth, rowHeight)];
        value.text = row[1];
        value.font = [UIFont systemFontOfSize:BODY_FONT_SIZE];
        value.textColor = [UIColor darkTextColor];
        value.textAlignment = NSTextAlignmentRight;
        value.backgroundColor = [UIColor clearColor];
        [card addSubview:value];

        rowY += rowHeight;
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildFlavorProfileCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    // Check if any flavor has potency > 0
    NSArray *flavorNames = @[@"spicy", @"dry", @"sweet", @"bitter", @"sour"];
    BOOL hasAnyFlavor = NO;
    for (NSString *name in flavorNames) {
        if ([self.berry.flavors[name] integerValue] > 0) {
            hasAnyFlavor = YES;
            break;
        }
    }
    if (!hasAnyFlavor) return y;

    CGFloat rowHeight = 26;
    CGFloat headerHeight = 26;
    NSInteger rowCount = 5;
    CGFloat cardHeight = CARD_PADDING + headerHeight + (rowHeight * rowCount) + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Flavor Profile" inCard:card atY:CARD_PADDING];

    // Bar colors for each flavor
    NSDictionary *barColors = @{
        @"spicy":  [UIColor colorWithRed:0.90 green:0.25 blue:0.20 alpha:1],
        @"dry":    [UIColor colorWithRed:0.85 green:0.75 blue:0.20 alpha:1],
        @"sweet":  [UIColor colorWithRed:0.90 green:0.50 blue:0.65 alpha:1],
        @"bitter": [UIColor colorWithRed:0.30 green:0.70 blue:0.35 alpha:1],
        @"sour":   [UIColor colorWithRed:0.30 green:0.55 blue:0.85 alpha:1]
    };

    CGFloat nameLabelWidth = 60;
    CGFloat potencyLabelWidth = 30;
    CGFloat maxBarWidth = cardWidth - CARD_PADDING * 2 - nameLabelWidth - potencyLabelWidth;
    CGFloat rowY = CARD_PADDING + headerHeight;

    for (NSString *flavorName in flavorNames) {
        NSInteger potency = [self.berry.flavors[flavorName] integerValue];

        // Flavor name label
        NSString *displayName = [[[flavorName substringToIndex:1] uppercaseString]
            stringByAppendingString:[flavorName substringFromIndex:1]];
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, rowY, nameLabelWidth, rowHeight)];
        nameLabel.text = displayName;
        nameLabel.font = [UIFont systemFontOfSize:12];
        nameLabel.textColor = [UIColor darkTextColor];
        nameLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:nameLabel];

        // Colored bar
        CGFloat barWidth = maxBarWidth * (potency / 40.0);
        if (barWidth < 0) barWidth = 0;
        UIView *bar = [[UIView alloc] initWithFrame:
            CGRectMake(CARD_PADDING + nameLabelWidth, rowY + 6, barWidth, 14)];
        bar.backgroundColor = barColors[flavorName];
        bar.layer.cornerRadius = 3;
        [card addSubview:bar];

        // Potency number
        UILabel *potencyLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING + nameLabelWidth + maxBarWidth, rowY, potencyLabelWidth, rowHeight)];
        potencyLabel.text = [NSString stringWithFormat:@"%ld", (long)potency];
        potencyLabel.font = [UIFont systemFontOfSize:12];
        potencyLabel.textColor = [UIColor grayColor];
        potencyLabel.textAlignment = NSTextAlignmentRight;
        potencyLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:potencyLabel];

        rowY += rowHeight;
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
