#import "TexturedBackgroundView.h"

@implementation TexturedBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // Base parchment color
    CGContextSetFillColorWithColor(ctx,
        [UIColor colorWithRed:0.96 green:0.94 blue:0.90 alpha:1].CGColor);
    CGContextFillRect(ctx, rect);

    // Deterministic PRNG for consistent texture
    NSUInteger state = (NSUInteger)(rect.size.width * 1000 + rect.size.height);

    // Subtle noise dots
    for (int i = 0; i < 3000; i++) {
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
        CGFloat x = (state % (NSUInteger)rect.size.width);
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
        CGFloat y = (state % (NSUInteger)rect.size.height);
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
        CGFloat brightness = 0.88 + (CGFloat)(state % 10) / 100.0;
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
        CGFloat size = 1.0 + (CGFloat)(state % 2);

        CGContextSetFillColorWithColor(ctx,
            [UIColor colorWithWhite:brightness alpha:0.15].CGColor);
        CGContextFillEllipseInRect(ctx, CGRectMake(x, y, size, size));
    }

    // Subtle horizontal linen strokes
    for (int i = 0; i < 1500; i++) {
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
        CGFloat x = (state % (NSUInteger)rect.size.width);
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
        CGFloat y = (state % (NSUInteger)rect.size.height);
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
        CGFloat len = 2.0 + (state % 3);

        CGContextSetStrokeColorWithColor(ctx,
            [UIColor colorWithWhite:0.85 alpha:0.08].CGColor);
        CGContextSetLineWidth(ctx, 0.5);
        CGContextMoveToPoint(ctx, x, y);
        CGContextAddLineToPoint(ctx, x + len, y);
        CGContextStrokePath(ctx);
    }
}

@end
