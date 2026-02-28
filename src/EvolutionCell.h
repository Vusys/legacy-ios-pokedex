#import <UIKit/UIKit.h>

@interface EvolutionCell : UITableViewCell

@property (nonatomic, strong) UIButton *fromButton;
@property (nonatomic, strong) UIButton *toButton;

- (void)configureWithFromSprite:(UIImage *)fromSprite
                       fromName:(NSString *)fromName
                         fromID:(NSInteger)fromID
                       toSprite:(UIImage *)toSprite
                         toName:(NSString *)toName
                           toID:(NSInteger)toID
                      condition:(NSString *)condition;

@end
