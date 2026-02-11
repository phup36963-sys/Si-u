#import <UIKit/UIKit.h>

@interface UIWindow (GVWindow)
- (void)fixOrientation; 
- (struct CGRect)safeAreaFrame;
@end
