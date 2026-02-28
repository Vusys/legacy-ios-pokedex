#import <UIKit/UIKit.h>

@class StatBarView;

@interface StatBarCell : UITableViewCell

@property (nonatomic, strong) StatBarView *statBar;

- (void)configureWithName:(NSString *)name value:(NSInteger)value;

@end
