#import "ItemCell.h"
#import "DataManager.h"
#import <QuartzCore/QuartzCore.h>

#define IC_LEFT_PAD 12
#define IC_SPRITE_SIZE 32
#define IC_TEXT_LEFT (IC_LEFT_PAD + IC_SPRITE_SIZE + 8)

@interface ItemCell ()
@property (nonatomic, strong) UIImageView *spriteView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *categoryLabel;
@property (nonatomic, strong) UILabel *costLabel;
@end

@implementation ItemCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _spriteView = [[UIImageView alloc] init];
        _spriteView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_spriteView];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:15];
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_nameLabel];

        _categoryLabel = [[UILabel alloc] init];
        _categoryLabel.font = [UIFont systemFontOfSize:11];
        _categoryLabel.textColor = [UIColor grayColor];
        _categoryLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_categoryLabel];

        _costLabel = [[UILabel alloc] init];
        _costLabel.font = [UIFont systemFontOfSize:12];
        _costLabel.textColor = [UIColor darkTextColor];
        _costLabel.textAlignment = NSTextAlignmentRight;
        _costLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_costLabel];
    }
    return self;
}

- (void)configureCellWithSummary:(NSDictionary *)summary {
    self.nameLabel.text = summary[@"name"] ?: @"";

    // Category display
    NSString *cat = summary[@"category"] ?: @"";
    if (cat.length > 0) {
        NSArray *parts = [cat componentsSeparatedByString:@"-"];
        NSMutableArray *capitalized = [[NSMutableArray alloc] init];
        for (NSString *part in parts) {
            if (part.length > 0) {
                [capitalized addObject:[[[part substringToIndex:1] uppercaseString]
                    stringByAppendingString:[part substringFromIndex:1]]];
            }
        }
        self.categoryLabel.text = [capitalized componentsJoinedByString:@" "];
    } else {
        self.categoryLabel.text = @"";
    }

    // Cost
    NSInteger cost = [summary[@"cost"] integerValue];
    if (cost == 0) {
        self.costLabel.text = @"—";
    } else {
        self.costLabel.text = [NSString stringWithFormat:@"₽%ld", (long)cost];
    }

    // Sprite
    BOOL hasSprite = [summary[@"has_sprite"] boolValue];
    NSString *apiName = summary[@"api_name"] ?: @"";
    if (hasSprite && apiName.length > 0) {
        self.spriteView.image = [[DataManager sharedManager] spriteForItemName:apiName];
    } else {
        self.spriteView.image = nil;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat costW = 70;

    // Sprite
    self.spriteView.frame = CGRectMake(IC_LEFT_PAD, (h - IC_SPRITE_SIZE) / 2,
                                        IC_SPRITE_SIZE, IC_SPRITE_SIZE);

    // Cost (right-aligned)
    self.costLabel.frame = CGRectMake(w - costW - 8, 0, costW, h);

    // Name and category
    CGFloat nameWidth = w - IC_TEXT_LEFT - costW - 16;
    self.nameLabel.frame = CGRectMake(IC_TEXT_LEFT, 8, nameWidth, 20);
    self.categoryLabel.frame = CGRectMake(IC_TEXT_LEFT, 28, nameWidth, 16);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.spriteView.image = nil;
    self.nameLabel.text = nil;
    self.categoryLabel.text = nil;
    self.costLabel.text = nil;
}

@end
