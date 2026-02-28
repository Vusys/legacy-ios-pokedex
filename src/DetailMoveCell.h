#import <UIKit/UIKit.h>

@interface DetailMoveCell : UITableViewCell

- (void)configureWithName:(NSString *)name
                    level:(NSInteger)level
                     type:(NSString *)type
                    power:(id)power
                 accuracy:(id)accuracy
                       pp:(id)pp;

@end
