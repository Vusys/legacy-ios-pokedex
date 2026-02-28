#import "PokemonCell.h"
#import "TypeBadgeView.h"
#import "DataManager.h"
#import <QuartzCore/QuartzCore.h>

#define SPRITE_SIZE 48
#define SPRITE_LEFT 8
#define TEXT_LEFT (SPRITE_LEFT + SPRITE_SIZE + 10)
#define BADGE_GAP 4

@interface PokemonCell ()
@property (nonatomic, strong) UIImageView *spriteView;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) NSMutableArray *typeBadges;
@end

@implementation PokemonCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _typeBadges = [[NSMutableArray alloc] init];

        // Sprite
        _spriteView = [[UIImageView alloc] initWithFrame:
            CGRectMake(SPRITE_LEFT, 6, SPRITE_SIZE, SPRITE_SIZE)];
        _spriteView.contentMode = UIViewContentModeScaleAspectFit;
        _spriteView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        _spriteView.layer.cornerRadius = 4;
        _spriteView.layer.borderWidth = 0.5;
        _spriteView.layer.borderColor = [[UIColor colorWithWhite:0.85 alpha:1] CGColor];
        [self.contentView addSubview:_spriteView];

        // Number label
        _numberLabel = [[UILabel alloc] init];
        _numberLabel.font = [UIFont fontWithName:@"Courier-Bold" size:12];
        if (!_numberLabel.font)
            _numberLabel.font = [UIFont boldSystemFontOfSize:12];
        _numberLabel.textColor = [UIColor grayColor];
        _numberLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_numberLabel];

        // Name label
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:16];
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_nameLabel];
    }
    return self;
}

- (void)configureCellWithSummary:(NSDictionary *)summary {
    NSInteger pokemonID = [summary[@"id"] integerValue];
    NSString *name = summary[@"name"] ?: @"";
    NSArray *types = summary[@"types"] ?: @[];

    // Number
    self.numberLabel.text = [NSString stringWithFormat:@"#%03ld", (long)pokemonID];

    // Name
    self.nameLabel.text = name;

    // Sprite (from shared cache)
    self.spriteView.image = [[DataManager sharedManager] spriteForPokemonID:pokemonID];

    // Clear old type badges
    for (UIView *badge in self.typeBadges) {
        [badge removeFromSuperview];
    }
    [self.typeBadges removeAllObjects];

    // Add type badges
    for (NSString *type in types) {
        TypeBadgeView *badge = [[TypeBadgeView alloc] initWithTypeName:type];
        [self.contentView addSubview:badge];
        [self.typeBadges addObject:badge];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat h = self.contentView.bounds.size.height;

    // Sprite
    self.spriteView.frame = CGRectMake(SPRITE_LEFT, (h - SPRITE_SIZE) / 2,
                                       SPRITE_SIZE, SPRITE_SIZE);

    // Number
    self.numberLabel.frame = CGRectMake(TEXT_LEFT, 6, 60, 14);

    // Name
    CGFloat nameWidth = self.contentView.bounds.size.width - TEXT_LEFT - 10;
    self.nameLabel.frame = CGRectMake(TEXT_LEFT, 20, nameWidth, 20);

    // Type badges
    CGFloat badgeX = TEXT_LEFT;
    CGFloat badgeY = 42;
    for (TypeBadgeView *badge in self.typeBadges) {
        badge.frame = CGRectMake(badgeX, badgeY,
                                 [TypeBadgeView badgeWidth], [TypeBadgeView badgeHeight]);
        badgeX += [TypeBadgeView badgeWidth] + BADGE_GAP;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    self.spriteView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    self.spriteView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.spriteView.image = nil;
    self.numberLabel.text = nil;
    self.nameLabel.text = nil;
    for (UIView *badge in self.typeBadges) {
        [badge removeFromSuperview];
    }
    [self.typeBadges removeAllObjects];
}

@end
