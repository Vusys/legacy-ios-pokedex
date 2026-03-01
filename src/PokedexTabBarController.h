#import <UIKit/UIKit.h>

@interface PokedexTabBarController : UIViewController

@property (nonatomic, readonly) UITabBar *tabBar;
@property (nonatomic, readonly) NSArray *childViewControllerList;
@property (nonatomic, assign) NSUInteger selectedIndex;

- (void)setChildViewControllers:(NSArray *)viewControllers;
- (void)selectTabWithTag:(NSInteger)tag;

@end
