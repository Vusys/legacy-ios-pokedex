#import "FlavorBarCell.h"
#import "DetailConstants.h"
#import <QuartzCore/QuartzCore.h>

#define FLAVOR_NAME_WIDTH 60.0f
#define FLAVOR_VALUE_WIDTH 30.0f

@interface FlavorBarCell ()
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *barView;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, assign) NSInteger potency;
@end

@implementation FlavorBarCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:12];
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_nameLabel];

        _barView = [[UIView alloc] init];
        _barView.layer.cornerRadius = 3;
        [self.contentView addSubview:_barView];

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont systemFontOfSize:12];
        _valueLabel.textColor = [UIColor grayColor];
        _valueLabel.textAlignment = NSTextAlignmentRight;
        _valueLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_valueLabel];
    }
    return self;
}

- (void)configureWithName:(NSString *)name
                  potency:(NSInteger)potency
                 barColor:(UIColor *)color {
    NSString *display = [[[name substringToIndex:1] uppercaseString]
        stringByAppendingString:[name substringFromIndex:1]];
    self.nameLabel.text = display;
    self.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)potency];
    self.barView.backgroundColor = color;
    self.potency = potency;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat maxBarWidth = w - pad * 2 - FLAVOR_NAME_WIDTH - FLAVOR_VALUE_WIDTH;

    self.nameLabel.frame = CGRectMake(pad, 0, FLAVOR_NAME_WIDTH, h);

    CGFloat barWidth = maxBarWidth * (self.potency / 40.0);
    if (barWidth < 0) barWidth = 0;
    self.barView.frame = CGRectMake(pad + FLAVOR_NAME_WIDTH, (h - 14) / 2, barWidth, 14);

    self.valueLabel.frame = CGRectMake(pad + FLAVOR_NAME_WIDTH + maxBarWidth, 0,
                                       FLAVOR_VALUE_WIDTH, h);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.nameLabel.text = nil;
    self.valueLabel.text = nil;
    self.barView.backgroundColor = nil;
    self.potency = 0;
}

@end
