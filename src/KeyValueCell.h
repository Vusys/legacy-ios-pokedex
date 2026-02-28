#import <UIKit/UIKit.h>

@interface KeyValueCell : UITableViewCell

@property (nonatomic, strong) UILabel *keyLabel;
@property (nonatomic, strong) UILabel *valueLabel;

- (void)configureWithKey:(NSString *)key value:(NSString *)value;
- (void)configureWithKey:(NSString *)key value:(NSString *)value
              valueColor:(UIColor *)color valueFont:(UIFont *)font;

@end
