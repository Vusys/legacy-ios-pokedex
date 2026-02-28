#import "StatBarCell.h"
#import "StatBarView.h"
#import "DetailConstants.h"

@implementation StatBarCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _statBar = [[StatBarView alloc] init];
        [self.contentView addSubview:_statBar];
    }
    return self;
}

- (void)configureWithName:(NSString *)name value:(NSInteger)value {
    [self.statBar configureWithName:name value:value];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat pad = DETAIL_CELL_PADDING;
    self.statBar.frame = CGRectMake(pad, 0, w - pad * 2, h);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.statBar configureWithName:@"" value:0];
}

@end
