#import "BerryCell.h"
#import "DataManager.h"
#import <QuartzCore/QuartzCore.h>

#define BC_LEFT_PAD 12
#define BC_SPRITE_SIZE 32
#define BC_TEXT_LEFT (BC_LEFT_PAD + BC_SPRITE_SIZE + 12)

@interface BerryCell ()
@property (nonatomic, strong) UIImageView *spriteView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UILabel *powerLabel;
@end

@implementation BerryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _spriteView = [[UIImageView alloc] init];
        _spriteView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_spriteView];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:15];
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_nameLabel];

        _typeLabel = [[UILabel alloc] init];
        _typeLabel.font = [UIFont systemFontOfSize:11];
        _typeLabel.textColor = [UIColor grayColor];
        _typeLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_typeLabel];

        _powerLabel = [[UILabel alloc] init];
        _powerLabel.font = [UIFont boldSystemFontOfSize:13];
        _powerLabel.textColor = [UIColor grayColor];
        _powerLabel.textAlignment = NSTextAlignmentRight;
        _powerLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_powerLabel];
    }
    return self;
}

- (void)configureCellWithSummary:(NSDictionary *)summary {
    self.nameLabel.text = summary[@"name"] ?: @"";

    // Natural gift type display
    NSString *type = summary[@"natural_gift_type"] ?: @"";
    if (type.length > 0) {
        self.typeLabel.text = [[[type substringToIndex:1] uppercaseString]
            stringByAppendingString:[type substringFromIndex:1]];
        self.typeLabel.hidden = NO;
    } else {
        self.typeLabel.text = @"";
        self.typeLabel.hidden = YES;
    }

    // Natural gift power
    NSInteger power = [summary[@"natural_gift_power"] integerValue];
    if (power == 0) {
        self.powerLabel.text = @"\u2014";
    } else {
        self.powerLabel.text = [NSString stringWithFormat:@"%ld", (long)power];
    }

    // Sprite
    NSInteger berryID = [summary[@"id"] integerValue];
    self.spriteView.image = [[DataManager sharedManager] spriteForBerryID:berryID];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat powerW = 50;

    // Sprite
    self.spriteView.frame = CGRectMake(BC_LEFT_PAD, (h - BC_SPRITE_SIZE) / 2,
                                        BC_SPRITE_SIZE, BC_SPRITE_SIZE);

    // Power (right-aligned)
    self.powerLabel.frame = CGRectMake(w - powerW - 8, 0, powerW, h);

    // Name and type
    CGFloat nameWidth = w - BC_TEXT_LEFT - powerW - 16;
    self.nameLabel.frame = CGRectMake(BC_TEXT_LEFT, 8, nameWidth, 20);
    self.typeLabel.frame = CGRectMake(BC_TEXT_LEFT, 28, nameWidth, 16);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.spriteView.image = nil;
    self.nameLabel.text = nil;
    self.typeLabel.text = nil;
    self.powerLabel.text = nil;
}

@end
