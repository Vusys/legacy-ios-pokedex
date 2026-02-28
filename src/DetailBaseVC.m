#import "DetailBaseVC.h"
#import "DetailConstants.h"
#import "TexturedBackgroundView.h"
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

    CGSize navSize = CGSizeMake(1, 44);
    UIGraphicsBeginImageContextWithOptions(navSize, YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] = {
        top[0], top[1], top[2], top[3],
        bottom[0], bottom[1], bottom[2], bottom[3]
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
