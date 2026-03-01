#ifndef NavBarStyle_h
#define NavBarStyle_h

#import <UIKit/UIKit.h>

static inline UIImage *NavBarGradientImage(CGFloat topR, CGFloat topG, CGFloat topB,
                                            CGFloat botR, CGFloat botG, CGFloat botB) {
    /* Load noise texture once */
    static UIImage *noiseTexture = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"noise"
                                                        ofType:@"png"
                                                   inDirectory:@"textures"];
        if (path) {
            noiseTexture = [[UIImage alloc] initWithContentsOfFile:path];
        }
    });

    CGFloat imgWidth = noiseTexture ? noiseTexture.size.width : 128;
    CGSize navSize = CGSizeMake(imgWidth, 44);
    UIGraphicsBeginImageContextWithOptions(navSize, YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    /* Base gradient: dark top → lighter bottom */
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] = {
        topR, topG, topB, 1.0,
        botR, botG, botB, 1.0
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
    CGContextDrawLinearGradient(ctx, gradient,
        CGPointMake(0, 0), CGPointMake(0, navSize.height), 0);
    CGGradientRelease(gradient);

    /* Noise texture overlay */
    if (noiseTexture) {
        CGContextSaveGState(ctx);
        CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
        CGContextSetAlpha(ctx, 0.35);
        CGContextDrawImage(ctx,
            CGRectMake(0, 0, navSize.width, navSize.height),
            noiseTexture.CGImage);
        CGContextRestoreGState(ctx);
    }

    /* iOS 5-style hard-cutoff gloss: bright top half, sharp edge at midpoint */
    CGFloat glossHeight = 22;

    /* Flat white fill on top half */
    CGContextSaveGState(ctx);
    CGContextSetBlendMode(ctx, kCGBlendModeScreen);
    CGFloat glossFillColors[] = {
        1.0, 1.0, 1.0, 0.30,
        1.0, 1.0, 1.0, 0.08
    };
    CGGradientRef glossFill = CGGradientCreateWithColorComponents(
        colorSpace, glossFillColors, NULL, 2);
    CGContextClipToRect(ctx, CGRectMake(0, 0, navSize.width, glossHeight));
    CGContextDrawLinearGradient(ctx, glossFill,
        CGPointMake(0, 0), CGPointMake(0, glossHeight), 0);
    CGGradientRelease(glossFill);
    CGContextRestoreGState(ctx);

    /* 1px dark line at the midpoint for hard edge */
    CGContextSetFillColorWithColor(ctx,
        [UIColor colorWithWhite:0.0 alpha:0.12].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, glossHeight, navSize.width, 1));

    /* Top edge highlight: 1px white line */
    CGContextSetFillColorWithColor(ctx,
        [UIColor colorWithWhite:1.0 alpha:0.35].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, navSize.width, 1));

    /* Bottom edge shadow: 1px dark line */
    CGContextSetFillColorWithColor(ctx,
        [UIColor colorWithWhite:0.0 alpha:0.20].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, navSize.height - 1, navSize.width, 1));

    CGColorSpaceRelease(colorSpace);

    UIImage *navImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return navImage;
}

#endif
