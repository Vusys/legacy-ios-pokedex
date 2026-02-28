#import "TypeBadgeView.h"
#import "PokemonType.h"
#import <QuartzCore/QuartzCore.h>

@interface TypeBadgeView ()
@property (nonatomic, strong) UILabel *label;
@end

@implementation TypeBadgeView

+ (CGFloat)badgeWidth { return 58; }
+ (CGFloat)badgeHeight { return 20; }

- (instancetype)initWithTypeName:(NSString *)typeName {
    CGFloat w = [TypeBadgeView badgeWidth];
    CGFloat h = [TypeBadgeView badgeHeight];
    self = [super initWithFrame:CGRectMake(0, 0, w, h)];
    if (self) {
        _typeName = typeName;

        UIColor *typeColor = [PokemonType colorForTypeName:typeName];
        self.backgroundColor = typeColor;
        self.layer.cornerRadius = 3;
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [[PokemonType darkColorForTypeName:typeName] CGColor];

        _label = [[UILabel alloc] initWithFrame:self.bounds];
        _label.text = [[typeName uppercaseString]
            substringToIndex:MIN(typeName.length, (NSUInteger)8)];
        _label.font = [UIFont boldSystemFontOfSize:10];
        _label.textColor = [UIColor whiteColor];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.backgroundColor = [UIColor clearColor];
        _label.shadowColor = [UIColor colorWithWhite:0 alpha:0.4];
        _label.shadowOffset = CGSizeMake(0, -0.5);
        [self addSubview:_label];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // Glossy highlight on top half
    CGRect topHalf = CGRectMake(0, 0, rect.size.width, rect.size.height * 0.5);
    CGContextSetFillColorWithColor(ctx,
        [UIColor colorWithWhite:1.0 alpha:0.15].CGColor);
    CGContextFillRect(ctx, topHalf);
}

@end
