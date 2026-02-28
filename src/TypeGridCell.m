#import "TypeGridCell.h"
#import "TypeBadgeView.h"
#import "DetailConstants.h"

@interface TypeGridCell ()
@property (nonatomic, strong) UILabel *categoryLabel;
@property (nonatomic, strong) NSArray *typeNames;
@property (nonatomic, strong) NSMutableArray *badges;
@end

@implementation TypeGridCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _categoryLabel = [[UILabel alloc] init];
        _categoryLabel.font = [UIFont boldSystemFontOfSize:11];
        _categoryLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1];
        _categoryLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_categoryLabel];

        _badges = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)configureWithLabel:(NSString *)label types:(NSArray *)types {
    self.categoryLabel.text = label;
    self.typeNames = types;

    for (UIView *badge in self.badges) {
        [badge removeFromSuperview];
    }
    [self.badges removeAllObjects];

    for (NSString *type in types) {
        TypeBadgeView *badge = [[TypeBadgeView alloc] initWithTypeName:type];
        [self.contentView addSubview:badge];
        [self.badges addObject:badge];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat labelH = 20;

    self.categoryLabel.frame = CGRectMake(pad, 0, w - pad * 2, labelH);

    CGFloat badgeW = [TypeBadgeView badgeWidth];
    CGFloat badgeH = [TypeBadgeView badgeHeight];
    CGFloat x = pad;
    CGFloat y = labelH;

    for (TypeBadgeView *badge in self.badges) {
        if (x + badgeW > w - pad) {
            x = pad;
            y += badgeH + 4;
        }
        badge.frame = CGRectMake(x, y, badgeW, badgeH);
        x += badgeW + 4;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.categoryLabel.text = nil;
    for (UIView *badge in self.badges) {
        [badge removeFromSuperview];
    }
    [self.badges removeAllObjects];
    self.typeNames = nil;
}

+ (CGFloat)heightForLabel:(NSString *)label types:(NSArray *)types width:(CGFloat)width {
    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat labelH = 20;
    CGFloat badgeW = [TypeBadgeView badgeWidth];
    CGFloat badgeH = [TypeBadgeView badgeHeight];
    CGFloat x = pad;
    CGFloat rowCount = 1;

    for (NSUInteger i = 0; i < types.count; i++) {
        if (x + badgeW > width - pad) {
            x = pad;
            rowCount++;
        }
        x += badgeW + 4;
    }

    return labelH + badgeH * rowCount + 4 * (rowCount - 1) + 6;
}

@end
