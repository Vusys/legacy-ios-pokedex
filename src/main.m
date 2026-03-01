#import <UIKit/UIKit.h>
#import "HomeVC.h"
#import "PokemonListVC.h"
#import "PokemonDetailVC.h"
#import "MoveListVC.h"
#import "MoveDetailVC.h"
#import "AbilityListVC.h"
#import "AbilityDetailVC.h"
#import "ItemCategoryListVC.h"
#import "ItemListVC.h"
#import "ItemDetailVC.h"
#import "NatureListVC.h"
#import "NatureDetailVC.h"
#import "PokedexTabBarController.h"
#import "BerryListVC.h"
#import "BerryDetailVC.h"
#import "RegionListVC.h"
#import "LocationDetailVC.h"
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

// Draw an 8-pointed starburst for the Moves tab (30x30 alpha mask)
- (UIImage *)movesIcon {
    CGFloat size = 30;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [[UIColor whiteColor] setFill];

    CGFloat cx = size / 2.0;
    CGFloat cy = size / 2.0;
    CGFloat outerR = 13;
    CGFloat innerR = 7;
    NSInteger points = 8;

    CGMutablePathRef path = CGPathCreateMutable();
    for (int i = 0; i < points * 2; i++) {
        CGFloat r = (i % 2 == 0) ? outerR : innerR;
        CGFloat angle = (M_PI / 2.0) + (i * M_PI / points);
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

// Draw a house silhouette for the Home tab (30x30 alpha mask)
- (UIImage *)homeIcon {
    CGFloat size = 30;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [[UIColor whiteColor] setFill];

    // Roof (triangle)
    CGMutablePathRef roof = CGPathCreateMutable();
    CGPathMoveToPoint(roof, NULL, 15, 2);
    CGPathAddLineToPoint(roof, NULL, 27, 14);
    CGPathAddLineToPoint(roof, NULL, 3, 14);
    CGPathCloseSubpath(roof);
    CGContextAddPath(ctx, roof);
    CGContextFillPath(ctx);
    CGPathRelease(roof);

    // Body (rectangle)
    CGContextFillRect(ctx, CGRectMake(6, 14, 18, 14));

    // Door cutout
    CGContextSetBlendMode(ctx, kCGBlendModeClear);
    CGContextFillRect(ctx, CGRectMake(12, 19, 7, 9));

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

// Draw up/down arrows for the Natures tab (30x30 alpha mask)
- (UIImage *)naturesIcon {
    CGFloat size = 30;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [[UIColor whiteColor] setStroke];
    [[UIColor whiteColor] setFill];
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);

    // Up arrow (left side) — stat increase
    CGContextMoveToPoint(ctx, 8, 12);
    CGContextAddLineToPoint(ctx, 8, 4);
    CGContextStrokePath(ctx);
    // Arrowhead
    CGContextMoveToPoint(ctx, 4, 8);
    CGContextAddLineToPoint(ctx, 8, 4);
    CGContextAddLineToPoint(ctx, 12, 8);
    CGContextStrokePath(ctx);

    // Down arrow (right side) — stat decrease
    CGContextMoveToPoint(ctx, 22, 18);
    CGContextAddLineToPoint(ctx, 22, 26);
    CGContextStrokePath(ctx);
    // Arrowhead
    CGContextMoveToPoint(ctx, 18, 22);
    CGContextAddLineToPoint(ctx, 22, 26);
    CGContextAddLineToPoint(ctx, 26, 22);
    CGContextStrokePath(ctx);

    // Horizontal divider
    CGContextSetLineWidth(ctx, 1.5);
    CGContextMoveToPoint(ctx, 3, 15);
    CGContextAddLineToPoint(ctx, 27, 15);
    CGContextStrokePath(ctx);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

// Draw a berry/fruit silhouette for the Berries tab (30x30 alpha mask)
- (UIImage *)berriesIcon {
    CGFloat size = 30;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [[UIColor whiteColor] setFill];
    [[UIColor whiteColor] setStroke];

    // Berry body (round)
    CGContextFillEllipseInRect(ctx, CGRectMake(6, 10, 18, 18));

    // Stem
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextMoveToPoint(ctx, 15, 10);
    CGContextAddLineToPoint(ctx, 15, 5);
    CGContextStrokePath(ctx);

    // Left leaf
    CGMutablePathRef leaf1 = CGPathCreateMutable();
    CGPathMoveToPoint(leaf1, NULL, 15, 6);
    CGPathAddCurveToPoint(leaf1, NULL, 11, 3, 7, 3, 7, 6);
    CGPathAddCurveToPoint(leaf1, NULL, 7, 8, 12, 7, 15, 6);
    CGPathCloseSubpath(leaf1);
    CGContextAddPath(ctx, leaf1);
    CGContextFillPath(ctx);
    CGPathRelease(leaf1);

    // Right leaf
    CGMutablePathRef leaf2 = CGPathCreateMutable();
    CGPathMoveToPoint(leaf2, NULL, 15, 6);
    CGPathAddCurveToPoint(leaf2, NULL, 19, 3, 23, 3, 23, 6);
    CGPathAddCurveToPoint(leaf2, NULL, 23, 8, 18, 7, 15, 6);
    CGPathCloseSubpath(leaf2);
    CGContextAddPath(ctx, leaf2);
    CGContextFillPath(ctx);
    CGPathRelease(leaf2);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

// Draw a map pin silhouette for the Locations tab (30x30 alpha mask)
- (UIImage *)locationsIcon {
    CGFloat size = 30;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [[UIColor whiteColor] setFill];
    [[UIColor whiteColor] setStroke];

    CGFloat cx = size / 2.0;

    // Pin head (circle)
    CGFloat headR = 8;
    CGContextFillEllipseInRect(ctx, CGRectMake(cx - headR, 3, headR * 2, headR * 2));

    // Pin point (triangle below the circle)
    CGMutablePathRef point = CGPathCreateMutable();
    CGPathMoveToPoint(point, NULL, cx - 6, 14);
    CGPathAddLineToPoint(point, NULL, cx, 27);
    CGPathAddLineToPoint(point, NULL, cx + 6, 14);
    CGPathCloseSubpath(point);
    CGContextAddPath(ctx, point);
    CGContextFillPath(ctx);
    CGPathRelease(point);

    // Inner circle cutout (to make a ring effect)
    CGContextSetBlendMode(ctx, kCGBlendModeClear);
    CGFloat innerR = 3.5;
    CGContextFillEllipseInRect(ctx, CGRectMake(cx - innerR, 3 + headR - innerR,
                                                innerR * 2, innerR * 2));

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    BOOL isiPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);

    // ─── Tab 1: Pokédex ─────────────────────────────────────
    PokemonListVC *pokedexList = [[PokemonListVC alloc] init];
    UIViewController *pokedexTab;

    if (isiPad) {
        UINavigationController *pokedexMasterNav = [[UINavigationController alloc]
            initWithRootViewController:pokedexList];
        PokemonDetailVC *pokedexDetail = [[PokemonDetailVC alloc] init];
        pokedexDetail.pokemonID = 1;
        UINavigationController *pokedexDetailNav = [[UINavigationController alloc]
            initWithRootViewController:pokedexDetail];
        UISplitViewController *pokedexSplit = [[UISplitViewController alloc] init];
        pokedexSplit.viewControllers = @[pokedexMasterNav, pokedexDetailNav];
        pokedexSplit.delegate = self;
        pokedexSplit.title = @"Pok\u00e9mon";
        pokedexSplit.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Pok\u00e9mon"
            image:[self pokeballIcon] tag:1];
        pokedexTab = pokedexSplit;
    } else {
        UINavigationController *pokedexNav = [[UINavigationController alloc]
            initWithRootViewController:pokedexList];
        pokedexNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Pok\u00e9mon"
            image:[self pokeballIcon] tag:1];
        pokedexTab = pokedexNav;
    }

    // ─── Tab 2: Moves ───────────────────────────────────────
    MoveListVC *moveList = [[MoveListVC alloc] init];
    UIViewController *movesTab;

    if (isiPad) {
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
            image:[self movesIcon] tag:2];
        movesTab = movesSplit;
    } else {
        UINavigationController *movesNav = [[UINavigationController alloc]
            initWithRootViewController:moveList];
        movesNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Moves"
            image:[self movesIcon] tag:2];
        movesTab = movesNav;
    }

    // ─── Tab 3: Abilities ───────────────────────────────────
    AbilityListVC *abilityList = [[AbilityListVC alloc] init];
    UIViewController *abilitiesTab;

    if (isiPad) {
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
            image:[self abilitiesIcon] tag:3];
        abilitiesTab = abilitiesSplit;
    } else {
        UINavigationController *abilitiesNav = [[UINavigationController alloc]
            initWithRootViewController:abilityList];
        abilitiesNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Abilities"
            image:[self abilitiesIcon] tag:3];
        abilitiesTab = abilitiesNav;
    }

    // ─── Tab 4: Locations ─────────────────────────────────
    RegionListVC *regionList = [[RegionListVC alloc] init];
    UIViewController *locationsTab;

    if (isiPad) {
        UINavigationController *locationMasterNav = [[UINavigationController alloc]
            initWithRootViewController:regionList];
        LocationDetailVC *locationDetail = [[LocationDetailVC alloc] init];
        UINavigationController *locationDetailNav = [[UINavigationController alloc]
            initWithRootViewController:locationDetail];
        UISplitViewController *locationsSplit = [[UISplitViewController alloc] init];
        locationsSplit.viewControllers = @[locationMasterNav, locationDetailNav];
        locationsSplit.delegate = self;
        locationsSplit.title = @"Locations";
        locationsSplit.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Locations"
            image:[self locationsIcon] tag:4];
        locationsTab = locationsSplit;
    } else {
        UINavigationController *locationsNav = [[UINavigationController alloc]
            initWithRootViewController:regionList];
        locationsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Locations"
            image:[self locationsIcon] tag:4];
        locationsTab = locationsNav;
    }

    // ─── Tab 5: Items ───────────────────────────────────────
    ItemCategoryListVC *itemCategoryList = [[ItemCategoryListVC alloc] init];
    UIViewController *itemsTab;

    if (isiPad) {
        UINavigationController *itemMasterNav = [[UINavigationController alloc]
            initWithRootViewController:itemCategoryList];
        ItemDetailVC *itemDetail = [[ItemDetailVC alloc] init];
        UINavigationController *itemDetailNav = [[UINavigationController alloc]
            initWithRootViewController:itemDetail];
        UISplitViewController *itemsSplit = [[UISplitViewController alloc] init];
        itemsSplit.viewControllers = @[itemMasterNav, itemDetailNav];
        itemsSplit.delegate = self;
        itemsSplit.title = @"Items";
        itemsSplit.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Items"
            image:[self itemsIcon] tag:5];
        itemsTab = itemsSplit;
    } else {
        UINavigationController *itemsNav = [[UINavigationController alloc]
            initWithRootViewController:itemCategoryList];
        itemsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Items"
            image:[self itemsIcon] tag:5];
        itemsTab = itemsNav;
    }

    // ─── Tab 6: Berries ─────────────────────────────────────
    BerryListVC *berryList = [[BerryListVC alloc] init];
    UIViewController *berriesTab;

    if (isiPad) {
        UINavigationController *berryMasterNav = [[UINavigationController alloc]
            initWithRootViewController:berryList];
        BerryDetailVC *berryDetail = [[BerryDetailVC alloc] init];
        UINavigationController *berryDetailNav = [[UINavigationController alloc]
            initWithRootViewController:berryDetail];
        UISplitViewController *berriesSplit = [[UISplitViewController alloc] init];
        berriesSplit.viewControllers = @[berryMasterNav, berryDetailNav];
        berriesSplit.delegate = self;
        berriesSplit.title = @"Berries";
        berriesSplit.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Berries"
            image:[self berriesIcon] tag:6];
        berriesTab = berriesSplit;
    } else {
        UINavigationController *berriesNav = [[UINavigationController alloc]
            initWithRootViewController:berryList];
        berriesNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Berries"
            image:[self berriesIcon] tag:6];
        berriesTab = berriesNav;
    }

    // ─── Tab 7: Natures ─────────────────────────────────────
    NatureListVC *natureList = [[NatureListVC alloc] init];
    UIViewController *naturesTab;

    if (isiPad) {
        UINavigationController *natureMasterNav = [[UINavigationController alloc]
            initWithRootViewController:natureList];
        NatureDetailVC *natureDetail = [[NatureDetailVC alloc] init];
        UINavigationController *natureDetailNav = [[UINavigationController alloc]
            initWithRootViewController:natureDetail];
        UISplitViewController *naturesSplit = [[UISplitViewController alloc] init];
        naturesSplit.viewControllers = @[natureMasterNav, natureDetailNav];
        naturesSplit.delegate = self;
        naturesSplit.title = @"Natures";
        naturesSplit.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Natures"
            image:[self naturesIcon] tag:7];
        naturesTab = naturesSplit;
    } else {
        UINavigationController *naturesNav = [[UINavigationController alloc]
            initWithRootViewController:natureList];
        naturesNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Natures"
            image:[self naturesIcon] tag:7];
        naturesTab = naturesNav;
    }

    // ─── Tab 0: Home ───────────────────────────────────────
    HomeVC *homeVC = [[HomeVC alloc] init];
    UINavigationController *homeNav = [[UINavigationController alloc]
        initWithRootViewController:homeVC];
    homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Home"
        image:[self homeIcon] tag:0];

    // ─── Tab Bar ────────────────────────────────────────────
    NSArray *allTabs = @[homeNav, pokedexTab, movesTab, abilitiesTab,
        locationsTab, itemsTab, berriesTab, naturesTab];

    if (isiPad) {
        PokedexTabBarController *tabBar = [[PokedexTabBarController alloc] init];
        [tabBar setChildViewControllers:allTabs];
        self.window.rootViewController = tabBar;
    } else {
        UITabBarController *tabBar = [[UITabBarController alloc] init];
        tabBar.viewControllers = allTabs;
        self.window.rootViewController = tabBar;
    }

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
