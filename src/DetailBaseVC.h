#import <UIKit/UIKit.h>

@interface DetailBaseVC : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, assign) CGFloat lastBuiltWidth;

- (void)buildSections;
- (void)setupHeaderView;
- (void)navBarGradientTopColor:(CGFloat *)top bottomColor:(CGFloat *)bottom;
- (NSString *)emptyStateText;
- (BOOL)hasData;
- (void)showEmptyState;

// Favourites (subclasses override)
- (NSString *)favouriteEntityType;
- (NSInteger)favouriteEntityID;
- (void)setupFavouriteButton;

@end
