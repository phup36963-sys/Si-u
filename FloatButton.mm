// FloatButton.mm (hoặc tên file bạn dùng cho nút chính)
// Chỉ hiện 1 nút nổi ban đầu, tap để mở 3 nút từ menu.mm

#import <UIKit/UIKit.h>
#import <UIVisualEffect.h>  // Blur effect

// Khai báo hàm từ menu.mm (để tap nút chính thì gọi mở 3 nút)
extern void createThreeFloatingButtons(void);

static UIWindow *floatWindow = nil;
static UIView *containerView = nil;
static UIVisualEffectView *blurView = nil;
static UILabel *label = nil;
static BOOL isVisible = YES;

// Handler drag & snap
@interface FloatHandler : NSObject
+ (void)handlePan:(UIPanGestureRecognizer *)pan;
+ (void)snapToEdge:(UIView *)view;
@end

@implementation FloatHandler

+ (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *view = pan.view;
    UIView *superview = view.superview;
    
    if (pan.state == UIGestureRecognizerStateBegan ||
        pan.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [pan translationInView:superview];
        view.center = CGPointMake(view.center.x + translation.x,
                                  view.center.y + translation.y);
        [pan setTranslation:CGPointZero inView:superview];
        
    } else if (pan.state == UIGestureRecognizerStateEnded) {
        [self snapToEdge:view];
    }
}

+ (void)snapToEdge:(UIView *)view {
    CGRect bounds = view.superview.bounds;
    CGPoint center = view.center;
    
    // Snap ngang
    if (center.x < bounds.size.width / 2) {
        center.x = view.frame.size.width / 2 + 20;
    } else {
        center.x = bounds.size.width - view.frame.size.width / 2 - 20;
    }
    
    // Giới hạn dọc
    CGFloat minY = 60.0;
    CGFloat maxY = bounds.size.height - view.frame.size.height - 60.0;
    center.y = MAX(minY, MIN(maxY, center.y));
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        view.center = center;
    } completion:nil];
}

@end

#pragma mark - Tạo nút nổi chính "NP"

void createMainFloatButton(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (floatWindow) {
            floatWindow.hidden = !isVisible;
            return;
        }
        
        // Tìm scene active
        UIWindowScene *activeScene = nil;
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:UIWindowScene.class] &&
                scene.activationState == UISceneActivationStateForegroundActive) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }
        
        if (!activeScene) {
            NSLog(@"[FloatButton] No active scene!");
            return;
        }
        
        floatWindow = [[UIWindow alloc] initWithWindowScene:activeScene];
        floatWindow.frame = activeScene.coordinateSpace.bounds;
        floatWindow.backgroundColor = UIColor.clearColor;
        floatWindow.windowLevel = UIWindowLevelAlert + 2000;
        floatWindow.hidden = NO;
        
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = UIColor.clearColor;
        floatWindow.rootViewController = rootVC;
        
        // Container nút chính
        containerView = [[UIView alloc] initWithFrame:CGRectMake(30, 150, 80, 80)];
        containerView.layer.cornerRadius = 40;
        containerView.clipsToBounds = YES;
        containerView.layer.shadowColor = [UIColor systemPinkColor].CGColor;
        containerView.layer.shadowOpacity = 0.7;
        containerView.layer.shadowRadius = 12;
        containerView.layer.shadowOffset = CGSizeMake(0, 6);
        
        // Blur
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
        blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.frame = containerView.bounds;
        [containerView addSubview:blurView];
        
        // Label "NP"
        label = [[UILabel alloc] initWithFrame:containerView.bounds];
        label.text = @"NP";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = UIColor.whiteColor;
        label.font = [UIFont boldSystemFontOfSize:26];
        label.shadowColor = [UIColor blackColor];
        label.shadowOffset = CGSizeMake(0, 1);
        [containerView addSubview:label];
        
        // Gestures
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[FloatHandler class]
                                                                              action:@selector(handlePan:)];
        [containerView addGestureRecognizer:pan];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:rootVC
                                                                              action:@selector(mainButtonTapped)];
        [containerView addGestureRecognizer:tap];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:rootVC
                                                                                                action:@selector(longPressHide)];
        [containerView addGestureRecognizer:longPress];
        
        [rootVC.view addSubview:containerView];
        
        // Animation hiện nút
        containerView.alpha = 0;
        containerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
        [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
            containerView.alpha = 1;
            containerView.transform = CGAffineTransformIdentity;
        } completion:nil];
        
        NSLog(@"[NetPingPro] Main Float Button 'NP' created!");
    });
}

#pragma mark - Hook cho action

%hook UIViewController

- (void)mainButtonTapped {
    NSLog(@"[NetPingPro] Main button tapped → Mở 3 nút nổi từ menu.mm");
    
    // Gọi hàm từ menu.mm để hiện 3 nút Ghost/Tele/Freeze
    createThreeFloatingButtons();
    
    // Optional: Ẩn nút chính sau khi mở menu (hoặc giữ lại)
    // floatWindow.hidden = YES;
    
    // Feedback tap
    [UIView animateWithDuration:0.12 animations:^{
        containerView.transform = CGAffineTransformMakeScale(0.85, 0.85);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.18 animations:^{
            containerView.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (void)longPressHide:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        isVisible = !isVisible;
        floatWindow.hidden = !isVisible;
        NSLog(@"[NetPingPro] Long press → Visibility: %d", isVisible);
    }
}

%end

// Load tự động khi dylib inject
%ctor {
    createMainFloatButton();
    NSLog(@"[NetPingPro] FloatButton loaded - Tap 'NP' để mở 3 nút nổi!");
}