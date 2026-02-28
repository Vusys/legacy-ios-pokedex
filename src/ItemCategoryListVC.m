#import "ItemCategoryListVC.h"
#import "ItemListVC.h"
#import "DataManager.h"
#import <QuartzCore/QuartzCore.h>

#define CATCELL_HEIGHT 50
#define CATCELL_ID @"ItemCategoryCell"
#define CATCELL_LEFT_PAD 12
#define CATCELL_SPRITE_SIZE 32
#define CATCELL_TEXT_LEFT (CATCELL_LEFT_PAD + CATCELL_SPRITE_SIZE + 8)

@interface ItemCategoryListVC ()
@property (nonatomic, strong) NSArray *categories;   // array of dicts
@property (nonatomic, assign) NSInteger totalCount;
@property (nonatomic, strong) UIImage *bagIcon;       // for "All Items" row
@end

@implementation ItemCategoryListVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Items";
    [self styleNavBar];
    [self buildCategories];
    [self buildBagIcon];
}

#pragma mark - Data

- (void)buildCategories {
    NSArray *allItems = [[DataManager sharedManager] allItemSummaries];
    self.totalCount = allItems.count;

    // Group items by category
    NSMutableDictionary *groups = [[NSMutableDictionary alloc] init];
    for (NSDictionary *item in allItems) {
        NSString *cat = item[@"category"] ?: @"other";
        NSMutableArray *list = groups[cat];
        if (!list) {
            list = [[NSMutableArray alloc] init];
            groups[cat] = list;
        }
        [list addObject:item];
    }

    // Build category info array
    NSMutableArray *cats = [[NSMutableArray alloc] init];
    for (NSString *cat in groups) {
        NSArray *items = groups[cat];
        NSString *displayName = [self displayNameForCategory:cat];

        // Find first item with a sprite for the representative icon
        NSString *spriteApiName = nil;
        for (NSDictionary *item in items) {
            if ([item[@"has_sprite"] boolValue] && [item[@"api_name"] length] > 0) {
                spriteApiName = item[@"api_name"];
                break;
            }
        }

        [cats addObject:@{
            @"category": cat,
            @"displayName": displayName,
            @"count": @(items.count),
            @"spriteApiName": spriteApiName ?: @""
        }];
    }

    // Sort alphabetically by display name
    [cats sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"displayName"] caseInsensitiveCompare:b[@"displayName"]];
    }];

    self.categories = cats;
}

- (NSString *)displayNameForCategory:(NSString *)cat {
    if (cat.length == 0) return @"Other";
    NSArray *parts = [cat componentsSeparatedByString:@"-"];
    NSMutableArray *capitalized = [[NSMutableArray alloc] init];
    for (NSString *part in parts) {
        if (part.length > 0) {
            [capitalized addObject:[[[part substringToIndex:1] uppercaseString]
                stringByAppendingString:[part substringFromIndex:1]]];
        }
    }
    return [capitalized componentsJoinedByString:@" "];
}

#pragma mark - Bag Icon

- (void)buildBagIcon {
    CGFloat size = CATCELL_SPRITE_SIZE;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    UIColor *fill = [UIColor colorWithRed:0.60 green:0.35 blue:0.10 alpha:1.0];
    [fill setFill];
    [fill setStroke];
    CGContextSetLineWidth(ctx, 1.5);

    // Bag handle
    CGContextStrokeEllipseInRect(ctx, CGRectMake(8, 2, 16, 12));

    // Bag body
    CGFloat bodyX = 4, bodyY = 11, bodyW = 24, bodyH = 18, r = 3;
    CGContextMoveToPoint(ctx, bodyX + r, bodyY);
    CGContextAddLineToPoint(ctx, bodyX + bodyW - r, bodyY);
    CGContextAddArcToPoint(ctx, bodyX + bodyW, bodyY, bodyX + bodyW, bodyY + r, r);
    CGContextAddLineToPoint(ctx, bodyX + bodyW, bodyY + bodyH - r);
    CGContextAddArcToPoint(ctx, bodyX + bodyW, bodyY + bodyH, bodyX + bodyW - r, bodyY + bodyH, r);
    CGContextAddLineToPoint(ctx, bodyX + r, bodyY + bodyH);
    CGContextAddArcToPoint(ctx, bodyX, bodyY + bodyH, bodyX, bodyY + bodyH - r, r);
    CGContextAddLineToPoint(ctx, bodyX, bodyY + r);
    CGContextAddArcToPoint(ctx, bodyX, bodyY, bodyX + r, bodyY, r);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);

    // Clasp
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 0.4);
    CGContextFillRect(ctx, CGRectMake(bodyX + 2, bodyY + 7, bodyW - 4, 3));

    self.bagIcon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

#pragma mark - Nav Bar

- (void)styleNavBar {
    CGSize navSize = CGSizeMake(1, 44);
    UIGraphicsBeginImageContextWithOptions(navSize, YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] = {
        0.60, 0.35, 0.10, 1.0,
        0.75, 0.50, 0.15, 1.0
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
    CGContextDrawLinearGradient(ctx, gradient,
        CGPointMake(0, 0), CGPointMake(0, navSize.height), 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    UIImage *navImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self.navigationController.navigationBar setBackgroundImage:navImage
        forBarMetrics:UIBarMetricsDefault];

    self.navigationController.navigationBar.titleTextAttributes = @{
        UITextAttributeTextColor: [UIColor whiteColor],
        UITextAttributeTextShadowColor: [UIColor colorWithWhite:0 alpha:0.6],
        UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
        UITextAttributeFont: [UIFont boldSystemFontOfSize:20]
    };
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    return self.categories.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CATCELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CATCELL_ID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CATCELL_ID];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        UIImageView *spriteView = [[UIImageView alloc] initWithFrame:
            CGRectMake(CATCELL_LEFT_PAD, (CATCELL_HEIGHT - CATCELL_SPRITE_SIZE) / 2,
                       CATCELL_SPRITE_SIZE, CATCELL_SPRITE_SIZE)];
        spriteView.contentMode = UIViewContentModeScaleAspectFit;
        spriteView.tag = 100;
        [cell.contentView addSubview:spriteView];

        UILabel *nameLabel = [[UILabel alloc] init];
        nameLabel.font = [UIFont boldSystemFontOfSize:15];
        nameLabel.textColor = [UIColor darkTextColor];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.tag = 101;
        [cell.contentView addSubview:nameLabel];

        UILabel *countLabel = [[UILabel alloc] init];
        countLabel.font = [UIFont systemFontOfSize:14];
        countLabel.textColor = [UIColor grayColor];
        countLabel.textAlignment = NSTextAlignmentRight;
        countLabel.backgroundColor = [UIColor clearColor];
        countLabel.tag = 102;
        [cell.contentView addSubview:countLabel];
    }

    UIImageView *spriteView = (UIImageView *)[cell.contentView viewWithTag:100];
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:101];
    UILabel *countLabel = (UILabel *)[cell.contentView viewWithTag:102];

    if (indexPath.section == 0) {
        // "All Items" row
        spriteView.image = self.bagIcon;
        nameLabel.text = @"All Items";
        countLabel.text = [NSString stringWithFormat:@"%ld", (long)self.totalCount];
    } else {
        NSDictionary *cat = self.categories[indexPath.row];
        nameLabel.text = cat[@"displayName"];
        countLabel.text = [NSString stringWithFormat:@"%@", cat[@"count"]];

        NSString *apiName = cat[@"spriteApiName"];
        if (apiName.length > 0) {
            spriteView.image = [[DataManager sharedManager] spriteForItemName:apiName];
        } else {
            spriteView.image = self.bagIcon;
        }
    }

    // Layout
    CGFloat w = cell.contentView.bounds.size.width;
    CGFloat countW = 50;
    spriteView.frame = CGRectMake(CATCELL_LEFT_PAD, (CATCELL_HEIGHT - CATCELL_SPRITE_SIZE) / 2,
                                  CATCELL_SPRITE_SIZE, CATCELL_SPRITE_SIZE);
    CGFloat nameW = w - CATCELL_TEXT_LEFT - countW - 30;
    nameLabel.frame = CGRectMake(CATCELL_TEXT_LEFT, 0, nameW, CATCELL_HEIGHT);
    countLabel.frame = CGRectMake(w - countW - 30, 0, countW, CATCELL_HEIGHT);

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    ItemListVC *listVC = [[ItemListVC alloc] init];

    if (indexPath.section == 0) {
        listVC.title = @"All Items";
    } else {
        NSDictionary *cat = self.categories[indexPath.row];
        listVC.categoryFilter = cat[@"category"];
        listVC.title = cat[@"displayName"];
    }

    [self.navigationController pushViewController:listVC animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
