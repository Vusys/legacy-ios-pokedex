#import "DetailMoveCell.h"
#import "PokemonType.h"
#import "DetailConstants.h"

@interface DetailMoveCell ()
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UILabel *powLabel;
@property (nonatomic, strong) UILabel *accLabel;
@property (nonatomic, strong) UILabel *ppLabel;
@end

@implementation DetailMoveCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UIFont *cellFont = [UIFont systemFontOfSize:11];
        UIFont *boldFont = [UIFont boldSystemFontOfSize:9];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = cellFont;
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.backgroundColor = [UIColor clearColor];
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_nameLabel];

        _typeLabel = [[UILabel alloc] init];
        _typeLabel.font = boldFont;
        _typeLabel.textAlignment = NSTextAlignmentCenter;
        _typeLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_typeLabel];

        _powLabel = [[UILabel alloc] init];
        _powLabel.font = cellFont;
        _powLabel.textColor = [UIColor darkTextColor];
        _powLabel.textAlignment = NSTextAlignmentCenter;
        _powLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_powLabel];

        _accLabel = [[UILabel alloc] init];
        _accLabel.font = cellFont;
        _accLabel.textColor = [UIColor darkTextColor];
        _accLabel.textAlignment = NSTextAlignmentCenter;
        _accLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_accLabel];

        _ppLabel = [[UILabel alloc] init];
        _ppLabel.font = cellFont;
        _ppLabel.textColor = [UIColor darkTextColor];
        _ppLabel.textAlignment = NSTextAlignmentCenter;
        _ppLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_ppLabel];
    }
    return self;
}

- (void)configureWithName:(NSString *)name
                    level:(NSInteger)level
                     type:(NSString *)type
                    power:(id)power
                 accuracy:(id)accuracy
                       pp:(id)pp {
    if (level > 0) {
        self.nameLabel.text = [NSString stringWithFormat:@"Lv.%ld %@", (long)level, name];
    } else {
        self.nameLabel.text = name;
    }

    if (type.length > 0) {
        NSString *abbrev = [[type uppercaseString]
            substringToIndex:MIN(type.length, (NSUInteger)4)];
        self.typeLabel.text = abbrev;
        self.typeLabel.textColor = [PokemonType colorForTypeName:type];
    } else {
        self.typeLabel.text = nil;
    }

    self.powLabel.text = (power && power != [NSNull null]) ?
        [NSString stringWithFormat:@"%@", power] : @"\u2014";
    self.accLabel.text = (accuracy && accuracy != [NSNull null]) ?
        [NSString stringWithFormat:@"%@", accuracy] : @"\u2014";
    self.ppLabel.text = pp ? [NSString stringWithFormat:@"%@", pp] : @"\u2014";
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width;
    CGFloat h = self.contentView.bounds.size.height;
    CGFloat pad = DETAIL_CELL_PADDING;
    CGFloat innerW = w - pad * 2;

    CGFloat typeColW = 50;
    CGFloat powColW = 36;
    CGFloat accColW = 36;
    CGFloat ppColW = 30;
    CGFloat statsW = typeColW + powColW + accColW + ppColW;
    CGFloat nameColW = innerW - statsW;

    self.nameLabel.frame = CGRectMake(pad, 0, nameColW, h);
    self.typeLabel.frame = CGRectMake(pad + nameColW, 0, typeColW, h);
    self.powLabel.frame = CGRectMake(pad + nameColW + typeColW, 0, powColW, h);
    self.accLabel.frame = CGRectMake(pad + nameColW + typeColW + powColW, 0, accColW, h);
    self.ppLabel.frame = CGRectMake(pad + nameColW + typeColW + powColW + accColW, 0, ppColW, h);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.nameLabel.text = nil;
    self.typeLabel.text = nil;
    self.powLabel.text = nil;
    self.accLabel.text = nil;
    self.ppLabel.text = nil;
}

@end
