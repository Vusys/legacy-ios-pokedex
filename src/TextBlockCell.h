#import <UIKit/UIKit.h>

@interface TextBlockCell : UITableViewCell

@property (nonatomic, strong) UILabel *bodyLabel;

- (void)configureWithText:(NSString *)text;
- (void)configureWithText:(NSString *)text font:(UIFont *)font color:(UIColor *)color;

+ (CGFloat)heightForText:(NSString *)text width:(CGFloat)width;
+ (CGFloat)heightForText:(NSString *)text width:(CGFloat)width font:(UIFont *)font;

@end
