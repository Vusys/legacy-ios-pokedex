#import "EggGroupCell.h"

@interface EggGroupCell ()
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *countLabel;
@end

@implementation EggGroupCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:15];
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_nameLabel];

        _countLabel = [[UILabel alloc] init];
        _countLabel.font = [UIFont systemFontOfSize:12];
        _countLabel.textColor = [UIColor grayColor];
        _countLabel.textAlignment = NSTextAlignmentRight;
        _countLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_countLabel];
    }
    return self;
}

- (void)configureCellWithSummary:(NSDictionary *)summary {
    self.nameLabel.text = summary[@"name"] ?: @"";

    NSInteger count = [summary[@"pokemon_count"] integerValue];
    if (count > 0) {
        self.countLabel.text = [NSString stringWithFormat:@"%ld Pok\u00e9mon",
                                (long)count];
    } else {
        self.countLabel.text = @"";
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat pad = 12;
    CGFloat countWidth = 100;

    self.nameLabel.frame = CGRectMake(pad, 0, w - pad - countWidth - 8, h);
    self.countLabel.frame = CGRectMake(w - countWidth - 8, 0, countWidth, h);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.nameLabel.text = nil;
    self.countLabel.text = nil;
}

@end
