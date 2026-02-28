#import <UIKit/UIKit.h>
#import "FilterPopoverVC.h"

@interface ItemListVC : UITableViewController <FilterPopoverDelegate>
@property (nonatomic, copy) NSString *categoryFilter;  // nil = all items
@end
