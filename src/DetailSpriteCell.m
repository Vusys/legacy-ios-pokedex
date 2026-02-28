#import "DetailSpriteCell.h"
#import "DetailConstants.h"
#import <QuartzCore/QuartzCore.h>

@implementation DetailSpriteCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _spriteView = [[UIImageView alloc] init];
        _spriteView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_spriteView];

        _numberLabel = [[UILabel alloc] init];
        _numberLabel.font = [UIFont fontWithName:@"Courier-Bold" size:12];
        if (!_numberLabel.font) _numberLabel.font = [UIFont boldSystemFontOfSize:12];
        _numberLabel.textColor = [UIColor grayColor];
        _numberLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_numberLabel];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:DETAIL_BODY_FONT_SIZE];
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_nameLabel];

        _badgeLabel = [[UILabel alloc] init];
        _badgeLabel.font = [UIFont boldSystemFontOfSize:10];
        _badgeLabel.textColor = [UIColor whiteColor];
        _badgeLabel.textAlignment = NSTextAlignmentCenter;
        _badgeLabel.backgroundColor = [UIColor colorWithRed:0.6 green:0.4 blue:0.8 alpha:1];
        _badgeLabel.layer.cornerRadius = 4;
        _badgeLabel.clipsToBounds = YES;
        _badgeLabel.hidden = YES;
        [self.contentView addSubview:_badgeLabel];
    }
    return self;
}

- (void)configureWithSprite:(UIImage *)sprite
                   numberID:(NSInteger)pokemonID
                       name:(NSString *)name {
    self.spriteView.image = sprite;
    self.numberLabel.text = [NSString stringWithFormat:@"#%03ld", (long)pokemonID];
    self.nameLabel.text = name;
    self.badgeLabel.hidden = YES;
}

- (void)configureWithSprite:(UIImage *)sprite
                   numberID:(NSInteger)pokemonID
                       name:(NSString *)name
                  badgeText:(NSString *)badge {
    [self configureWithSprite:sprite numberID:pokemonID name:name];
    if (badge && badge.length > 0) {
        self.badgeLabel.text = badge;
        self.badgeLabel.hidden = NO;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat pad = DETAIL_CELL_PADDING;

    self.spriteView.frame = CGRectMake(pad, (h - 24) / 2, 24, 24);
    self.numberLabel.frame = CGRectMake(pad + 30, 0, 50, h);

    CGFloat nameX = pad + 82;
    CGFloat nameW = w - nameX - pad;
    if (!self.badgeLabel.hidden) nameW -= 60;
    self.nameLabel.frame = CGRectMake(nameX, 0, nameW, h);

    if (!self.badgeLabel.hidden) {
        self.badgeLabel.frame = CGRectMake(w - pad - 55, (h - 20) / 2, 50, 20);
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.spriteView.image = nil;
    self.numberLabel.text = nil;
    self.nameLabel.text = nil;
    self.badgeLabel.text = nil;
    self.badgeLabel.hidden = YES;
}

@end
