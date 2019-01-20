#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableViewRowAction (PrivateAPI)

@property(nonatomic, strong) void (^_handler)(UITableViewRowAction *, NSIndexPath *);

@end

NS_ASSUME_NONNULL_END
