#import "PokedexTabBarController.h"

static NSString *const kTabOrderKey = @"PokedexTabOrder";

@interface PokedexTabBarController () <UITabBarDelegate>
@property (nonatomic, strong) UITabBar *tabBar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSArray *childViewControllerList;
@property (nonatomic, weak) UIViewController *currentChild;
@property (nonatomic, strong) NSArray *pendingViewControllers;
@end

@implementation PokedexTabBarController

#pragma mark - Setup

- (void)setChildViewControllers:(NSArray *)viewControllers {
    // Apply saved tab order if available
    NSArray *savedOrder = [[NSUserDefaults standardUserDefaults] arrayForKey:kTabOrderKey];
    if (savedOrder.count == viewControllers.count) {
        NSMutableArray *reordered = [[NSMutableArray alloc] initWithCapacity:viewControllers.count];
        BOOL valid = YES;
        for (NSNumber *tagNum in savedOrder) {
            NSInteger tag = [tagNum integerValue];
            UIViewController *found = nil;
            for (UIViewController *vc in viewControllers) {
                if (vc.tabBarItem.tag == tag) {
                    found = vc;
                    break;
                }
            }
            if (found) {
                [reordered addObject:found];
            } else {
                valid = NO;
                break;
            }
        }
        if (valid && reordered.count == viewControllers.count) {
            viewControllers = reordered;
        }
    }

    if ([self isViewLoaded]) {
        [self applyViewControllers:viewControllers];
    } else {
        self.pendingViewControllers = viewControllers;
    }
}

- (void)applyViewControllers:(NSArray *)viewControllers {
    // Remove any previously added children
    if (self.currentChild) {
        [self.currentChild willMoveToParentViewController:nil];
        [self.currentChild.view removeFromSuperview];
        [self.currentChild removeFromParentViewController];
        self.currentChild = nil;
    }

    _childViewControllerList = [viewControllers copy];

    // Build tab bar items
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:viewControllers.count];
    for (UIViewController *vc in viewControllers) {
        if (vc.tabBarItem) {
            [items addObject:vc.tabBarItem];
        }
    }

    [self.tabBar setItems:items animated:NO];

    // Select first tab
    if (viewControllers.count > 0) {
        self.tabBar.selectedItem = items[0];
        [self transitionToChildAtIndex:0];
    }
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    // Content area fills above tab bar
    self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.contentView];

    // Tab bar at bottom
    self.tabBar = [[UITabBar alloc] initWithFrame:CGRectZero];
    self.tabBar.delegate = self;
    [self.view addSubview:self.tabBar];

    // Long-press for edit mode
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(longPressOnTabBar:)];
    [self.tabBar addGestureRecognizer:longPress];

    [self layoutFrames];

    // Apply pending VCs that were set before view loaded
    if (self.pendingViewControllers) {
        [self applyViewControllers:self.pendingViewControllers];
        self.pendingViewControllers = nil;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutFrames];
}

- (void)layoutFrames {
    CGRect bounds = self.view.bounds;
    CGFloat tabBarHeight = 49.0;

    self.tabBar.frame = CGRectMake(0, bounds.size.height - tabBarHeight,
                                    bounds.size.width, tabBarHeight);
    self.contentView.frame = CGRectMake(0, 0,
                                         bounds.size.width,
                                         bounds.size.height - tabBarHeight);

    if (self.currentChild) {
        self.currentChild.view.frame = self.contentView.bounds;
    }
}

#pragma mark - Tab Switching

- (void)transitionToChildAtIndex:(NSUInteger)index {
    if (index >= self.childViewControllerList.count) return;

    UIViewController *newChild = self.childViewControllerList[index];
    if (newChild == self.currentChild) return;

    // Remove current child
    if (self.currentChild) {
        [self.currentChild willMoveToParentViewController:nil];
        [self.currentChild.view removeFromSuperview];
        [self.currentChild removeFromParentViewController];
    }

    // Add new child
    [self addChildViewController:newChild];
    newChild.view.frame = self.contentView.bounds;
    newChild.view.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:newChild.view];
    [newChild didMoveToParentViewController:self];

    self.currentChild = newChild;
    _selectedIndex = index;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (selectedIndex >= self.childViewControllerList.count) return;
    _selectedIndex = selectedIndex;

    UIViewController *vc = self.childViewControllerList[selectedIndex];
    UITabBarItem *item = vc.tabBarItem;
    self.tabBar.selectedItem = item;

    [self transitionToChildAtIndex:selectedIndex];
}

- (void)selectTabWithTag:(NSInteger)tag {
    for (NSUInteger i = 0; i < self.childViewControllerList.count; i++) {
        UIViewController *vc = self.childViewControllerList[i];
        if (vc.tabBarItem.tag == tag) {
            self.selectedIndex = i;
            return;
        }
    }
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    for (NSUInteger i = 0; i < self.childViewControllerList.count; i++) {
        UIViewController *vc = self.childViewControllerList[i];
        if (vc.tabBarItem == item) {
            [self transitionToChildAtIndex:i];
            return;
        }
    }
}

- (void)tabBar:(UITabBar *)tabBar didEndCustomizingItems:(NSArray *)items
       changed:(BOOL)changed {
    if (!changed) return;

    // Rebuild child order from the new item order
    NSMutableArray *reordered = [[NSMutableArray alloc]
        initWithCapacity:self.childViewControllerList.count];
    NSMutableArray *tagOrder = [[NSMutableArray alloc]
        initWithCapacity:items.count];

    for (UITabBarItem *item in items) {
        [tagOrder addObject:@(item.tag)];
        for (UIViewController *vc in self.childViewControllerList) {
            if (vc.tabBarItem == item) {
                [reordered addObject:vc];
                break;
            }
        }
    }

    if (reordered.count == self.childViewControllerList.count) {
        _childViewControllerList = reordered;
        [[NSUserDefaults standardUserDefaults] setObject:tagOrder forKey:kTabOrderKey];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // Update selected index to match the current child's new position
        if (self.currentChild) {
            NSUInteger newIdx = [reordered indexOfObject:self.currentChild];
            if (newIdx != NSNotFound) {
                _selectedIndex = newIdx;
            }
        }
    }
}

#pragma mark - Long Press for Edit Mode

- (void)longPressOnTabBar:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSMutableArray *items = [[NSMutableArray alloc] init];
        for (UIViewController *vc in self.childViewControllerList) {
            [items addObject:vc.tabBarItem];
        }
        [self.tabBar beginCustomizingItems:items];
    }
}

#pragma mark - Rotation (iOS 6)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

@end
