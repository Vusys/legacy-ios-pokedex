#import "TextBlockCell.h"
#import "DetailConstants.h"

@implementation TextBlockCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _bodyLabel = [[UILabel alloc] init];
        _bodyLabel.font = [UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE];
        _bodyLabel.textColor = [UIColor colorWithWhite:0.30 alpha:1];
        _bodyLabel.backgroundColor = [UIColor clearColor];
        _bodyLabel.numberOfLines = 0;
        _bodyLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:_bodyLabel];
    }
    return self;
}

- (void)configureWithText:(NSString *)text {
    self.bodyLabel.text = text;
    self.bodyLabel.font = [UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE];
    self.bodyLabel.textColor = [UIColor colorWithWhite:0.30 alpha:1];
}

- (void)configureWithText:(NSString *)text font:(UIFont *)font color:(UIColor *)color {
    self.bodyLabel.text = text;
    self.bodyLabel.font = font;
    self.bodyLabel.textColor = color;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat pad = DETAIL_CELL_PADDING;
    self.bodyLabel.frame = CGRectMake(pad, 8, w - pad * 2, h - 16);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.bodyLabel.text = nil;
    self.bodyLabel.font = [UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE];
    self.bodyLabel.textColor = [UIColor colorWithWhite:0.30 alpha:1];
}

+ (CGFloat)heightForText:(NSString *)text width:(CGFloat)width {
    return [self heightForText:text width:width
                          font:[UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE]];
}

+ (CGFloat)heightForText:(NSString *)text width:(CGFloat)width font:(UIFont *)font {
    if (!text || text.length == 0) return 0;
    CGFloat textWidth = width - DETAIL_CELL_PADDING * 2;
    CGSize size = [text sizeWithFont:font
                   constrainedToSize:CGSizeMake(textWidth, 9999)
                       lineBreakMode:NSLineBreakByWordWrapping];
    return size.height + 16; // 8px top + 8px bottom padding
}

@end
