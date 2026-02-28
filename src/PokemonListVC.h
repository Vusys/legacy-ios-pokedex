#import <UIKit/UIKit.h>
#import "FilterPopoverVC.h"

@interface PokemonListVC : UITableViewController <FilterPopoverDelegate>

@property (nonatomic, weak) UINavigationController *detailNavigationController;

@end
