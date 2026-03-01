#import "DetailBaseVC.h"
#import "DetailConstants.h"
#import "TexturedBackgroundView.h"
#import "DataManager.h"
#import "NavBarStyle.h"
#import <QuartzCore/QuartzCore.h>

@implementation DetailBaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lastBuiltWidth = 0;

    NSLog(@"[DEBUG] %@ viewDidLoad: view.bounds=%@ ", NSStringFromClass([self class]),
          NSStringFromCGRect(self.view.bounds));

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                  style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.backgroundView = [[TexturedBackgroundView alloc]
        initWithFrame:self.tableView.bounds];
    [self.view addSubview:self.tableView];

    NSLog(@"[DEBUG] %@ viewDidLoad: tableView.bounds=%@",
          NSStringFromClass([self class]), NSStringFromCGRect(self.tableView.bounds));

    [self styleNavBar];
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
    CGFloat w = self.tableView.bounds.size.width;
    if (w > 0 && w != self.lastBuiltWidth) {
        NSLog(@"[DEBUG] %@ viewDidLayoutSubviews: width %.0f -> %.0f (hasData=%d)",
              NSStringFromClass([self class]), self.lastBuiltWidth, w, [self hasData]);
        self.lastBuiltWidth = w;
        if ([self hasData]) {
            [self buildSections];
            [self setupHeaderView];
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Empty State

- (BOOL)hasData {
    return NO; // Subclasses override
}

- (void)showEmptyState {
    if (!self.emptyLabel) {
        self.emptyLabel = [[UILabel alloc] init];
        self.emptyLabel.textAlignment = NSTextAlignmentCenter;
        self.emptyLabel.font = [UIFont systemFontOfSize:18];
        self.emptyLabel.textColor = [UIColor grayColor];
        self.emptyLabel.backgroundColor = [UIColor clearColor];
        self.emptyLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    self.emptyLabel.text = [self emptyStateText];
    self.emptyLabel.frame = CGRectMake(0, 100, self.view.bounds.size.width, 40);
    self.tableView.tableHeaderView = self.emptyLabel;
    self.sections = @[];
    [self.tableView reloadData];
}

#pragma mark - Nav Bar

- (void)styleNavBar {
    CGFloat top[4] = {0, 0, 0, 1};
    CGFloat bottom[4] = {0, 0, 0, 1};
    [self navBarGradientTopColor:top bottomColor:bottom];

    UIImage *navImage = NavBarGradientImage(top[0], top[1], top[2],
                                              bottom[0], bottom[1], bottom[2]);

    [self.navigationController.navigationBar setBackgroundImage:navImage
        forBarMetrics:UIBarMetricsDefault];

    self.navigationController.navigationBar.titleTextAttributes = @{
        UITextAttributeTextColor: [UIColor whiteColor],
        UITextAttributeTextShadowColor: [UIColor colorWithWhite:0 alpha:0.6],
        UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
        UITextAttributeFont: [UIFont boldSystemFontOfSize:20]
    };
}

- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom {
    // Subclasses override
}

- (NSString *)emptyStateText {
    return @"Select an item";
}

#pragma mark - Sections

- (void)buildSections {
    // Subclasses override
}

- (void)setupHeaderView {
    // Subclasses override
}

#pragma mark - Favourites

- (NSString *)favouriteEntityType {
    return nil;
}

- (NSInteger)favouriteEntityID {
    return 0;
}

- (void)setupFavouriteButton {
    NSString *type = [self favouriteEntityType];
    NSInteger eid = [self favouriteEntityID];
    if (!type || eid <= 0) return;

    [self updateFavouriteButtonIcon];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(favouritesDidChange:)
               name:FavouritesChangedNotification
             object:nil];
}

- (void)updateFavouriteButtonIcon {
    BOOL isFav = [[DataManager sharedManager]
        isFavourite:[self favouriteEntityID] type:[self favouriteEntityType]];
    UIImage *heartImage = [self heartImageFilled:isFav size:24];
    UIBarButtonItem *btn = [[UIBarButtonItem alloc]
        initWithImage:heartImage
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(toggleFavourite)];
    self.navigationItem.rightBarButtonItem = btn;
}

- (void)toggleFavourite {
    [[DataManager sharedManager]
        toggleFavourite:[self favouriteEntityID] type:[self favouriteEntityType]];
    [self updateFavouriteButtonIcon];
}

- (void)favouritesDidChange:(NSNotification *)note {
    NSString *type = note.userInfo[@"type"];
    NSNumber *eid = note.userInfo[@"id"];
    if ([type isEqualToString:[self favouriteEntityType]] &&
        [eid integerValue] == [self favouriteEntityID]) {
        [self updateFavouriteButtonIcon];
    }
}

- (UIImage *)heartImageFilled:(BOOL)filled size:(CGFloat)size {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGFloat inset = size * 0.04;
    CGFloat topY = size * 0.30;
    CGFloat botY = size - inset;
    CGFloat midX = size / 2.0;

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, midX, botY);
    // Left half
    CGPathAddCurveToPoint(path, NULL,
        inset, size * 0.62,
        inset, topY - size * 0.12,
        midX, topY);
    // Right half
    CGPathAddCurveToPoint(path, NULL,
        size - inset, topY - size * 0.12,
        size - inset, size * 0.62,
        midX, botY);
    CGPathCloseSubpath(path);

    if (filled) {
        [[UIColor colorWithRed:0.90 green:0.25 blue:0.30 alpha:1] setFill];
        CGContextAddPath(ctx, path);
        CGContextFillPath(ctx);
    } else {
        [[UIColor colorWithWhite:0.55 alpha:1] setStroke];
        CGContextSetLineWidth(ctx, 1.5);
        CGContextAddPath(ctx, path);
        CGContextStrokePath(ctx);
    }
    CGPathRelease(path);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *s = self.sections[(NSUInteger)section];
    NSArray *rows = s[@"rows"];
    return (NSInteger)rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *s = self.sections[(NSUInteger)section];
    return s[@"title"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Subclasses override for custom cell dequeuing
    UITableViewCell *cell = [[UITableViewCell alloc]
        initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *s = self.sections[(NSUInteger)indexPath.section];
    NSArray *rows = s[@"rows"];
    NSDictionary *row = rows[(NSUInteger)indexPath.row];
    NSNumber *height = row[@"height"];
    if (height) return [height floatValue];
    return DETAIL_ROW_HEIGHT;
}

@end
