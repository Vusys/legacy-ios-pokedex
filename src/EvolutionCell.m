#import "EvolutionCell.h"
#import "DetailConstants.h"

@interface EvolutionCell ()
@property (nonatomic, strong) UILabel *fromLabel;
@property (nonatomic, strong) UILabel *toLabel;
@property (nonatomic, strong) UILabel *arrowLabel;
@property (nonatomic, strong) UILabel *conditionLabel;
@property (nonatomic, strong) UILabel *arrow2Label;
@end

@implementation EvolutionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _fromButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _fromButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_fromButton];

        _fromLabel = [[UILabel alloc] init];
        _fromLabel.font = [UIFont systemFontOfSize:10];
        _fromLabel.textColor = [UIColor darkTextColor];
        _fromLabel.backgroundColor = [UIColor clearColor];
        _fromLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_fromLabel];

        _arrowLabel = [[UILabel alloc] init];
        _arrowLabel.text = @"\u2192";
        _arrowLabel.font = [UIFont systemFontOfSize:12];
        _arrowLabel.textColor = [UIColor grayColor];
        _arrowLabel.textAlignment = NSTextAlignmentCenter;
        _arrowLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_arrowLabel];

        _conditionLabel = [[UILabel alloc] init];
        _conditionLabel.font = [UIFont systemFontOfSize:10];
        _conditionLabel.textColor = [UIColor grayColor];
        _conditionLabel.textAlignment = NSTextAlignmentCenter;
        _conditionLabel.backgroundColor = [UIColor clearColor];
        _conditionLabel.numberOfLines = 2;
        _conditionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:_conditionLabel];

        _arrow2Label = [[UILabel alloc] init];
        _arrow2Label.text = @"\u2192";
        _arrow2Label.font = [UIFont systemFontOfSize:12];
        _arrow2Label.textColor = [UIColor grayColor];
        _arrow2Label.textAlignment = NSTextAlignmentCenter;
        _arrow2Label.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_arrow2Label];

        _toButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _toButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_toButton];

        _toLabel = [[UILabel alloc] init];
        _toLabel.font = [UIFont systemFontOfSize:10];
        _toLabel.textColor = [UIColor darkTextColor];
        _toLabel.textAlignment = NSTextAlignmentRight;
        _toLabel.backgroundColor = [UIColor clearColor];
        _toLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_toLabel];
    }
    return self;
}

- (void)configureWithFromSprite:(UIImage *)fromSprite
                       fromName:(NSString *)fromName
                         fromID:(NSInteger)fromID
                       toSprite:(UIImage *)toSprite
                         toName:(NSString *)toName
                           toID:(NSInteger)toID
                      condition:(NSString *)condition {
    [self.fromButton setImage:fromSprite forState:UIControlStateNormal];
    self.fromButton.tag = fromID;
    self.fromLabel.text = fromName;

    [self.toButton setImage:toSprite forState:UIControlStateNormal];
    self.toButton.tag = toID;
    self.toLabel.text = toName;

    self.conditionLabel.text = condition;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat pad = DETAIL_CELL_PADDING;

    CGFloat spriteSize = 32;
    CGFloat nameW = 50;
    CGFloat arrowW = 14;
    CGFloat spriteY = (h - spriteSize) / 2;

    // Left: [fromSprite][fromName]
    CGFloat leftX = pad;
    self.fromButton.frame = CGRectMake(leftX, spriteY, spriteSize, spriteSize);
    leftX += spriteSize + 2;
    self.fromLabel.frame = CGRectMake(leftX, 0, nameW, h);
    leftX += nameW;

    // Right: [toName][toSprite]
    CGFloat rightX = w - pad - nameW;
    self.toLabel.frame = CGRectMake(rightX, 0, nameW, h);
    rightX -= (spriteSize + 2);
    self.toButton.frame = CGRectMake(rightX, spriteY, spriteSize, spriteSize);

    // Middle: [arrow][condition][arrow]
    CGFloat midStart = leftX;
    CGFloat midEnd = rightX;
    CGFloat condWidth = midEnd - midStart - arrowW * 2;

    self.arrowLabel.frame = CGRectMake(midStart, 0, arrowW, h);
    self.conditionLabel.frame = CGRectMake(midStart + arrowW, 0, condWidth, h);
    self.arrow2Label.frame = CGRectMake(midEnd - arrowW, 0, arrowW, h);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.fromButton setImage:nil forState:UIControlStateNormal];
    [self.toButton setImage:nil forState:UIControlStateNormal];
    self.fromLabel.text = nil;
    self.toLabel.text = nil;
    self.conditionLabel.text = nil;
    // Remove old targets
    [self.fromButton removeTarget:nil action:NULL
                 forControlEvents:UIControlEventTouchUpInside];
    [self.toButton removeTarget:nil action:NULL
               forControlEvents:UIControlEventTouchUpInside];
}

@end
