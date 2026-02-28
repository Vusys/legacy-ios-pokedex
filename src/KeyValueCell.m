#import "KeyValueCell.h"
#import "DetailConstants.h"

#define KV_LABEL_WIDTH 120.0f

@implementation KeyValueCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _keyLabel = [[UILabel alloc] init];
        _keyLabel.font = [UIFont boldSystemFontOfSize:DETAIL_BODY_FONT_SIZE];
        _keyLabel.textColor = [UIColor colorWithWhite:0.35 alpha:1];
        _keyLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_keyLabel];

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE];
        _valueLabel.textColor = [UIColor darkTextColor];
        _valueLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_valueLabel];
    }
    return self;
}

- (void)configureWithKey:(NSString *)key value:(NSString *)value {
    self.keyLabel.text = key;
    self.valueLabel.text = value;
    self.valueLabel.font = [UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE];
    self.valueLabel.textColor = [UIColor darkTextColor];
}

- (void)configureWithKey:(NSString *)key value:(NSString *)value
              valueColor:(UIColor *)color valueFont:(UIFont *)font {
    self.keyLabel.text = key;
    self.valueLabel.text = value;
    self.valueLabel.textColor = color;
    self.valueLabel.font = font;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat pad = DETAIL_CELL_PADDING;

    self.keyLabel.frame = CGRectMake(pad, 0, KV_LABEL_WIDTH, h);
    self.valueLabel.frame = CGRectMake(pad + KV_LABEL_WIDTH, 0,
                                       w - pad * 2 - KV_LABEL_WIDTH, h);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.keyLabel.text = nil;
    self.valueLabel.text = nil;
    self.valueLabel.font = [UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE];
    self.valueLabel.textColor = [UIColor darkTextColor];
}

@end
