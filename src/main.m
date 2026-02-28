#import <UIKit/UIKit.h>
#import "PokemonListVC.h"
#import "PokemonDetailVC.h"
#import "MoveListVC.h"
#import "MoveDetailVC.h"
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

    // ─── Tab Bar ────────────────────────────────────────────
    UITabBarController *tabBar = [[UITabBarController alloc] init];
    tabBar.viewControllers = @[pokedexSplit, movesSplit];

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
