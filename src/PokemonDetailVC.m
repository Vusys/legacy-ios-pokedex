#import "PokemonDetailVC.h"
#import "Pokemon.h"
#import "PokemonType.h"
#import "DataManager.h"
#import "TypeBadgeView.h"
#import "StatBarView.h"
#import "TextBlockCell.h"
#import "KeyValueCell.h"
#import "DetailSpriteCell.h"
#import "StatBarCell.h"
#import "TypeGridCell.h"
#import "DetailMoveCell.h"
#import "EvolutionCell.h"
#import "DetailConstants.h"
#import <QuartzCore/QuartzCore.h>

@interface PokemonDetailVC ()
@property (nonatomic, strong) Pokemon *pokemon;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *artworkView;
@property (nonatomic, strong) UIScrollView *thumbnailScroll;
@property (nonatomic, strong) NSArray *thumbnailEntries; // array of {image, label, isSprite}
@property (nonatomic, strong) NSMutableArray *thumbnailImageViews;
@property (nonatomic, assign) NSInteger selectedThumbnailIndex;
@property (nonatomic, strong) UIView *scrollFadeView;
@property (nonatomic, assign) NSInteger fullscreenIndex;
@end

@implementation PokemonDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.pokemonID > 0) {
        CFAbsoluteTime loadStart = CFAbsoluteTimeGetCurrent();
        self.pokemon = [[DataManager sharedManager] pokemonDetailWithID:self.pokemonID];
        NSLog(@"[PERF] PokemonDetailVC loadData: %.1fms (id=%ld, name=%@)",
              (CFAbsoluteTimeGetCurrent() - loadStart) * 1000,
              (long)self.pokemonID, self.pokemon.name ?: @"nil");
        self.title = self.pokemon.name ?: @"Pok\u00e9dex";
        NSLog(@"[DEBUG] PokemonDetailVC viewDidLoad: about to build, tableView.width=%.0f view.width=%.0f",
              self.tableView.bounds.size.width, self.view.bounds.size.width);
        [self buildSections];
        [self setupHeaderView];
        [self.tableView reloadData];
        [self setupFavouriteButton];
    } else {
        [self showEmptyState];
    }
}

- (BOOL)hasData {
    return self.pokemon != nil;
}

- (NSString *)favouriteEntityType { return @"pokemon"; }
- (NSInteger)favouriteEntityID { return self.pokemonID; }

- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom {
    top[0] = 0.55; top[1] = 0.0; top[2] = 0.0; top[3] = 1.0;
    bottom[0] = 0.80; bottom[1] = 0.0; bottom[2] = 0.0; bottom[3] = 1.0;
}

- (NSString *)emptyStateText {
    return @"Select a Pok\u00e9mon";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.thumbnailScroll) {
        [self.thumbnailScroll flashScrollIndicators];
    }
}

#pragma mark - Header View

- (void)setupHeaderView {
    if (!self.pokemon) return;

    DataManager *dm = [DataManager sharedManager];
    NSInteger pid = self.pokemon.pokemonID;
    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat width = self.tableView.bounds.size.width;
    CGFloat innerWidth = width - pad * 2;

    NSLog(@"[DEBUG] PokemonDetailVC setupHeaderView: tableWidth=%.0f innerWidth=%.0f (pokemon=%@)",
          width, innerWidth, self.pokemon.name);

    // Build thumbnail entries: array of dicts with image + label
    [self buildThumbnailEntries];

    // Artwork
    UIImage *artworkImage = [dm artworkForPokemonID:pid];
    BOOL hasArtwork = (artworkImage != nil);
    CGFloat artworkDisplaySize = hasArtwork ? MIN(floorf(innerWidth * 0.65), 280) : 96;

    UIImage *frontImage = [dm spriteForPokemonID:pid];
    if (!hasArtwork) artworkImage = frontImage;

    // Layout height calculation
    CGFloat infoHeight = 96;
    BOOL hasClassification = self.pokemon.isLegendary || self.pokemon.isMythical || self.pokemon.isBaby;
    CGFloat classificationHeight = hasClassification ? 22 : 0;
    CGFloat artworkRowHeight = artworkDisplaySize + 8;
    CGFloat thumbnailStripH = 78;
    CGFloat labelH = 12;
    CGFloat headerHeight = pad + infoHeight + classificationHeight + artworkRowHeight
                           + thumbnailStripH + labelH + 4 + pad;

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, headerHeight)];
    CGFloat cy = pad;

    // Number
    UILabel *numberLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(pad, cy, innerWidth, 18)];
    numberLabel.text = [self.pokemon formattedID];
    numberLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
    if (!numberLabel.font) numberLabel.font = [UIFont boldSystemFontOfSize:14];
    numberLabel.textColor = [UIColor grayColor];
    numberLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:numberLabel];
    cy += 18;

    // Name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(pad, cy, innerWidth, 28)];
    nameLabel.text = self.pokemon.name;
    nameLabel.font = [UIFont boldSystemFontOfSize:24];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:nameLabel];
    cy += 28;

    // Genus
    UILabel *genusLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(pad, cy, innerWidth, 18)];
    genusLabel.text = self.pokemon.genus;
    genusLabel.font = [UIFont italicSystemFontOfSize:13];
    genusLabel.textColor = [UIColor grayColor];
    genusLabel.backgroundColor = [UIColor clearColor];
    [header addSubview:genusLabel];
    cy += 22;

    // Type badges
    CGFloat badgeX = pad;
    for (NSString *type in self.pokemon.types) {
        TypeBadgeView *badge = [[TypeBadgeView alloc] initWithTypeName:type];
        badge.frame = CGRectMake(badgeX, cy,
                                 [TypeBadgeView badgeWidth], [TypeBadgeView badgeHeight]);
        [header addSubview:badge];
        badgeX += [TypeBadgeView badgeWidth] + 6;
    }
    cy += [TypeBadgeView badgeHeight] + 8;

    // Classification badges
    if (hasClassification) {
        CGFloat classBadgeX = pad;
        CGFloat classBadgeH = 18;
        UIFont *classBadgeFont = [UIFont boldSystemFontOfSize:9];

        NSMutableArray *badgeInfo = [[NSMutableArray alloc] init];
        if (self.pokemon.isLegendary)
            [badgeInfo addObject:@[@"LEGENDARY",
                [UIColor colorWithRed:0.83 green:0.63 blue:0.09 alpha:1]]];
        if (self.pokemon.isMythical)
            [badgeInfo addObject:@[@"MYTHICAL",
                [UIColor colorWithRed:0.55 green:0.36 blue:0.96 alpha:1]]];
        if (self.pokemon.isBaby)
            [badgeInfo addObject:@[@"BABY",
                [UIColor colorWithRed:0.96 green:0.45 blue:0.71 alpha:1]]];

        for (NSArray *info in badgeInfo) {
            NSString *text = info[0];
            UIColor *color = info[1];
            CGSize textSize = [text sizeWithFont:classBadgeFont];
            CGFloat badgeW = textSize.width + 12;

            UIView *classBadge = [[UIView alloc] initWithFrame:
                CGRectMake(classBadgeX, cy, badgeW, classBadgeH)];
            classBadge.backgroundColor = color;
            classBadge.layer.cornerRadius = 3;

            UILabel *badgeLbl = [[UILabel alloc] initWithFrame:classBadge.bounds];
            badgeLbl.text = text;
            badgeLbl.font = classBadgeFont;
            badgeLbl.textColor = [UIColor whiteColor];
            badgeLbl.textAlignment = NSTextAlignmentCenter;
            badgeLbl.backgroundColor = [UIColor clearColor];
            [classBadge addSubview:badgeLbl];
            [header addSubview:classBadge];
            classBadgeX += badgeW + 4;
        }
        cy += classBadgeH + 4;
    }

    // Artwork (centered, tappable)
    CGFloat artworkX = (width - artworkDisplaySize) / 2.0;
    self.artworkView = [[UIImageView alloc] initWithFrame:
        CGRectMake(artworkX, cy, artworkDisplaySize, artworkDisplaySize)];
    self.artworkView.contentMode = UIViewContentModeScaleAspectFit;
    self.artworkView.image = artworkImage;
    self.artworkView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    self.artworkView.layer.cornerRadius = 8;
    self.artworkView.layer.borderWidth = 0.5;
    self.artworkView.layer.borderColor = [[UIColor colorWithWhite:0.88 alpha:1] CGColor];
    self.artworkView.clipsToBounds = YES;
    self.artworkView.userInteractionEnabled = YES;
    UITapGestureRecognizer *artTap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(artworkTapped:)];
    [self.artworkView addGestureRecognizer:artTap];
    [header addSubview:self.artworkView];
    cy += artworkDisplaySize + 8;

    // Thumbnail scroll strip
    CGFloat thumbSize = 64;
    CGFloat thumbGap = 6;
    CGFloat stripTotalH = thumbnailStripH + labelH + 4;

    self.thumbnailScroll = [[UIScrollView alloc] initWithFrame:
        CGRectMake(0, cy, width, stripTotalH)];
    self.thumbnailScroll.showsHorizontalScrollIndicator = YES;
    self.thumbnailScroll.showsVerticalScrollIndicator = NO;

    self.thumbnailImageViews = [[NSMutableArray alloc] init];
    CGFloat tx = pad;

    for (NSUInteger i = 0; i < self.thumbnailEntries.count; i++) {
        NSDictionary *entry = self.thumbnailEntries[i];
        UIImage *img = entry[@"image"];
        NSString *label = entry[@"label"];
        BOOL isSprite = [entry[@"isSprite"] boolValue];

        // For pixel sprites, pre-scale to integer-ratio size for crisp rendering
        UIImage *displayImg = img;
        if (isSprite) {
            displayImg = [self pixelScaledImage:img toFitSize:thumbSize];
        }

        // Thumbnail image view
        UIImageView *iv = [[UIImageView alloc] initWithFrame:
            CGRectMake(tx, 4, thumbSize, thumbSize)];
        iv.clipsToBounds = YES;

        if (isSprite) {
            iv.contentMode = UIViewContentModeCenter;
            iv.image = displayImg;
        } else {
            iv.contentMode = UIViewContentModeScaleAspectFit;
            iv.image = img;
        }

        iv.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        iv.layer.cornerRadius = 4;
        iv.layer.borderWidth = (i == 0) ? 2.0 : 0.5;
        iv.layer.borderColor = (i == 0) ?
            [[UIColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:1] CGColor] :
            [[UIColor colorWithWhite:0.85 alpha:1] CGColor];
        iv.userInteractionEnabled = YES;
        iv.tag = (NSInteger)i;

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(thumbnailTapped:)];
        [iv addGestureRecognizer:tap];

        [self.thumbnailScroll addSubview:iv];
        [self.thumbnailImageViews addObject:iv];

        // Label below thumbnail
        UILabel *thumbLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(tx, 4 + thumbSize + 2, thumbSize, labelH)];
        thumbLabel.text = label;
        thumbLabel.font = [UIFont systemFontOfSize:9];
        thumbLabel.textColor = [UIColor grayColor];
        thumbLabel.textAlignment = NSTextAlignmentCenter;
        thumbLabel.backgroundColor = [UIColor clearColor];
        [self.thumbnailScroll addSubview:thumbLabel];

        tx += thumbSize + thumbGap;
    }

    self.thumbnailScroll.contentSize = CGSizeMake(tx, stripTotalH);
    [header addSubview:self.thumbnailScroll];

    // Right-edge gradient fade to indicate scrollable content
    if (tx > width) {
        CGFloat fadeW = 36;
        self.scrollFadeView = [[UIView alloc] initWithFrame:
            CGRectMake(width - fadeW, cy, fadeW, stripTotalH)];
        self.scrollFadeView.userInteractionEnabled = NO;

        CAGradientLayer *fade = [CAGradientLayer layer];
        fade.frame = self.scrollFadeView.bounds;
        fade.colors = @[
            (id)[[UIColor colorWithWhite:1.0 alpha:0.0] CGColor],
            (id)[[UIColor colorWithWhite:1.0 alpha:0.95] CGColor]
        ];
        fade.startPoint = CGPointMake(0, 0.5);
        fade.endPoint = CGPointMake(1, 0.5);
        [self.scrollFadeView.layer addSublayer:fade];
        [header addSubview:self.scrollFadeView];
    }

    self.selectedThumbnailIndex = 0;

    self.headerView = header;
    self.tableView.tableHeaderView = header;
}

- (void)buildThumbnailEntries {
    DataManager *dm = [DataManager sharedManager];
    NSInteger pid = self.pokemon.pokemonID;
    NSMutableArray *entries = [[NSMutableArray alloc] init];

    // Artwork (full-size) comes first
    UIImage *artwork = [dm artworkForPokemonID:pid];
    if (artwork) {
        [entries addObject:@{@"image": artwork, @"label": @"Artwork", @"isSprite": @NO}];
    }

    // Front default
    UIImage *front = [dm spriteForPokemonID:pid];
    if (front) {
        [entries addObject:@{@"image": front, @"label": @"Front", @"isSprite": @YES}];
    }

    // Back default
    UIImage *back = [dm backSpriteForPokemonID:pid];
    if (back) {
        [entries addObject:@{@"image": back, @"label": @"Back", @"isSprite": @YES}];
    }

    // Shiny front
    UIImage *shinyFront = [dm shinySpriteForPokemonID:pid];
    if (shinyFront) {
        [entries addObject:@{@"image": shinyFront, @"label": @"Shiny", @"isSprite": @YES}];
    }

    // Shiny back
    UIImage *shinyBack = [dm backShinySpriteForPokemonID:pid];
    if (shinyBack) {
        [entries addObject:@{@"image": shinyBack, @"label": @"Shiny Back", @"isSprite": @YES}];
    }

    // Shiny artwork
    UIImage *shinyArt = [dm shinyArtworkForPokemonID:pid];
    if (shinyArt) {
        [entries addObject:@{@"image": shinyArt, @"label": @"Shiny Art", @"isSprite": @NO}];
    }

    // Female front
    if (self.pokemon.hasFemaleSprite) {
        UIImage *female = [dm femaleSpriteForPokemonID:pid];
        if (female) {
            [entries addObject:@{@"image": female, @"label": @"\u2640 Front", @"isSprite": @YES}];
        }
    }

    // Female back
    if (self.pokemon.hasBackFemaleSprite) {
        UIImage *backFemale = [dm backFemaleSpriteForPokemonID:pid];
        if (backFemale) {
            [entries addObject:@{@"image": backFemale, @"label": @"\u2640 Back", @"isSprite": @YES}];
        }
    }

    // Shiny female
    if (self.pokemon.hasShinyFemaleSprite) {
        UIImage *shinyFemale = [dm shinyFemaleSpriteForPokemonID:pid];
        if (shinyFemale) {
            [entries addObject:@{@"image": shinyFemale, @"label": @"\u2640 Shiny", @"isSprite": @YES}];
        }
    }

    // Shiny female back
    if (self.pokemon.hasBackShinyFemaleSprite) {
        UIImage *backShinyFemale = [dm backShinyFemaleSpriteForPokemonID:pid];
        if (backShinyFemale) {
            [entries addObject:@{@"image": backShinyFemale, @"label": @"\u2640 Sh.Back", @"isSprite": @YES}];
        }
    }

    self.thumbnailEntries = entries;
}

- (void)thumbnailTapped:(UITapGestureRecognizer *)gesture {
    NSInteger index = gesture.view.tag;
    if (index < 0 || (NSUInteger)index >= self.thumbnailEntries.count) return;

    // Update selection highlight
    UIImageView *oldThumb = self.thumbnailImageViews[(NSUInteger)self.selectedThumbnailIndex];
    oldThumb.layer.borderWidth = 0.5;
    oldThumb.layer.borderColor = [[UIColor colorWithWhite:0.85 alpha:1] CGColor];

    UIImageView *newThumb = self.thumbnailImageViews[(NSUInteger)index];
    newThumb.layer.borderWidth = 2.0;
    newThumb.layer.borderColor = [[UIColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:1] CGColor];

    self.selectedThumbnailIndex = index;

    // Update large artwork view with pixel-perfect scaling for sprites
    NSDictionary *entry = self.thumbnailEntries[(NSUInteger)index];
    UIImage *image = entry[@"image"];
    BOOL isSprite = [entry[@"isSprite"] boolValue];

    if (isSprite) {
        CGFloat containerSize = self.artworkView.bounds.size.width;
        UIImage *scaled = [self pixelScaledImage:image toFitSize:containerSize];
        self.artworkView.image = scaled;
        self.artworkView.contentMode = UIViewContentModeCenter;
        self.artworkView.layer.magnificationFilter = kCAFilterNearest;
    } else {
        self.artworkView.image = image;
        self.artworkView.contentMode = UIViewContentModeScaleAspectFit;
        self.artworkView.layer.magnificationFilter = kCAFilterLinear;
    }
}

#pragma mark - Fullscreen Image

- (void)artworkTapped:(UITapGestureRecognizer *)gesture {
    UIImage *image = self.artworkView.image;
    if (!image) return;

    self.fullscreenIndex = self.selectedThumbnailIndex;

    UIWindow *window = self.view.window;
    CGRect windowBounds = window.bounds;
    CGFloat statusBarH = 20;
    CGFloat toolbarH = 44;
    CGFloat topInset = statusBarH + toolbarH;

    UIView *overlay = [[UIView alloc] initWithFrame:windowBounds];
    overlay.backgroundColor = [UIColor whiteColor];
    overlay.tag = 8888;
    overlay.clipsToBounds = YES;

    // Start off-screen (below)
    overlay.frame = CGRectMake(0, windowBounds.size.height,
                               windowBounds.size.width, windowBounds.size.height);

    // Black status bar background
    UIView *statusBg = [[UIView alloc] initWithFrame:
        CGRectMake(0, 0, windowBounds.size.width, statusBarH)];
    statusBg.backgroundColor = [UIColor blackColor];
    [overlay addSubview:statusBg];

    // iOS-style black toolbar below status bar
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:
        CGRectMake(0, statusBarH, windowBounds.size.width, toolbarH)];
    toolbar.barStyle = UIBarStyleBlack;
    toolbar.tag = 8889;

    [self updateFullscreenToolbar:toolbar];

    [overlay addSubview:toolbar];

    // Image area below toolbar
    CGRect imageArea = CGRectMake(0, topInset, windowBounds.size.width,
                                  windowBounds.size.height - topInset);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageArea];
    imageView.backgroundColor = [UIColor whiteColor];
    imageView.tag = 8890;

    [self configureFullscreenImageView:imageView forIndex:self.fullscreenIndex];

    [overlay addSubview:imageView];

    // Swipe gestures
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(fullscreenSwipeLeft:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [overlay addGestureRecognizer:swipeLeft];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(fullscreenSwipeRight:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [overlay addGestureRecognizer:swipeRight];

    [window addSubview:overlay];

    // Slide up from bottom
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        overlay.frame = windowBounds;
    } completion:nil];
}

- (void)dismissFullScreenOverlay:(id)sender {
    UIWindow *window = self.view.window;
    UIView *overlay = [window viewWithTag:8888];
    if (!overlay) return;

    // Also update the thumbnail selection to match where the user swiped to
    if (self.fullscreenIndex != self.selectedThumbnailIndex) {
        UIImageView *oldThumb = self.thumbnailImageViews[(NSUInteger)self.selectedThumbnailIndex];
        oldThumb.layer.borderWidth = 0.5;
        oldThumb.layer.borderColor = [[UIColor colorWithWhite:0.85 alpha:1] CGColor];

        UIImageView *newThumb = self.thumbnailImageViews[(NSUInteger)self.fullscreenIndex];
        newThumb.layer.borderWidth = 2.0;
        newThumb.layer.borderColor = [[UIColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:1] CGColor];

        self.selectedThumbnailIndex = self.fullscreenIndex;

        // Update main artwork view too
        NSDictionary *entry = self.thumbnailEntries[(NSUInteger)self.fullscreenIndex];
        UIImage *img = entry[@"image"];
        BOOL isSprite = [entry[@"isSprite"] boolValue];
        if (isSprite) {
            CGFloat containerSize = self.artworkView.bounds.size.width;
            self.artworkView.image = [self pixelScaledImage:img toFitSize:containerSize];
            self.artworkView.contentMode = UIViewContentModeCenter;
            self.artworkView.layer.magnificationFilter = kCAFilterNearest;
        } else {
            self.artworkView.image = img;
            self.artworkView.contentMode = UIViewContentModeScaleAspectFit;
            self.artworkView.layer.magnificationFilter = kCAFilterLinear;
        }
    }

    CGRect windowBounds = window.bounds;
    // Slide down off screen
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        overlay.frame = CGRectMake(0, windowBounds.size.height,
                                   windowBounds.size.width, windowBounds.size.height);
    } completion:^(BOOL finished) {
        [overlay removeFromSuperview];
    }];
}

- (void)configureFullscreenImageView:(UIImageView *)imageView forIndex:(NSInteger)index {
    NSDictionary *entry = self.thumbnailEntries[(NSUInteger)index];
    UIImage *fullImage = entry[@"image"];
    BOOL isSprite = [entry[@"isSprite"] boolValue];

    if (isSprite) {
        CGFloat fitDim = MIN(imageView.bounds.size.width, imageView.bounds.size.height);
        UIImage *scaled = [self pixelScaledImage:fullImage toFitSize:fitDim];
        imageView.image = scaled;
        imageView.contentMode = UIViewContentModeCenter;
        imageView.layer.magnificationFilter = kCAFilterNearest;
    } else {
        imageView.image = fullImage;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.layer.magnificationFilter = kCAFilterLinear;
    }
}

- (void)updateFullscreenToolbar:(UIToolbar *)toolbar {
    NSDictionary *entry = self.thumbnailEntries[(NSUInteger)self.fullscreenIndex];
    NSString *label = entry[@"label"];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = label;
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    [titleLabel sizeToFit];

    UIBarButtonItem *titleItem = [[UIBarButtonItem alloc]
        initWithCustomView:titleLabel];

    UIBarButtonItem *flex = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
        target:nil action:nil];

    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Done" style:UIBarButtonItemStyleDone
        target:self action:@selector(dismissFullScreenOverlay:)];

    toolbar.items = @[titleItem, flex, doneItem];
}

- (void)fullscreenSwipeLeft:(UISwipeGestureRecognizer *)gesture {
    [self fullscreenNavigate:1];
}

- (void)fullscreenSwipeRight:(UISwipeGestureRecognizer *)gesture {
    [self fullscreenNavigate:-1];
}

- (void)fullscreenNavigate:(NSInteger)direction {
    NSInteger newIndex = self.fullscreenIndex + direction;
    if (newIndex < 0 || (NSUInteger)newIndex >= self.thumbnailEntries.count) return;

    UIView *overlay = [self.view.window viewWithTag:8888];
    if (!overlay) return;

    UIImageView *imageView = (UIImageView *)[overlay viewWithTag:8890];
    UIToolbar *toolbar = (UIToolbar *)[overlay viewWithTag:8889];
    if (!imageView || !toolbar) return;

    self.fullscreenIndex = newIndex;

    // Animate image transition
    CGFloat slideDistance = overlay.bounds.size.width;
    CGFloat offsetX = (direction > 0) ? -slideDistance : slideDistance;

    UIImageView *newImageView = [[UIImageView alloc] initWithFrame:imageView.frame];
    newImageView.backgroundColor = [UIColor whiteColor];
    newImageView.tag = 0; // temp tag
    [self configureFullscreenImageView:newImageView forIndex:newIndex];

    // Position new image off-screen in the swipe direction
    CGRect newStart = newImageView.frame;
    newStart.origin.x = -offsetX;
    newImageView.frame = newStart;
    [overlay addSubview:newImageView];

    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        // Slide old image out
        CGRect oldFrame = imageView.frame;
        oldFrame.origin.x = offsetX;
        imageView.frame = oldFrame;

        // Slide new image in
        CGRect targetFrame = newImageView.frame;
        targetFrame.origin.x = 0;
        newImageView.frame = targetFrame;
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
        newImageView.tag = 8890;
    }];

    // Update toolbar title
    [self updateFullscreenToolbar:toolbar];
}

#pragma mark - Pixel Scaling

- (UIImage *)pixelScaledImage:(UIImage *)image toFitSize:(CGFloat)containerSize {
    CGFloat nativeSize = MAX(image.size.width, image.size.height);
    if (nativeSize <= 0) return image;

    CGFloat targetSize;
    if (nativeSize <= containerSize) {
        // Magnification: largest integer multiple that fits
        NSInteger multiple = (NSInteger)floorf(containerSize / nativeSize);
        if (multiple < 1) multiple = 1;
        targetSize = nativeSize * multiple;
    } else {
        // Minification: smallest integer divisor that makes it fit
        NSInteger divisor = (NSInteger)ceilf(nativeSize / containerSize);
        if (divisor < 1) divisor = 1;
        targetSize = nativeSize / divisor;
    }

    CGFloat scale = targetSize / nativeSize;
    CGFloat w = image.size.width * scale;
    CGFloat h = image.size.height * scale;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), NO, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    [image drawInRect:CGRectMake(0, 0, w, h)];
    UIImage *scaled = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaled;
}

#pragma mark - Build Sections

- (void)buildSections {
    if (!self.pokemon) {
        self.sections = @[];
        return;
    }

    NSMutableArray *sects = [[NSMutableArray alloc] init];
    CGFloat tableWidth = self.tableView.bounds.size.width;

    CFAbsoluteTime totalStart = CFAbsoluteTimeGetCurrent();

    // Flavor text entries
    {
        NSArray *entries = self.pokemon.flavorTextEntries;
        NSString *fallbackText = self.pokemon.flavorText;
        if (!entries || entries.count == 0) {
            if (fallbackText.length > 0) {
                entries = @[@{@"text": fallbackText, @"versions": @[]}];
            }
        }
        if (entries.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            NSDictionary *versionNames = [self versionDisplayNames];
            UIFont *italicFont = [UIFont italicSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
            UIFont *boldFont = [UIFont boldSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
            for (NSUInteger i = 0; i < entries.count; i++) {
                NSDictionary *entry = entries[i];
                NSString *text = entry[@"text"] ?: @"";
                NSString *versionStr = @"";

                if (i > 0) {
                    NSArray *versions = entry[@"versions"] ?: @[];
                    NSMutableArray *displayVersions = [[NSMutableArray alloc] init];
                    for (NSString *v in versions) {
                        [displayVersions addObject:(versionNames[v] ?: v)];
                    }
                    versionStr = [displayVersions componentsJoinedByString:@" / "];
                }

                CGFloat h = [TextBlockCell heightForText:text width:tableWidth font:italicFont];
                if (versionStr.length > 0) {
                    CGFloat vh = [TextBlockCell heightForText:versionStr width:tableWidth font:boldFont];
                    h = h + vh - 8; // subtract one padding since they share the cell
                }
                [rows addObject:@{
                    @"type": @"flavortext",
                    @"text": text,
                    @"versionStr": versionStr,
                    @"height": @(h)
                }];
            }
            [sects addObject:@{@"rows": rows}];
        }
    }

    // Base Stats
    {
        NSDictionary *stats = self.pokemon.stats;
        if (stats && stats.count > 0) {
            NSArray *statOrder = @[@"hp", @"attack", @"defense",
                                   @"special-attack", @"special-defense", @"speed"];
            NSDictionary *statNames = @{
                @"hp": @"HP", @"attack": @"Atk", @"defense": @"Def",
                @"special-attack": @"Sp.Atk", @"special-defense": @"Sp.Def",
                @"speed": @"Speed"
            };

            NSMutableArray *rows = [[NSMutableArray alloc] init];
            NSInteger total = 0;
            for (NSString *key in statOrder) {
                NSInteger value = [stats[key] integerValue];
                total += value;
                [rows addObject:@{
                    @"type": @"statbar",
                    @"name": statNames[key],
                    @"value": @(value),
                    @"height": @(DETAIL_STAT_HEIGHT)
                }];
            }
            [rows addObject:@{
                @"type": @"keyvalue",
                @"key": @"Total",
                @"value": [NSString stringWithFormat:@"%ld", (long)total],
                @"height": @(28)
            }];
            [sects addObject:@{@"title": @"Base Stats", @"rows": rows}];
        }
    }

    // Type Effectiveness
    [self buildTypeEffectivenessSection:sects width:tableWidth];

    // Info
    {
        NSArray *rows = @[
            @{@"type": @"keyvalue", @"key": @"Height", @"value": [self.pokemon formattedHeight]},
            @{@"type": @"keyvalue", @"key": @"Weight", @"value": [self.pokemon formattedWeight]},
            @{@"type": @"keyvalue", @"key": @"Color", @"value": [self titleCase:self.pokemon.color]},
            @{@"type": @"keyvalue", @"key": @"Shape", @"value": [self formatShape:self.pokemon.shape]},
            @{@"type": @"keyvalue", @"key": @"Habitat", @"value": [self titleCase:self.pokemon.habitat]},
            @{@"type": @"keyvalue", @"key": @"Catch Rate",
              @"value": [NSString stringWithFormat:@"%ld", (long)self.pokemon.captureRate]},
            @{@"type": @"keyvalue", @"key": @"Base Exp",
              @"value": [NSString stringWithFormat:@"%ld", (long)self.pokemon.baseExperience]},
            @{@"type": @"keyvalue", @"key": @"Generation",
              @"value": [self formatGeneration:self.pokemon.generation]},
        ];
        [sects addObject:@{@"title": @"Info", @"rows": rows}];
    }

    // Pokedex Numbers
    {
        NSArray *numbers = self.pokemon.pokedexNumbers;
        if (numbers && numbers.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            for (NSDictionary *entry in numbers) {
                NSInteger num = [entry[@"number"] integerValue];
                [rows addObject:@{
                    @"type": @"keyvalue",
                    @"key": entry[@"name"] ?: @"",
                    @"value": [NSString stringWithFormat:@"#%03ld", (long)num],
                    @"valueFont": @"mono"
                }];
            }
            [sects addObject:@{@"title": @"Pok\u00e9dex Numbers", @"rows": rows}];
        }
    }

    // Localized Names
    {
        NSArray *names = self.pokemon.localizedNames;
        if (names && names.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            for (NSDictionary *entry in names) {
                [rows addObject:@{
                    @"type": @"keyvalue",
                    @"key": entry[@"language"] ?: @"",
                    @"value": entry[@"name"] ?: @""
                }];
            }
            [sects addObject:@{@"title": @"Names", @"rows": rows}];
        }
    }

    // Wild Held Items
    {
        NSArray *items = self.pokemon.heldItems;
        if (items && items.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            for (NSDictionary *item in items) {
                [rows addObject:@{
                    @"type": @"helditem",
                    @"name": item[@"name"] ?: @"",
                    @"api_name": item[@"api_name"] ?: @"",
                    @"rarity": item[@"rarity"] ?: @0,
                    @"height": @(DETAIL_ROW_HEIGHT)
                }];
            }
            [sects addObject:@{@"title": @"Wild Held Items", @"rows": rows}];
        }
    }

    // Abilities
    {
        NSArray *abilities = self.pokemon.abilities;
        if (abilities && abilities.count > 0) {
            NSMutableArray *rows = [[NSMutableArray alloc] init];
            for (NSDictionary *ability in abilities) {
                NSString *name = ability[@"name"] ?: @"";
                BOOL isHidden = [ability[@"is_hidden"] boolValue];
                NSString *display = isHidden ?
                    [NSString stringWithFormat:@"%@ (Hidden)", name] : name;
                [rows addObject:@{
                    @"type": @"ability",
                    @"display": display,
                    @"isHidden": @(isHidden)
                }];
            }
            [sects addObject:@{@"title": @"Abilities", @"rows": rows}];
        }
    }

    // Breeding
    {
        NSArray *rows = @[
            @{@"type": @"keyvalue", @"key": @"Egg Groups",
              @"value": ([[self.pokemon.eggGroups componentsJoinedByString:@", "] length] > 0 ?
                  [self.pokemon.eggGroups componentsJoinedByString:@", "] : @"None")},
            @{@"type": @"keyvalue", @"key": @"Gender", @"value": [self.pokemon genderString]},
            @{@"type": @"keyvalue", @"key": @"Hatch Steps",
              @"value": [NSString stringWithFormat:@"~%ld", (long)(self.pokemon.hatchCounter * 256)]},
            @{@"type": @"keyvalue", @"key": @"Base Happy",
              @"value": [NSString stringWithFormat:@"%ld", (long)self.pokemon.baseHappiness]},
            @{@"type": @"keyvalue", @"key": @"Growth Rate", @"value": [self.pokemon formattedGrowthRate]},
        ];
        [sects addObject:@{@"title": @"Breeding", @"rows": rows}];
    }

    // Encounters
    [self buildEncounterSections:sects];

    // Evolution
    [self buildEvolutionSection:sects];

    // Moves (one section per learn method)
    [self buildMoveSections:sects];

    self.sections = sects;

    NSLog(@"[DEBUG] PokemonDetailVC buildSections: %lu sections, tableWidth=%.0f",
          (unsigned long)sects.count, tableWidth);
    NSLog(@"[PERF] PokemonDetailVC buildSections TOTAL: %.1fms (pokemon=%@)",
          (CFAbsoluteTimeGetCurrent() - totalStart) * 1000,
          self.pokemon.name ?: @"nil");
}

- (void)buildTypeEffectivenessSection:(NSMutableArray *)sects width:(CGFloat)tableWidth {
    NSArray *pokemonTypes = self.pokemon.types;
    if (!pokemonTypes || pokemonTypes.count == 0) return;

    NSArray *allTypes = [[DataManager sharedManager] allTypes];
    if (allTypes.count == 0) return;

    NSMutableDictionary *relationsMap = [[NSMutableDictionary alloc] init];
    for (NSDictionary *typeData in allTypes) {
        NSString *name = typeData[@"name"];
        if (name) relationsMap[name] = typeData[@"damage_relations"] ?: @{};
    }

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

    NSMutableArray *categories = [[NSMutableArray alloc] init];
    if (weak4x.count > 0) [categories addObject:@[@"4\u00D7 Weak", weak4x]];
    if (weak2x.count > 0) [categories addObject:@[@"2\u00D7 Weak", weak2x]];
    if (resist2x.count > 0) [categories addObject:@[@"\u00BD\u00D7 Resist", resist2x]];
    if (resist4x.count > 0) [categories addObject:@[@"\u00BC\u00D7 Resist", resist4x]];
    if (immune.count > 0) [categories addObject:@[@"Immune", immune]];

    if (categories.count == 0) return;

    NSMutableArray *rows = [[NSMutableArray alloc] init];
    for (NSArray *cat in categories) {
        CGFloat h = [TypeGridCell heightForLabel:cat[0] types:cat[1] width:tableWidth];
        [rows addObject:@{
            @"type": @"typegrid",
            @"label": cat[0],
            @"types": cat[1],
            @"height": @(h)
        }];
    }
    [sects addObject:@{@"title": @"Type Effectiveness", @"rows": rows}];
}

- (void)buildEncounterSections:(NSMutableArray *)sects {
    NSArray *encounters = [[DataManager sharedManager] encounterDataForPokemonID:self.pokemonID];
    if (!encounters || encounters.count == 0) return;

    NSUInteger maxVersions = 8;
    NSUInteger maxLocationsPerVersion = 10;
    NSUInteger totalVersions = encounters.count;
    NSUInteger versionsToShow = MIN(totalVersions, maxVersions);

    for (NSUInteger i = 0; i < versionsToShow; i++) {
        NSDictionary *versionEntry = encounters[i];
        NSString *versionName = versionEntry[@"version"] ?: @"Unknown";
        NSArray *locations = versionEntry[@"locations"] ?: @[];

        NSMutableArray *rows = [[NSMutableArray alloc] init];
        NSUInteger locCount = MIN(locations.count, maxLocationsPerVersion);

        for (NSUInteger j = 0; j < locCount; j++) {
            NSDictionary *loc = locations[j];
            NSString *locationName = loc[@"location"] ?: @"Unknown";
            NSString *method = loc[@"method"] ?: @"";
            NSInteger minLevel = [loc[@"min_level"] integerValue];
            NSInteger maxLevel = [loc[@"max_level"] integerValue];
            NSInteger chance = [loc[@"chance"] integerValue];

            NSMutableString *detail = [[NSMutableString alloc] init];
            if (method.length > 0) {
                [detail appendString:method];
            }
            if (minLevel > 0 || maxLevel > 0) {
                if (detail.length > 0) [detail appendString:@", "];
                if (minLevel == maxLevel) {
                    [detail appendFormat:@"Lv. %ld", (long)minLevel];
                } else {
                    [detail appendFormat:@"Lv. %ld\u2013%ld", (long)minLevel, (long)maxLevel];
                }
            }
            if (chance > 0) {
                [detail appendFormat:@" (%ld%%)", (long)chance];
            }

            [rows addObject:@{
                @"type": @"keyvalue",
                @"key": locationName,
                @"value": detail
            }];
        }

        if (locations.count > maxLocationsPerVersion) {
            NSUInteger extra = locations.count - maxLocationsPerVersion;
            [rows addObject:@{
                @"type": @"keyvalue",
                @"key": @"",
                @"value": [NSString stringWithFormat:@"...and %lu more location%s",
                    (unsigned long)extra, extra == 1 ? "" : "s"]
            }];
        }

        // First version section gets "Encounters" prefix in title
        NSString *title;
        if (i == 0) {
            title = [NSString stringWithFormat:@"Encounters \u2014 %@", versionName];
        } else {
            title = versionName;
        }
        [sects addObject:@{@"title": title, @"rows": rows}];
    }

    if (totalVersions > maxVersions) {
        NSUInteger extra = totalVersions - maxVersions;
        NSMutableArray *rows = [[NSMutableArray alloc] init];
        [rows addObject:@{
            @"type": @"keyvalue",
            @"key": @"",
            @"value": [NSString stringWithFormat:@"Also appears in %lu other game%s",
                (unsigned long)extra, extra == 1 ? "" : "s"]
        }];
        [sects addObject:@{@"rows": rows}];
    }
}

- (void)buildEvolutionSection:(NSMutableArray *)sects {
    NSArray *chain = self.pokemon.evolutionChain;
    if (!chain || chain.count < 2) return;

    NSMutableDictionary *entryById = [[NSMutableDictionary alloc] init];
    for (NSDictionary *entry in chain) {
        NSNumber *eid = entry[@"id"];
        if (eid) entryById[eid] = entry;
    }

    NSMutableArray *pairs = [[NSMutableArray alloc] init];
    for (NSDictionary *entry in chain) {
        id fromId = entry[@"from_id"];
        if (!fromId || fromId == [NSNull null]) continue;
        if ([fromId isKindOfClass:[NSString class]] && [fromId length] == 0) continue;
        NSDictionary *fromEntry = entryById[@([fromId integerValue])];
        if (!fromEntry) continue;
        [pairs addObject:@[fromEntry, entry]];
    }

    if (pairs.count == 0) return;

    NSMutableArray *rows = [[NSMutableArray alloc] init];
    for (NSArray *pair in pairs) {
        NSDictionary *from = pair[0];
        NSDictionary *to = pair[1];
        [rows addObject:@{
            @"type": @"evolution",
            @"fromID": from[@"id"] ?: @0,
            @"fromName": from[@"name"] ?: @"",
            @"toID": to[@"id"] ?: @0,
            @"toName": to[@"name"] ?: @"",
            @"condition": [self evolutionConditionText:to],
            @"height": @(DETAIL_EVOLUTION_HEIGHT)
        }];
    }
    [sects addObject:@{@"title": @"Evolution", @"rows": rows}];
}

- (void)buildMoveSections:(NSMutableArray *)sects {
    NSArray *allMoves = self.pokemon.moves;
    if (!allMoves || allMoves.count == 0) return;

    NSMutableArray *levelUp = [[NSMutableArray alloc] init];
    NSMutableArray *machine = [[NSMutableArray alloc] init];
    NSMutableArray *egg = [[NSMutableArray alloc] init];
    NSMutableArray *tutor = [[NSMutableArray alloc] init];
    NSMutableArray *other = [[NSMutableArray alloc] init];

    for (NSDictionary *move in allMoves) {
        NSString *method = move[@"method"] ?: @"";
        if ([method isEqualToString:@"level-up"]) [levelUp addObject:move];
        else if ([method isEqualToString:@"machine"]) [machine addObject:move];
        else if ([method isEqualToString:@"egg"]) [egg addObject:move];
        else if ([method isEqualToString:@"tutor"]) [tutor addObject:move];
        else [other addObject:move];
    }

    NSArray *moveSections = @[
        @[@"Level-Up Moves", levelUp],
        @[@"TM/HM Moves", machine],
        @[@"Egg Moves", egg],
        @[@"Tutor Moves", tutor],
        @[@"Other Moves", other]
    ];

    for (NSArray *ms in moveSections) {
        NSString *title = ms[0];
        NSArray *moves = ms[1];
        if (moves.count == 0) continue;

        NSMutableArray *rows = [[NSMutableArray alloc] init];
        for (NSDictionary *move in moves) {
            [rows addObject:@{
                @"type": @"move",
                @"name": move[@"name"] ?: @"",
                @"level": move[@"level"] ?: @0,
                @"moveType": move[@"type"] ?: @"",
                @"power": move[@"power"] ?: [NSNull null],
                @"accuracy": move[@"accuracy"] ?: [NSNull null],
                @"pp": move[@"pp"] ?: [NSNull null],
                @"height": @(DETAIL_MOVE_HEIGHT)
            }];
        }
        [sects addObject:@{@"title": title, @"rows": rows}];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *section = self.sections[(NSUInteger)indexPath.section];
    NSArray *rows = section[@"rows"];
    NSDictionary *row = rows[(NSUInteger)indexPath.row];
    NSString *type = row[@"type"];

    if ([type isEqualToString:@"flavortext"]) {
        return [self flavorTextCellForRow:row tableView:tableView];
    }
    if ([type isEqualToString:@"statbar"]) {
        static NSString *statID = @"StatBarCell";
        StatBarCell *cell = [tableView dequeueReusableCellWithIdentifier:statID];
        if (!cell) {
            cell = [[StatBarCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:statID];
        }
        [cell configureWithName:row[@"name"] value:[row[@"value"] integerValue]];
        return cell;
    }
    if ([type isEqualToString:@"typegrid"]) {
        static NSString *tgID = @"TypeGridCell";
        TypeGridCell *cell = [tableView dequeueReusableCellWithIdentifier:tgID];
        if (!cell) {
            cell = [[TypeGridCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:tgID];
        }
        [cell configureWithLabel:row[@"label"] types:row[@"types"]];
        return cell;
    }
    if ([type isEqualToString:@"keyvalue"]) {
        static NSString *kvID = @"KeyValueCell";
        KeyValueCell *cell = [tableView dequeueReusableCellWithIdentifier:kvID];
        if (!cell) {
            cell = [[KeyValueCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:kvID];
        }
        if ([row[@"valueFont"] isEqualToString:@"mono"]) {
            UIFont *mono = [UIFont fontWithName:@"Courier-Bold" size:DETAIL_BODY_FONT_SIZE];
            if (!mono) mono = [UIFont boldSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
            [cell configureWithKey:row[@"key"] value:row[@"value"]
                        valueColor:[UIColor darkTextColor] valueFont:mono];
        } else {
            [cell configureWithKey:row[@"key"] value:row[@"value"]];
        }
        return cell;
    }
    if ([type isEqualToString:@"helditem"]) {
        return [self heldItemCellForRow:row tableView:tableView];
    }
    if ([type isEqualToString:@"ability"]) {
        static NSString *abilityID = @"AbilityCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:abilityID];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:abilityID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE];
        }
        cell.textLabel.text = row[@"display"];
        cell.textLabel.textColor = [row[@"isHidden"] boolValue] ?
            [UIColor grayColor] : [UIColor darkTextColor];
        return cell;
    }
    if ([type isEqualToString:@"evolution"]) {
        static NSString *evoID = @"EvolutionCell";
        EvolutionCell *cell = [tableView dequeueReusableCellWithIdentifier:evoID];
        if (!cell) {
            cell = [[EvolutionCell alloc] initWithStyle:UITableViewCellStyleDefault
                                         reuseIdentifier:evoID];
        }
        DataManager *dm = [DataManager sharedManager];
        NSInteger fromID = [row[@"fromID"] integerValue];
        NSInteger toID = [row[@"toID"] integerValue];
        [cell configureWithFromSprite:[dm spriteForPokemonID:fromID]
                             fromName:row[@"fromName"]
                               fromID:fromID
                             toSprite:[dm spriteForPokemonID:toID]
                               toName:row[@"toName"]
                                 toID:toID
                            condition:row[@"condition"]];
        [cell.fromButton addTarget:self action:@selector(evolutionSpriteTapped:)
              forControlEvents:UIControlEventTouchUpInside];
        [cell.toButton addTarget:self action:@selector(evolutionSpriteTapped:)
            forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    if ([type isEqualToString:@"move"]) {
        static NSString *moveID = @"DetailMoveCell";
        DetailMoveCell *cell = [tableView dequeueReusableCellWithIdentifier:moveID];
        if (!cell) {
            cell = [[DetailMoveCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:moveID];
        }
        [cell configureWithName:row[@"name"]
                          level:[row[@"level"] integerValue]
                           type:row[@"moveType"]
                          power:row[@"power"]
                       accuracy:row[@"accuracy"]
                             pp:row[@"pp"]];
        return cell;
    }
    if ([type isEqualToString:@"text"]) {
        static NSString *textID = @"TextBlockCell";
        TextBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:textID];
        if (!cell) {
            cell = [[TextBlockCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:textID];
        }
        [cell configureWithText:row[@"text"]];
        return cell;
    }

    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)flavorTextCellForRow:(NSDictionary *)row
                                tableView:(UITableView *)tableView {
    static NSString *ftID = @"FlavorTextCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ftID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:ftID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *sub in cell.contentView.subviews) [sub removeFromSuperview];

    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat w = cell.contentView.bounds.size.width - pad * 2;
    CGFloat cy = 8;
    NSString *versionStr = row[@"versionStr"];
    NSString *text = row[@"text"];

    if (versionStr.length > 0) {
        UIFont *boldFont = [UIFont boldSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
        CGSize vSize = [versionStr sizeWithFont:boldFont
                              constrainedToSize:CGSizeMake(w, 9999)
                                  lineBreakMode:NSLineBreakByWordWrapping];
        UILabel *vLabel = [[UILabel alloc] initWithFrame:
            CGRectMake(pad, cy, w, vSize.height)];
        vLabel.text = versionStr;
        vLabel.font = boldFont;
        vLabel.textColor = [UIColor colorWithWhite:0.20 alpha:1];
        vLabel.backgroundColor = [UIColor clearColor];
        vLabel.numberOfLines = 0;
        vLabel.lineBreakMode = NSLineBreakByWordWrapping;
        vLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [cell.contentView addSubview:vLabel];
        cy += vSize.height + 2;
    }

    UIFont *italicFont = [UIFont italicSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
    CGSize tSize = [text sizeWithFont:italicFont
                    constrainedToSize:CGSizeMake(w, 9999)
                        lineBreakMode:NSLineBreakByWordWrapping];
    UILabel *tLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(pad, cy, w, tSize.height)];
    tLabel.text = text;
    tLabel.font = italicFont;
    tLabel.textColor = [UIColor colorWithWhite:0.30 alpha:1];
    tLabel.backgroundColor = [UIColor clearColor];
    tLabel.numberOfLines = 0;
    tLabel.lineBreakMode = NSLineBreakByWordWrapping;
    tLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [cell.contentView addSubview:tLabel];

    return cell;
}

- (UITableViewCell *)heldItemCellForRow:(NSDictionary *)row
                              tableView:(UITableView *)tableView {
    static NSString *heldID = @"HeldItemCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:heldID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:heldID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *sub in cell.contentView.subviews) [sub removeFromSuperview];

    DataManager *dm = [DataManager sharedManager];
    NSString *name = row[@"name"];
    NSString *apiName = row[@"api_name"];
    NSInteger rarity = [row[@"rarity"] integerValue];
    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat h = 44;

    UIImage *sprite = [dm spriteForItemName:apiName];
    CGFloat nameX = pad;
    if (sprite) {
        UIImageView *sv = [[UIImageView alloc] initWithFrame:
            CGRectMake(pad, (h - 24) / 2, 24, 24)];
        sv.contentMode = UIViewContentModeScaleAspectFit;
        sv.image = sprite;
        [cell.contentView addSubview:sv];
        nameX = pad + 30;
    }

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(nameX, 0, cell.contentView.bounds.size.width - nameX - 66, h)];
    nameLabel.text = name;
    nameLabel.font = [UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE];
    nameLabel.textColor = [UIColor darkTextColor];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [cell.contentView addSubview:nameLabel];

    UILabel *rarityLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(cell.contentView.bounds.size.width - pad - 50, 0, 50, h)];
    rarityLabel.text = [NSString stringWithFormat:@"%ld%%", (long)rarity];
    rarityLabel.font = [UIFont systemFontOfSize:12];
    rarityLabel.textColor = [UIColor grayColor];
    rarityLabel.textAlignment = NSTextAlignmentRight;
    rarityLabel.backgroundColor = [UIColor clearColor];
    rarityLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [cell.contentView addSubview:rarityLabel];

    return cell;
}

#pragma mark - Evolution Navigation

- (void)evolutionSpriteTapped:(UIButton *)sender {
    NSInteger targetID = sender.tag;
    if (targetID <= 0 || targetID == self.pokemon.pokemonID) return;

    PokemonDetailVC *detailVC = [[PokemonDetailVC alloc] init];
    detailVC.pokemonID = targetID;
    UINavigationController *detailNav = [[UINavigationController alloc]
        initWithRootViewController:detailVC];

    UISplitViewController *splitVC = self.splitViewController;
    if (splitVC) {
        splitVC.viewControllers = @[splitVC.viewControllers[0], detailNav];
    } else {
        [self.navigationController pushViewController:detailVC animated:YES];
    }
}

#pragma mark - Helpers

- (NSString *)titleCase:(NSString *)str {
    if (!str || str.length == 0) return @"\u2014";
    return [[[str substringToIndex:1] uppercaseString]
        stringByAppendingString:[str substringFromIndex:1]];
}

- (NSString *)formatShape:(NSString *)shape {
    if (!shape || shape.length == 0) return @"\u2014";
    NSDictionary *shapeNames = @{
        @"ball": @"Ball", @"squiggle": @"Squiggle", @"fish": @"Fish",
        @"arms": @"Arms", @"blob": @"Blob", @"upright": @"Upright",
        @"legs": @"Legs", @"quadruped": @"Quadruped", @"wings": @"Wings",
        @"tentacles": @"Tentacles", @"heads": @"Multiple Bodies",
        @"humanoid": @"Humanoid", @"bug-wings": @"Bug Wings", @"armor": @"Armor",
    };
    return shapeNames[shape] ?: [self titleCase:shape];
}

- (NSString *)formatGeneration:(NSString *)gen {
    if (!gen || gen.length == 0) return @"\u2014";
    NSString *numeral = [[gen componentsSeparatedByString:@"-"] lastObject];
    return [NSString stringWithFormat:@"Gen %@", [numeral uppercaseString]];
}

- (NSString *)evolutionConditionText:(NSDictionary *)entry {
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    NSString *trigger = entry[@"trigger"] ?: @"";

    id minLevel = entry[@"min_level"];
    if (minLevel && minLevel != [NSNull null] && [minLevel integerValue] > 0) {
        [parts addObject:[NSString stringWithFormat:@"Lv. %@", minLevel]];
    }

    if (entry[@"item"] && entry[@"item"] != [NSNull null])
        [parts addObject:entry[@"item"]];
    if (entry[@"held_item"] && entry[@"held_item"] != [NSNull null])
        [parts addObject:[NSString stringWithFormat:@"Hold %@", entry[@"held_item"]]];
    if (entry[@"known_move"] && entry[@"known_move"] != [NSNull null])
        [parts addObject:[NSString stringWithFormat:@"Know %@", entry[@"known_move"]]];
    if (entry[@"known_move_type"] && entry[@"known_move_type"] != [NSNull null])
        [parts addObject:[NSString stringWithFormat:@"%@ move", entry[@"known_move_type"]]];
    if (entry[@"min_happiness"] && entry[@"min_happiness"] != [NSNull null])
        [parts addObject:@"Happiness"];
    if (entry[@"min_beauty"] && entry[@"min_beauty"] != [NSNull null])
        [parts addObject:@"Beauty"];
    if (entry[@"min_affection"] && entry[@"min_affection"] != [NSNull null])
        [parts addObject:@"Affection"];
    if (entry[@"time_of_day"] && entry[@"time_of_day"] != [NSNull null]) {
        NSString *tod = entry[@"time_of_day"];
        if (tod.length > 0) [parts addObject:[self titleCase:tod]];
    }
    if ([entry[@"needs_overworld_rain"] boolValue]) [parts addObject:@"Rain"];
    if ([entry[@"turn_upside_down"] boolValue]) [parts addObject:@"Upside Down"];
    if (entry[@"trade_species"] && entry[@"trade_species"] != [NSNull null])
        [parts addObject:[NSString stringWithFormat:@"Trade w/ %@", entry[@"trade_species"]]];
    id gender = entry[@"gender"];
    if (gender && gender != [NSNull null]) {
        NSInteger g = [gender integerValue];
        if (g == 1) [parts addObject:@"\u2640"];
        else if (g == 2) [parts addObject:@"\u2642"];
    }

    if ([trigger isEqualToString:@"trade"] && parts.count == 0) [parts addObject:@"Trade"];
    if ([trigger isEqualToString:@"use-item"] && parts.count == 0) [parts addObject:@"Use Item"];
    if ([trigger isEqualToString:@"level-up"] && parts.count == 0) [parts addObject:@"Level Up"];

    if (parts.count == 0) return [self titleCase:trigger];
    return [parts componentsJoinedByString:@", "];
}

- (NSDictionary *)versionDisplayNames {
    return @{
        @"red": @"Red", @"blue": @"Blue", @"yellow": @"Yellow",
        @"gold": @"Gold", @"silver": @"Silver", @"crystal": @"Crystal",
        @"ruby": @"Ruby", @"sapphire": @"Sapphire", @"emerald": @"Emerald",
        @"firered": @"FireRed", @"leafgreen": @"LeafGreen",
        @"diamond": @"Diamond", @"pearl": @"Pearl", @"platinum": @"Platinum",
        @"heartgold": @"HeartGold", @"soulsilver": @"SoulSilver",
        @"black": @"Black", @"white": @"White",
        @"black-2": @"Black 2", @"white-2": @"White 2",
        @"x": @"X", @"y": @"Y",
        @"omega-ruby": @"Omega Ruby", @"alpha-sapphire": @"Alpha Sapphire",
        @"sun": @"Sun", @"moon": @"Moon",
        @"ultra-sun": @"Ultra Sun", @"ultra-moon": @"Ultra Moon",
        @"lets-go-pikachu": @"Let's Go Pikachu",
        @"lets-go-eevee": @"Let's Go Eevee",
        @"sword": @"Sword", @"shield": @"Shield",
        @"legends-arceus": @"Legends: Arceus",
        @"scarlet": @"Scarlet", @"violet": @"Violet",
    };
}

@end
