#import <UIKit/UIKit.h>
#import "PokemonListVC.h"
#import "PokemonDetailVC.h"
#import "MoveListVC.h"
#import "MoveDetailVC.h"
#import "AbilityListVC.h"
#import "AbilityDetailVC.h"
#import "ItemListVC.h"
#import "ItemDetailVC.h"
#import "DataManager.h"

// ─── AppDelegate ────────────────────────────────────────────────────

@interface AppDelegate : UIResponder <UIApplicationDelegate, UISplitViewControllerDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation AppDelegate

// Draw a Pokéball silhouette for the tab bar (30x30 alpha mask)
- (UIImage *)pokeballIcon {
    CGFloat size = 30;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    UIColor *fill = [UIColor whiteColor];
    [fill setFill];
    [fill setStroke];
    CGContextSetLineWidth(ctx, 1.5);

    // Outer circle
    CGRect ballRect = CGRectInset(CGRectMake(0, 0, size, size), 2, 2);
    CGContextStrokeEllipseInRect(ctx, ballRect);

    // Horizontal line through middle
    CGFloat midY = size / 2.0;
    CGContextMoveToPoint(ctx, 2, midY);
    CGContextAddLineToPoint(ctx, size - 2, midY);
    CGContextStrokePath(ctx);

    // Center circle (filled)
    CGFloat centerR = 4;
    CGRect centerRect = CGRectMake(size/2 - centerR, midY - centerR, centerR*2, centerR*2);
    CGContextFillEllipseInRect(ctx, centerRect);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

// Draw a sword silhouette for the Moves tab (30x30 alpha mask)
- (UIImage *)swordIcon {
    CGFloat size = 30;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [[UIColor whiteColor] setStroke];
    [[UIColor whiteColor] setFill];
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetLineCap(ctx, kCGLineCapRound);

    // Blade (diagonal from top-right to center)
    CGContextMoveToPoint(ctx, 23, 3);
    CGContextAddLineToPoint(ctx, 11, 15);
    CGContextStrokePath(ctx);

    // Blade tip serifs
    CGContextMoveToPoint(ctx, 23, 3);
    CGContextAddLineToPoint(ctx, 19, 4);
    CGContextStrokePath(ctx);
    CGContextMoveToPoint(ctx, 23, 3);
    CGContextAddLineToPoint(ctx, 22, 7);
    CGContextStrokePath(ctx);

    // Cross guard
    CGContextSetLineWidth(ctx, 2.5);
    CGContextMoveToPoint(ctx, 7, 13);
    CGContextAddLineToPoint(ctx, 15, 19);
    CGContextStrokePath(ctx);

    // Handle
    CGContextSetLineWidth(ctx, 2.5);
    CGContextMoveToPoint(ctx, 11, 15);
    CGContextAddLineToPoint(ctx, 6, 24);
    CGContextStrokePath(ctx);

    // Pommel
    CGContextFillEllipseInRect(ctx, CGRectMake(4, 22, 4, 4));

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

// Draw a star silhouette for the Abilities tab (30x30 alpha mask)
- (UIImage *)abilitiesIcon {
    CGFloat size = 30;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [[UIColor whiteColor] setFill];
    [[UIColor whiteColor] setStroke];
    CGContextSetLineWidth(ctx, 1.5);

    // 5-pointed star
    CGFloat cx = size / 2.0;
    CGFloat cy = size / 2.0;
    CGFloat outerR = 12;
    CGFloat innerR = 5;

    CGMutablePathRef path = CGPathCreateMutable();
    for (int i = 0; i < 10; i++) {
        CGFloat r = (i % 2 == 0) ? outerR : innerR;
        CGFloat angle = (M_PI / 2.0) + (i * M_PI / 5.0);
        CGFloat x = cx + r * cos(angle);
        CGFloat y2 = cy - r * sin(angle);
        if (i == 0) {
            CGPathMoveToPoint(path, NULL, x, y2);
        } else {
            CGPathAddLineToPoint(path, NULL, x, y2);
        }
    }
    CGPathCloseSubpath(path);

    CGContextAddPath(ctx, path);
    CGContextFillPath(ctx);
    CGPathRelease(path);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

// Draw a bag/backpack silhouette for the Items tab (30x30 alpha mask)
- (UIImage *)itemsIcon {
    CGFloat size = 30;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [[UIColor whiteColor] setFill];
    [[UIColor whiteColor] setStroke];
    CGContextSetLineWidth(ctx, 1.5);

    // Bag handle
    CGContextStrokeEllipseInRect(ctx, CGRectMake(9, 2, 12, 10));

    // Bag body (rounded rect)
    CGFloat bodyX = 5;
    CGFloat bodyY = 10;
    CGFloat bodyW = 20;
    CGFloat bodyH = 16;
    CGFloat r = 3;

    CGContextMoveToPoint(ctx, bodyX + r, bodyY);
    CGContextAddLineToPoint(ctx, bodyX + bodyW - r, bodyY);
    CGContextAddArcToPoint(ctx, bodyX + bodyW, bodyY, bodyX + bodyW, bodyY + r, r);
    CGContextAddLineToPoint(ctx, bodyX + bodyW, bodyY + bodyH - r);
    CGContextAddArcToPoint(ctx, bodyX + bodyW, bodyY + bodyH, bodyX + bodyW - r, bodyY + bodyH, r);
    CGContextAddLineToPoint(ctx, bodyX + r, bodyY + bodyH);
    CGContextAddArcToPoint(ctx, bodyX, bodyY + bodyH, bodyX, bodyY + bodyH - r, r);
    CGContextAddLineToPoint(ctx, bodyX, bodyY + r);
    CGContextAddArcToPoint(ctx, bodyX, bodyY, bodyX + r, bodyY, r);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);

    // Clasp/stripe
    CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.3);
    CGContextFillRect(ctx, CGRectMake(bodyX + 2, bodyY + 6, bodyW - 4, 3));

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // ─── Tab 1: Pokédex (split view) ────────────────────────
    PokemonListVC *pokedexList = [[PokemonListVC alloc] init];
    UINavigationController *pokedexMasterNav = [[UINavigationController alloc]
        initWithRootViewController:pokedexList];

    PokemonDetailVC *pokedexDetail = [[PokemonDetailVC alloc] init];
    pokedexDetail.pokemonID = 1;
    UINavigationController *pokedexDetailNav = [[UINavigationController alloc]
        initWithRootViewController:pokedexDetail];

    UISplitViewController *pokedexSplit = [[UISplitViewController alloc] init];
    pokedexSplit.viewControllers = @[pokedexMasterNav, pokedexDetailNav];
    pokedexSplit.delegate = self;
    pokedexSplit.title = @"Pokédex";
    pokedexSplit.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Pokédex"
        image:[self pokeballIcon] tag:0];

    // ─── Tab 2: Moves (split view) ──────────────────────────
    MoveListVC *moveList = [[MoveListVC alloc] init];
    UINavigationController *moveMasterNav = [[UINavigationController alloc]
        initWithRootViewController:moveList];

    MoveDetailVC *moveDetail = [[MoveDetailVC alloc] init];
    moveDetail.moveID = 1;
    UINavigationController *moveDetailNav = [[UINavigationController alloc]
        initWithRootViewController:moveDetail];

    UISplitViewController *movesSplit = [[UISplitViewController alloc] init];
    movesSplit.viewControllers = @[moveMasterNav, moveDetailNav];
    movesSplit.delegate = self;
    movesSplit.title = @"Moves";
    movesSplit.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Moves"
        image:[self swordIcon] tag:1];

    // ─── Tab 3: Abilities (split view) ─────────────────────
    AbilityListVC *abilityList = [[AbilityListVC alloc] init];
    UINavigationController *abilityMasterNav = [[UINavigationController alloc]
        initWithRootViewController:abilityList];

    AbilityDetailVC *abilityDetail = [[AbilityDetailVC alloc] init];
    UINavigationController *abilityDetailNav = [[UINavigationController alloc]
        initWithRootViewController:abilityDetail];

    UISplitViewController *abilitiesSplit = [[UISplitViewController alloc] init];
    abilitiesSplit.viewControllers = @[abilityMasterNav, abilityDetailNav];
    abilitiesSplit.delegate = self;
    abilitiesSplit.title = @"Abilities";
    abilitiesSplit.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Abilities"
        image:[self abilitiesIcon] tag:2];

    // ─── Tab 4: Items (split view) ──────────────────────
    ItemListVC *itemList = [[ItemListVC alloc] init];
    UINavigationController *itemMasterNav = [[UINavigationController alloc]
        initWithRootViewController:itemList];

    ItemDetailVC *itemDetail = [[ItemDetailVC alloc] init];
    UINavigationController *itemDetailNav = [[UINavigationController alloc]
        initWithRootViewController:itemDetail];

    UISplitViewController *itemsSplit = [[UISplitViewController alloc] init];
    itemsSplit.viewControllers = @[itemMasterNav, itemDetailNav];
    itemsSplit.delegate = self;
    itemsSplit.title = @"Items";
    itemsSplit.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Items"
        image:[self itemsIcon] tag:3];

    // ─── Tab Bar ────────────────────────────────────────────
    UITabBarController *tabBar = [[UITabBarController alloc] init];
    tabBar.viewControllers = @[pokedexSplit, movesSplit, abilitiesSplit, itemsSplit];

    self.window.rootViewController = tabBar;
    [self.window makeKeyAndVisible];
    return YES;
}

// Always show the master pane in split views
- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}

@end

// ─── Main ───────────────────────────────────────────────────────────

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
            NSStringFromClass([AppDelegate class]));
    }
}
