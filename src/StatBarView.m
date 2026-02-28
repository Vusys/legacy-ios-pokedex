#import "StatBarView.h"
#import <QuartzCore/QuartzCore.h>

#define LABEL_WIDTH 52
#define VALUE_WIDTH 34
#define BAR_LEFT (LABEL_WIDTH + VALUE_WIDTH + 8)
#define BAR_HEIGHT 14
#define MAX_STAT 255.0

@interface StatBarView ()
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, assign) NSInteger statValue;
@end

@implementation StatBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont boldSystemFontOfSize:12];
        _nameLabel.textColor = [UIColor colorWithWhite:0.35 alpha:1];
        _nameLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_nameLabel];

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont systemFontOfSize:12];
        _valueLabel.textColor = [UIColor darkTextColor];
        _valueLabel.textAlignment = NSTextAlignmentRight;
        _valueLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_valueLabel];
    }
    return self;
}

- (void)configureWithName:(NSString *)name value:(NSInteger)value {
    self.nameLabel.text = name;
    self.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)value];
    self.statValue = value;
    [self setNeedsDisplay];
}

+ (UIColor *)colorForStatValue:(NSInteger)value {
    if (value < 30)  return [UIColor colorWithRed:0.80 green:0.15 blue:0.15 alpha:1];
    if (value < 60)  return [UIColor colorWithRed:0.90 green:0.45 blue:0.15 alpha:1];
    if (value < 90)  return [UIColor colorWithRed:0.90 green:0.75 blue:0.15 alpha:1];
    if (value < 120) return [UIColor colorWithRed:0.45 green:0.75 blue:0.20 alpha:1];
    return [UIColor colorWithRed:0.15 green:0.65 blue:0.50 alpha:1];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = self.bounds.size.height;
    self.nameLabel.frame = CGRectMake(0, 0, LABEL_WIDTH, h);
    self.valueLabel.frame = CGRectMake(LABEL_WIDTH, 0, VALUE_WIDTH, h);
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGFloat barMaxWidth = rect.size.width - BAR_LEFT - 4;
    CGFloat barY = (rect.size.height - BAR_HEIGHT) / 2;

    // Track background
    CGRect trackRect = CGRectMake(BAR_LEFT, barY, barMaxWidth, BAR_HEIGHT);
    UIBezierPath *trackPath = [UIBezierPath bezierPathWithRoundedRect:trackRect
                                                         cornerRadius:3];
    CGContextSetFillColorWithColor(ctx,
        [UIColor colorWithWhite:0.90 alpha:1].CGColor);
    CGContextAddPath(ctx, trackPath.CGPath);
    CGContextFillPath(ctx);

    // Inner shadow on track (top edge)
    CGContextSetStrokeColorWithColor(ctx,
        [UIColor colorWithWhite:0.80 alpha:0.5].CGColor);
    CGContextSetLineWidth(ctx, 0.5);
    CGContextMoveToPoint(ctx, BAR_LEFT + 3, barY + 0.5);
    CGContextAddLineToPoint(ctx, BAR_LEFT + barMaxWidth - 3, barY + 0.5);
    CGContextStrokePath(ctx);

    // Filled bar
    if (self.statValue > 0) {
        CGFloat fillWidth = (self.statValue / MAX_STAT) * barMaxWidth;
        if (fillWidth < 6) fillWidth = 6;
        CGRect fillRect = CGRectMake(BAR_LEFT, barY, fillWidth, BAR_HEIGHT);
        UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect:fillRect
                                                            cornerRadius:3];
        UIColor *barColor = [StatBarView colorForStatValue:self.statValue];
        CGContextSetFillColorWithColor(ctx, barColor.CGColor);
        CGContextAddPath(ctx, fillPath.CGPath);
        CGContextFillPath(ctx);

        // Glossy highlight on top half of bar
        CGRect glossRect = CGRectMake(BAR_LEFT, barY, fillWidth, BAR_HEIGHT * 0.5);
        CGContextSetFillColorWithColor(ctx,
            [UIColor colorWithWhite:1 alpha:0.2].CGColor);
        CGContextAddPath(ctx,
            [UIBezierPath bezierPathWithRoundedRect:glossRect cornerRadius:3].CGPath);
        CGContextFillPath(ctx);
    }
}

@end
