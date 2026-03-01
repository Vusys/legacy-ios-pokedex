#ifndef NavBarStyle_h
#define NavBarStyle_h

#import <UIKit/UIKit.h>

static inline UIImage *NavBarGradientImage(CGFloat topR, CGFloat topG, CGFloat topB,
                                            CGFloat botR, CGFloat botG, CGFloat botB) {
    CGSize navSize = CGSizeMake(1, 44);
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

    /* Gloss overlay: white highlight on top half */
    CGFloat glossColors[] = {
        1.0, 1.0, 1.0, 0.35,
        1.0, 1.0, 1.0, 0.0
    };
    CGGradientRef gloss = CGGradientCreateWithColorComponents(colorSpace, glossColors, NULL, 2);
    CGContextDrawLinearGradient(ctx, gloss,
        CGPointMake(0, 0), CGPointMake(0, 22), 0);
    CGGradientRelease(gloss);

    CGColorSpaceRelease(colorSpace);

    /* Top edge highlight: 1px white line */
    CGContextSetFillColorWithColor(ctx,
        [UIColor colorWithWhite:1.0 alpha:0.25].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, navSize.width, 1));

    UIImage *navImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return navImage;
}

#endif
