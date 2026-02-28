#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PokemonType : NSObject

+ (UIColor *)colorForTypeName:(NSString *)typeName;
+ (UIColor *)darkColorForTypeName:(NSString *)typeName;
+ (NSArray *)allTypeNames;

@end
