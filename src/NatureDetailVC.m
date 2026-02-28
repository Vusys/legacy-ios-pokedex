#import "NatureDetailVC.h"
#import "Nature.h"
#import "DataManager.h"
#import "TexturedBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

#define CARD_MARGIN 16
#define CARD_PADDING 14
#define CARD_SPACING 14
#define CARD_CORNER 8
#define SECTION_FONT_SIZE 13
#define BODY_FONT_SIZE 14

@interface NatureDetailVC ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) TexturedBackgroundView *backgroundView;
@property (nonatomic, strong) Nature *nature;
@property (nonatomic, assign) CGFloat lastBuiltWidth;
@end

@implementation NatureDetailVC

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

    if (self.natureID > 0) {
        [self loadNature];
        self.title = self.nature.name ?: @"Nature";
    }
}

- (void)loadNature {
    NSArray *summaries = [[DataManager sharedManager] allNatureSummaries];
    for (NSDictionary *dict in summaries) {
        if ([dict[@"id"] integerValue] == self.natureID) {
            self.nature = [Nature natureFromDictionary:dict];
            break;
        }
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
        0.45, 0.25, 0.55, 1.0,   // purple top
        0.60, 0.35, 0.70, 1.0    // lighter purple bottom
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

    if (!self.nature) {
        CGFloat w = self.scrollView.bounds.size.width;
        UILabel *empty = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, w, 40)];
        empty.text = @"Select a Nature";
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
    y = [self buildStatEffectsCard:y cardWidth:cardWidth];
    y = [self buildFlavorCard:y cardWidth:cardWidth];

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

    // Nature name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(CARD_PADDING, CARD_PADDING, cardWidth - CARD_PADDING * 2, 28)];
    nameLabel.text = self.nature.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    [card addSubview:nameLabel];

    // Subtitle for neutral natures
    if (self.nature.isNeutral) {
        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, CARD_PADDING + 34, 200, 20)];
        subtitleLabel.text = @"Neutral Nature";
        subtitleLabel.font = [UIFont systemFontOfSize:14];
        subtitleLabel.textColor = [UIColor grayColor];
        subtitleLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:subtitleLabel];
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildStatEffectsCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    CGFloat headerHeight = 26;
    CGFloat contentHeight;

    if (self.nature.isNeutral) {
        contentHeight = 24;
    } else {
        contentHeight = 52; // two rows at 26px each
    }

    CGFloat cardHeight = CARD_PADDING + headerHeight + contentHeight + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Stat Effects" inCard:card atY:CARD_PADDING];

    CGFloat contentY = CARD_PADDING + headerHeight;

    if (self.nature.isNeutral) {
        UILabel *neutralLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, contentY, cardWidth - CARD_PADDING * 2, 24)];
        neutralLabel.text = @"This nature has no stat effect.";
        neutralLabel.font = [UIFont italicSystemFontOfSize:14];
        neutralLabel.textColor = [UIColor grayColor];
        neutralLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:neutralLabel];
    } else {
        UILabel *upLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, contentY, cardWidth - CARD_PADDING * 2, 26)];
        upLabel.text = [NSString stringWithFormat:@"+10%% %@",
                        [self.nature increasedStatDisplay]];
        upLabel.font = [UIFont boldSystemFontOfSize:16];
        upLabel.textColor = [UIColor colorWithRed:0.2 green:0.65 blue:0.2 alpha:1];
        upLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:upLabel];

        UILabel *downLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, contentY + 26, cardWidth - CARD_PADDING * 2, 26)];
        downLabel.text = [NSString stringWithFormat:@"\u221210%% %@",
                          [self.nature decreasedStatDisplay]];
        downLabel.font = [UIFont boldSystemFontOfSize:16];
        downLabel.textColor = [UIColor colorWithRed:0.85 green:0.2 blue:0.2 alpha:1];
        downLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:downLabel];
    }

    [self.scrollView addSubview:card];
    return y + cardHeight + CARD_SPACING;
}

- (CGFloat)buildFlavorCard:(CGFloat)y cardWidth:(CGFloat)cardWidth {
    CGFloat headerHeight = 26;
    CGFloat contentHeight;

    if (self.nature.isNeutral) {
        contentHeight = 24;
    } else {
        contentHeight = 48; // two rows at 24px each
    }

    CGFloat cardHeight = CARD_PADDING + headerHeight + contentHeight + CARD_PADDING;
    UIView *card = [self createCardAtY:y width:cardWidth height:cardHeight];

    [self sectionHeaderWithTitle:@"Flavor Preference" inCard:card atY:CARD_PADDING];

    CGFloat contentY = CARD_PADDING + headerHeight;

    if (self.nature.isNeutral) {
        UILabel *neutralLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, contentY, cardWidth - CARD_PADDING * 2, 24)];
        neutralLabel.text = @"This nature has no flavor preference.";
        neutralLabel.font = [UIFont italicSystemFontOfSize:14];
        neutralLabel.textColor = [UIColor grayColor];
        neutralLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:neutralLabel];
    } else {
        UILabel *likesLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, contentY, cardWidth - CARD_PADDING * 2, 24)];
        likesLabel.text = [NSString stringWithFormat:@"Likes: %@",
                           [self.nature likesFlavorDisplay]];
        likesLabel.font = [UIFont systemFontOfSize:BODY_FONT_SIZE];
        likesLabel.textColor = [UIColor darkTextColor];
        likesLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:likesLabel];

        UILabel *dislikesLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(CARD_PADDING, contentY + 24, cardWidth - CARD_PADDING * 2, 24)];
        dislikesLabel.text = [NSString stringWithFormat:@"Dislikes: %@",
                              [self.nature hatesFlavorDisplay]];
        dislikesLabel.font = [UIFont systemFontOfSize:BODY_FONT_SIZE];
        dislikesLabel.textColor = [UIColor darkTextColor];
        dislikesLabel.backgroundColor = [UIColor clearColor];
        [card addSubview:dislikesLabel];
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
