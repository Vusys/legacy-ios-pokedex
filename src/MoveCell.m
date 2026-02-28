#import "MoveCell.h"
#import "TypeBadgeView.h"
#import <QuartzCore/QuartzCore.h>

#define MC_LEFT_PAD 12
#define MC_BADGE_W 58
#define MC_TEXT_LEFT (MC_LEFT_PAD + MC_BADGE_W + 8)

@interface MoveCell ()
@property (nonatomic, strong) TypeBadgeView *typeBadge;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *classLabel;
@property (nonatomic, strong) UILabel *powerLabel;
@property (nonatomic, strong) UILabel *accLabel;
@property (nonatomic, strong) UILabel *ppLabel;
@end

@implementation MoveCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:15];
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_nameLabel];

        _classLabel = [[UILabel alloc] init];
        _classLabel.font = [UIFont systemFontOfSize:11];
        _classLabel.textColor = [UIColor grayColor];
        _classLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_classLabel];

        // Right-side stat labels
        _powerLabel = [[UILabel alloc] init];
        _powerLabel.font = [UIFont systemFontOfSize:12];
        _powerLabel.textColor = [UIColor darkTextColor];
        _powerLabel.textAlignment = NSTextAlignmentCenter;
        _powerLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_powerLabel];

        _accLabel = [[UILabel alloc] init];
        _accLabel.font = [UIFont systemFontOfSize:12];
        _accLabel.textColor = [UIColor darkTextColor];
        _accLabel.textAlignment = NSTextAlignmentCenter;
        _accLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_accLabel];

        _ppLabel = [[UILabel alloc] init];
        _ppLabel.font = [UIFont systemFontOfSize:12];
        _ppLabel.textColor = [UIColor darkTextColor];
        _ppLabel.textAlignment = NSTextAlignmentCenter;
        _ppLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_ppLabel];
    }
    return self;
}

- (void)configureCellWithSummary:(NSDictionary *)summary {
    NSString *name = summary[@"name"] ?: @"";
    NSString *type = summary[@"type"] ?: @"normal";
    NSString *damageClass = summary[@"damage_class"] ?: @"";

    self.nameLabel.text = name;

    // Damage class display
    if ([damageClass isEqualToString:@"physical"]) {
        self.classLabel.text = @"Physical";
    } else if ([damageClass isEqualToString:@"special"]) {
        self.classLabel.text = @"Special";
    } else if ([damageClass isEqualToString:@"status"]) {
        self.classLabel.text = @"Status";
    } else {
        self.classLabel.text = damageClass;
    }

    // Type badge
    if (self.typeBadge) {
        [self.typeBadge removeFromSuperview];
    }
    self.typeBadge = [[TypeBadgeView alloc] initWithTypeName:type];
    [self.contentView addSubview:self.typeBadge];

    // Power
    id power = summary[@"power"];
    if (power && power != [NSNull null]) {
        self.powerLabel.text = [NSString stringWithFormat:@"%@", power];
    } else {
        self.powerLabel.text = @"—";
    }

    // Accuracy
    id accuracy = summary[@"accuracy"];
    if (accuracy && accuracy != [NSNull null]) {
        self.accLabel.text = [NSString stringWithFormat:@"%@", accuracy];
    } else {
        self.accLabel.text = @"—";
    }

    // PP
    id pp = summary[@"pp"];
    if (pp) {
        self.ppLabel.text = [NSString stringWithFormat:@"%@", pp];
    } else {
        self.ppLabel.text = @"—";
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat statColW = 44;
    CGFloat statsRight = w - 8;

    // Type badge
    self.typeBadge.frame = CGRectMake(MC_LEFT_PAD, (h - [TypeBadgeView badgeHeight]) / 2,
                                      [TypeBadgeView badgeWidth], [TypeBadgeView badgeHeight]);

    // Right-side stats: PP | Acc | Pow
    CGFloat ppX = statsRight - statColW;
    CGFloat accX = ppX - statColW;
    CGFloat powX = accX - statColW;

    self.ppLabel.frame = CGRectMake(ppX, 0, statColW, h);
    self.accLabel.frame = CGRectMake(accX, 0, statColW, h);
    self.powerLabel.frame = CGRectMake(powX, 0, statColW, h);

    // Name and class
    CGFloat nameWidth = powX - MC_TEXT_LEFT - 4;
    self.nameLabel.frame = CGRectMake(MC_TEXT_LEFT, 8, nameWidth, 20);
    self.classLabel.frame = CGRectMake(MC_TEXT_LEFT, 28, nameWidth, 16);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    if (self.typeBadge) {
        [self.typeBadge removeFromSuperview];
        self.typeBadge = nil;
    }
    self.nameLabel.text = nil;
    self.classLabel.text = nil;
    self.powerLabel.text = nil;
    self.accLabel.text = nil;
    self.ppLabel.text = nil;
}

@end
