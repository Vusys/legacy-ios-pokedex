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
        image:nil tag:0];

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
        image:nil tag:1];

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
