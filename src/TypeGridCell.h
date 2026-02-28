#import <UIKit/UIKit.h>

@interface TypeGridCell : UITableViewCell

- (void)configureWithLabel:(NSString *)label types:(NSArray *)types;

+ (CGFloat)heightForLabel:(NSString *)label types:(NSArray *)types width:(CGFloat)width;

@end
