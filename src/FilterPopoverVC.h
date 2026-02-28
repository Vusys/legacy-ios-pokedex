#import <UIKit/UIKit.h>
#import "FilterState.h"

@protocol FilterPopoverDelegate <NSObject>
- (void)filterPopoverDidApply:(FilterState *)filterState;
@end

@interface FilterPopoverVC : UIViewController

@property (nonatomic, weak) id<FilterPopoverDelegate> delegate;
@property (nonatomic, strong) FilterState *filterState;
@property (nonatomic, assign) BOOL movesMode;

@end
