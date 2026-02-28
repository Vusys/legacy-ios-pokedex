#import <UIKit/UIKit.h>

@interface FlavorBarCell : UITableViewCell

- (void)configureWithName:(NSString *)name
                  potency:(NSInteger)potency
                 barColor:(UIColor *)color;

@end
