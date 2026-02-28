#import <UIKit/UIKit.h>

@interface DetailSpriteCell : UITableViewCell

@property (nonatomic, strong) UIImageView *spriteView;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *badgeLabel;

- (void)configureWithSprite:(UIImage *)sprite
                   numberID:(NSInteger)pokemonID
                       name:(NSString *)name;
- (void)configureWithSprite:(UIImage *)sprite
                   numberID:(NSInteger)pokemonID
                       name:(NSString *)name
                  badgeText:(NSString *)badge;

@end
