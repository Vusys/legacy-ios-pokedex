#import "AbilityCell.h"

@interface AbilityCell ()
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *genLabel;
@end

@implementation AbilityCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:15];
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_nameLabel];

        _genLabel = [[UILabel alloc] init];
        _genLabel.font = [UIFont systemFontOfSize:11];
        _genLabel.textColor = [UIColor grayColor];
        _genLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_genLabel];
    }
    return self;
}

- (void)configureCellWithSummary:(NSDictionary *)summary {
    self.nameLabel.text = summary[@"name"] ?: @"";

    NSString *gen = summary[@"generation"] ?: @"";
    if (gen.length > 0) {
        NSString *numeral = [[gen componentsSeparatedByString:@"-"] lastObject];
        self.genLabel.text = [NSString stringWithFormat:@"Gen %@",
                              [numeral uppercaseString]];
    } else {
        self.genLabel.text = @"";
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w = self.contentView.bounds.size.width;
    CGFloat pad = 12;

    self.nameLabel.frame = CGRectMake(pad, 6, w - pad * 2, 20);
    self.genLabel.frame = CGRectMake(pad, 26, w - pad * 2, 14);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.nameLabel.text = nil;
    self.genLabel.text = nil;
}

@end
