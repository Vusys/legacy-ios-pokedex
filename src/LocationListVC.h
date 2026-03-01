#import <UIKit/UIKit.h>
#import "FilterPopoverVC.h"

@interface LocationListVC : UITableViewController <FilterPopoverDelegate>

@property (nonatomic, strong) NSString *regionName;

@end
