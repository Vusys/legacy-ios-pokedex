#import <UIKit/UIKit.h>
#import "PokemonListVC.h"
#import "PokemonDetailVC.h"
#import "DataManager.h"

// ─── AppDelegate ────────────────────────────────────────────────────

@interface AppDelegate : UIResponder <UIApplicationDelegate, UISplitViewControllerDelegate>
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UISplitViewController *splitVC;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Master: Pokemon list
    PokemonListVC *listVC = [[PokemonListVC alloc] init];
    UINavigationController *masterNav = [[UINavigationController alloc]
        initWithRootViewController:listVC];

    // Detail: Pokemon detail (start with #1 Bulbasaur)
    PokemonDetailVC *detailVC = [[PokemonDetailVC alloc] init];
    detailVC.pokemonID = 1;
    UINavigationController *detailNav = [[UINavigationController alloc]
        initWithRootViewController:detailVC];

    // Split view
    self.splitVC = [[UISplitViewController alloc] init];
    self.splitVC.viewControllers = @[masterNav, detailNav];
    self.splitVC.delegate = self;

    // Give master a reference for updating detail
    listVC.detailNavigationController = detailNav;

    self.window.rootViewController = self.splitVC;
    [self.window makeKeyAndVisible];
    return YES;
}

// Always show the master pane
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
