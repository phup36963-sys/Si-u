#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

static UIWindow *floatWindow = nil;
static UIView *containerView = nil;

@interface FloatButtonHandler : NSObject
+ (void)handleMove:(UIPanGestureRecognizer *)pan;
@end

@implementation FloatButtonHandler

+ (void)handleMove:(UIPanGestureRecognizer *)pan {
    UIView *view = pan.view;
    CGPoint translation = [pan translationInView:view.superview];
    view.center = CGPointMake(view.center.x + translation.x,
                              view.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:view.superview];
}

@end

#pragma mark - Create Float

void createFloatButton(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (floatWindow) return;
        
        // Lấy UIWindowScene đang active (chuẩn iOS 13+)
        UIWindowScene *activeScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }
        
        if (!activeScene) return;
        
        floatWindow = [[UIWindow alloc] initWithWindowScene:activeScene];
        floatWindow.frame = activeScene.coordinateSpace.bounds;
        floatWindow.backgroundColor = UIColor.clearColor;
        floatWindow.windowLevel = UIWindowLevelAlert + 1;
        floatWindow.hidden = NO;
        
        UIViewController *rootVC = [UIViewController new];
        rootVC.view.backgroundColor = UIColor.clearColor;
        floatWindow.rootViewController = rootVC;
        
        // Container
        containerView = [[UIView alloc] initWithFrame:CGRectMake(80, 200, 70, 70)];
        containerView.backgroundColor = [[UIColor systemPinkColor] colorWithAlphaComponent:0.9];
        containerView.layer.cornerRadius = 35;
        containerView.clipsToBounds = YES;
        
        UILabel *label = [[UILabel alloc] initWithFrame:containerView.bounds];
        label.text = @"NP";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = UIColor.whiteColor;
        label.font = [UIFont boldSystemFontOfSize:18];
        [containerView addSubview:label];
        
        UIPanGestureRecognizer *pan =
        [[UIPanGestureRecognizer alloc] initWithTarget:[FloatButtonHandler class]
                                                action:@selector(handleMove:)];
        [containerView addGestureRecognizer:pan];
        
        [rootVC.view addSubview:containerView];
    });
}