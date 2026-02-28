#import "NatureCell.h"

@interface NatureCell ()
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *upStatLabel;
@property (nonatomic, strong) UILabel *downStatLabel;
@end

@implementation NatureCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:15];
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_nameLabel];

        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.font = [UIFont italicSystemFontOfSize:11];
        _subtitleLabel.textColor = [UIColor grayColor];
        _subtitleLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_subtitleLabel];

        _upStatLabel = [[UILabel alloc] init];
        _upStatLabel.font = [UIFont boldSystemFontOfSize:12];
        _upStatLabel.textColor = [UIColor colorWithRed:0.2 green:0.65 blue:0.2 alpha:1];
        _upStatLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_upStatLabel];

        _downStatLabel = [[UILabel alloc] init];
        _downStatLabel.font = [UIFont boldSystemFontOfSize:12];
        _downStatLabel.textColor = [UIColor colorWithRed:0.85 green:0.2 blue:0.2 alpha:1];
        _downStatLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_downStatLabel];
    }
    return self;
}

- (NSString *)shortStatName:(NSString *)apiStat {
    if (!apiStat || apiStat.length == 0) return @"\u2014";
    if ([apiStat isEqualToString:@"attack"])          return @"Atk";
    if ([apiStat isEqualToString:@"defense"])         return @"Def";
    if ([apiStat isEqualToString:@"special-attack"])  return @"Sp.Atk";
    if ([apiStat isEqualToString:@"special-defense"]) return @"Sp.Def";
    if ([apiStat isEqualToString:@"speed"])           return @"Spd";
    return apiStat;
}

- (void)configureCellWithSummary:(NSDictionary *)summary {
    self.nameLabel.text = summary[@"name"] ?: @"";

    BOOL isNeutral = [summary[@"is_neutral"] boolValue];
    self.subtitleLabel.text = isNeutral ? @"Neutral" : @"";

    NSString *increased = summary[@"increased_stat"] ?: @"";
    NSString *decreased = summary[@"decreased_stat"] ?: @"";

    if (isNeutral) {
        self.upStatLabel.text = @"\u2014";
        self.upStatLabel.textColor = [UIColor grayColor];
        self.downStatLabel.text = @"\u2014";
        self.downStatLabel.textColor = [UIColor grayColor];
    } else {
        self.upStatLabel.text = [NSString stringWithFormat:@"+%@",
                                 [self shortStatName:increased]];
        self.upStatLabel.textColor = [UIColor colorWithRed:0.2 green:0.65 blue:0.2 alpha:1];
        self.downStatLabel.text = [NSString stringWithFormat:@"\u2212%@",
                                   [self shortStatName:decreased]];
        self.downStatLabel.textColor = [UIColor colorWithRed:0.85 green:0.2 blue:0.2 alpha:1];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat h = self.contentView.bounds.size.height;
    CGFloat pad = 12;

    self.nameLabel.frame = CGRectMake(pad, 6, 110, 20);
    self.subtitleLabel.frame = CGRectMake(pad, 26, 110, 14);

    CGFloat statX = 130;
    self.upStatLabel.frame = CGRectMake(statX, (h - 18) / 2, 70, 18);
    self.downStatLabel.frame = CGRectMake(statX + 75, (h - 18) / 2, 70, 18);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.nameLabel.text = nil;
    self.subtitleLabel.text = nil;
    self.upStatLabel.text = nil;
    self.downStatLabel.text = nil;
}

@end
