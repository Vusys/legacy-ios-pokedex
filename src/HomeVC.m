#import "HomeVC.h"
#import "AboutVC.h"
#import "FavouritesVC.h"
#import "DataManager.h"
#import "TexturedBackgroundView.h"
#import "NavBarStyle.h"
#import <QuartzCore/QuartzCore.h>

#define HOME_CARD_HEIGHT  120.0f
#define HOME_PADDING       16.0f
#define HOME_SPACING       12.0f
#define HOME_CORNER_RADIUS  8.0f

@interface HomeVC ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) CGFloat lastBuiltWidth;
@end

@implementation HomeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Pok\u00e9dex";
    self.lastBuiltWidth = 0;

    // Textured background
    TexturedBackgroundView *bg = [[TexturedBackgroundView alloc]
        initWithFrame:self.view.bounds];
    bg.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                          UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:bg];

    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleHeight;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    // Info button → About
    UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoBtn addTarget:self action:@selector(showAbout)
      forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithCustomView:infoBtn];

    [self styleNavBar];

    [[NSNotificationCenter defaultCenter]
        addObserver:self selector:@selector(favouritesDidChange:)
               name:FavouritesChangedNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)favouritesDidChange:(NSNotification *)note {
    self.lastBuiltWidth = 0; // Force rebuild
    [self rebuildGrid];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self styleNavBar];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:nil
        forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.titleTextAttributes = nil;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    if (w > 0 && w != self.lastBuiltWidth) {
        self.lastBuiltWidth = w;
        [self rebuildGrid];
    }
}

#pragma mark - Nav Bar

- (void)styleNavBar {
    [self.navigationController.navigationBar
        setBackgroundImage:NavBarGradientImage(0.25, 0.25, 0.30, 0.40, 0.40, 0.45)
             forBarMetrics:UIBarMetricsDefault];

    self.navigationController.navigationBar.titleTextAttributes = @{
        UITextAttributeTextColor: [UIColor whiteColor],
        UITextAttributeTextShadowColor: [UIColor colorWithWhite:0 alpha:0.6],
        UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
        UITextAttributeFont: [UIFont boldSystemFontOfSize:20]
    };
}

#pragma mark - About

- (void)showAbout {
    AboutVC *about = [[AboutVC alloc] init];
    [self.navigationController pushViewController:about animated:YES];
}

#pragma mark - Grid Layout

- (void)rebuildGrid {
    // Remove old cards
    for (UIView *sub in [self.scrollView.subviews copy]) {
        [sub removeFromSuperview];
    }

    CGFloat viewW = self.view.bounds.size.width;
    NSInteger cols = (viewW >= 600) ? 3 : 2;
    CGFloat cardW = (viewW - 2 * HOME_PADDING - (cols - 1) * HOME_SPACING) / cols;

    // Section data: name, tab index (1-based since Home is 0), count
    NSArray *sectionData = [self sectionData];

    CGFloat y = HOME_PADDING;
    for (NSUInteger i = 0; i < sectionData.count; i++) {
        NSDictionary *info = sectionData[i];
        NSInteger col = (NSInteger)(i % (NSUInteger)cols);
        CGFloat x = HOME_PADDING + col * (cardW + HOME_SPACING);

        UIView *card = [self cardViewWithFrame:CGRectMake(x, y, cardW, HOME_CARD_HEIGHT)
                                          info:info
                                         index:i];
        [self.scrollView addSubview:card];

        // Move to next row after filling columns
        if (col == cols - 1) {
            y += HOME_CARD_HEIGHT + HOME_SPACING;
        }
    }

    // Handle last partial row
    NSInteger lastCol = (NSInteger)((sectionData.count - 1) % (NSUInteger)cols);
    if (lastCol != cols - 1) {
        y += HOME_CARD_HEIGHT + HOME_SPACING;
    }

    self.scrollView.contentSize = CGSizeMake(viewW, y + HOME_PADDING);
}

- (UIView *)cardViewWithFrame:(CGRect)frame info:(NSDictionary *)info index:(NSUInteger)idx {
    UIButton *card = [[UIButton alloc] initWithFrame:frame];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = HOME_CORNER_RADIUS;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.15f;
    card.layer.shadowOffset = CGSizeMake(0, 1);
    card.layer.shadowRadius = 3.0f;
    card.tag = [info[@"tabIndex"] integerValue];
    [card addTarget:self action:@selector(cardTapped:)
   forControlEvents:UIControlEventTouchUpInside];

    // Highlight effect
    [card addTarget:self action:@selector(cardTouchDown:)
   forControlEvents:UIControlEventTouchDown];
    [card addTarget:self action:@selector(cardTouchUp:)
   forControlEvents:UIControlEventTouchUpInside |
                     UIControlEventTouchUpOutside |
                     UIControlEventTouchCancel];

    CGFloat cardW = frame.size.width;

    // Icon (tinted gray for tabs, gold star for favourites)
    UIImage *icon = [self iconForInfo:info];
    if (icon) {
        NSInteger tabIdx = [info[@"tabIndex"] integerValue];
        UIImage *displayIcon = (tabIdx == -1) ? icon :
            [self tintImage:icon
                  withColor:[UIColor colorWithWhite:0.45 alpha:1]];
        UIImageView *iconView = [[UIImageView alloc]
            initWithImage:displayIcon];
        iconView.frame = CGRectMake((cardW - 30) / 2.0, 16, 30, 30);
        iconView.contentMode = UIViewContentModeCenter;
        [card addSubview:iconView];
    }

    // Section name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(8, 52, cardW - 16, 20)];
    nameLabel.text = info[@"name"];
    nameLabel.font = [UIFont boldSystemFontOfSize:16];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.userInteractionEnabled = NO;
    [card addSubview:nameLabel];

    // Item count
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    [fmt setNumberStyle:NSNumberFormatterDecimalStyle];
    NSString *countStr = [fmt stringFromNumber:info[@"count"]];

    UILabel *countLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(8, 74, cardW - 16, 18)];
    countLabel.text = countStr;
    countLabel.font = [UIFont systemFontOfSize:13];
    countLabel.textColor = [UIColor grayColor];
    countLabel.textAlignment = NSTextAlignmentCenter;
    countLabel.backgroundColor = [UIColor clearColor];
    countLabel.userInteractionEnabled = NO;
    [card addSubview:countLabel];

    return card;
}

#pragma mark - Card Actions

- (void)cardTapped:(UIButton *)sender {
    if (sender.tag == -1) {
        // Favourites card → push FavouritesVC
        FavouritesVC *favVC = [[FavouritesVC alloc] initWithStyle:UITableViewStyleGrouped];
        [self.navigationController pushViewController:favVC animated:YES];
        return;
    }
    self.tabBarController.selectedIndex = (NSUInteger)sender.tag;
}

- (void)cardTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        sender.alpha = 0.7;
    }];
}

- (void)cardTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.15 animations:^{
        sender.alpha = 1.0;
    }];
}

#pragma mark - Section Data

- (NSArray *)sectionData {
    DataManager *dm = [DataManager sharedManager];
    NSMutableArray *data = [[NSMutableArray alloc] init];

    NSUInteger favCount = [dm totalFavouriteCount];
    if (favCount > 0) {
        [data addObject:@{@"name": @"Favourites", @"tabIndex": @(-1),
                          @"count": @(favCount)}];
    }

    [data addObjectsFromArray:@[
        @{@"name": @"Pok\u00e9dex",    @"tabIndex": @1,
          @"count": @([dm totalPokemonCount])},
        @{@"name": @"Moves",       @"tabIndex": @2,
          @"count": @([dm totalMoveCount])},
        @{@"name": @"Abilities",   @"tabIndex": @3,
          @"count": @([[dm allAbilitySummaries] count])},
        @{@"name": @"Items",       @"tabIndex": @4,
          @"count": @([[dm allItemSummaries] count])},
        @{@"name": @"Natures",     @"tabIndex": @5,
          @"count": @([[dm allNatureSummaries] count])},
        @{@"name": @"Egg Groups",  @"tabIndex": @6,
          @"count": @([[dm allEggGroupSummaries] count])},
        @{@"name": @"Berries",     @"tabIndex": @7,
          @"count": @([[dm allBerrySummaries] count])},
    ]];
    return data;
}

#pragma mark - Icons

- (UIImage *)iconForInfo:(NSDictionary *)info {
    NSInteger tabIndex = [info[@"tabIndex"] integerValue];
    if (tabIndex == -1) {
        return [self starIconWithSize:CGSizeMake(30, 30)];
    }
    NSArray *vcs = self.tabBarController.viewControllers;
    if ((NSUInteger)tabIndex < vcs.count) {
        UIViewController *vc = vcs[(NSUInteger)tabIndex];
        return vc.tabBarItem.image;
    }
    return nil;
}

- (UIImage *)starIconWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGFloat w = size.width, h = size.height;
    CGFloat cx = w / 2.0, cy = h / 2.0;
    CGFloat outerR = MIN(w, h) / 2.0;
    CGFloat innerR = outerR * 0.38;

    CGMutablePathRef path = CGPathCreateMutable();
    for (int i = 0; i < 10; i++) {
        CGFloat angle = (CGFloat)i * M_PI / 5.0 - M_PI / 2.0;
        CGFloat r = (i % 2 == 0) ? outerR : innerR;
        CGFloat px = cx + r * cosf(angle);
        CGFloat py = cy + r * sinf(angle);
        if (i == 0) {
            CGPathMoveToPoint(path, NULL, px, py);
        } else {
            CGPathAddLineToPoint(path, NULL, px, py);
        }
    }
    CGPathCloseSubpath(path);

    CGContextAddPath(ctx, path);
    CGContextSetFillColorWithColor(ctx,
        [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0].CGColor);
    CGContextFillPath(ctx);
    CGPathRelease(path);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)tintImage:(UIImage *)image withColor:(UIColor *)color {
    CGSize size = image.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // Draw the color fill
    [color setFill];
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGContextFillRect(ctx, rect);

    // Mask with the image alpha channel
    CGContextSetBlendMode(ctx, kCGBlendModeDestinationIn);
    CGContextDrawImage(ctx, rect, image.CGImage);

    UIImage *tinted = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tinted;
}

@end
