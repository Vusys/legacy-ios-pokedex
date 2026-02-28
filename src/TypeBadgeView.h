#import <UIKit/UIKit.h>

@interface TypeBadgeView : UIView

@property (nonatomic, strong) NSString *typeName;

- (instancetype)initWithTypeName:(NSString *)typeName;

+ (CGFloat)badgeWidth;
+ (CGFloat)badgeHeight;

@end
