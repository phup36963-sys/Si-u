// menu.mm
// Floating 3 buttons: Ghost - Tele - Freeze
// Tương thích iOS 13+ đến 18.x / non-jb inject
// Chỉnh sửa: đẹp hơn, ổn định hơn, dễ mở rộng

#import <UIKit/UIKit.h>
#import <UIVisualEffect.h>

// Window và buttons global
static UIWindow *overlayWindow = nil;
static NSArray<UIView *> *floatButtons = nil;
static BOOL buttonsVisible = YES;

// Cấu trúc nút để dễ mở rộng
typedef struct {
    NSString *title;
    UIColor *color;
    SEL actionSelector;  // Optional: selector nếu cần gọi hàm riêng
} FloatButtonConfig;

static FloatButtonConfig buttonConfigs[] = {
    {@"Ghost", [UIColor systemPurpleColor], NULL},
    {@"Tele",  [UIColor systemCyanColor],   NULL},
    {@"Freeze",[UIColor systemYellowColor], NULL}
};
static const int numButtons = sizeof(buttonConfigs) / sizeof(buttonConfigs[0]);

// Handler drag & snap
@interface FloatHandler : NSObject
+ (void)handlePan:(UIPanGestureRecognizer *)pan;
+ (void)snapToEdge:(UIView *)button;
+ (void)toggleVisibility;
@end

@implementation FloatHandler

+ (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *btn = pan.view;
    UIView *superview = btn.superview;
    
    if (pan.state == UIGestureRecognizerStateBegan ||
        pan.state == UIGestureRecognizerStateChanged) {
        
        CGPoint delta = [pan translationInView:superview];
        btn.center = CGPointMake(btn.center.x + delta.x, btn.center.y + delta.y);
        [pan setTranslation:CGPointZero inView:superview];
        
    } else if (pan.state == UIGestureRecognizerStateEnded ||
               pan.state == UIGestureRecognizerStateCancelled) {
        [self snapToEdge:btn];
    }
}

+ (void)snapToEdge:(UIView *)button {
    CGRect bounds = button.superview.bounds;
    CGPoint center = button.center;
    CGFloat halfWidth = button.frame.size.width / 2;
    
    // Snap ngang
    center.x = (center.x < bounds.size.width * 0.5) ?
        halfWidth + 16 : bounds.size.width - halfWidth - 16;
    
    // Giới hạn dọc (tránh notch/home bar)
    CGFloat minY = 60.0;
    CGFloat maxY = bounds.size.height - button.frame.size.height - 80.0;
    center.y = MAX(minY, MIN(maxY, center.y));
    
    [UIView animateWithDuration:0.4
                          delay:0
         usingSpringWithDamping:0.75
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        button.center = center;
    } completion:nil];
}

+ (void)toggleVisibility {
    buttonsVisible = !buttonsVisible;
    overlayWindow.hidden = !buttonsVisible;
    NSLog(@"[Menu.mm] 3 nút nổi: %@", buttonsVisible ? @"Hiện" : @"Ẩn");
}

@end

#pragma mark - Tạo 3 nút nổi

void createThreeFloatingButtons(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Nếu window đã tồn tại → chỉ toggle visibility
        if (overlayWindow) {
            [FloatHandler toggleVisibility];
            return;
        }
        
        // Tìm scene active
        UIWindowScene *activeScene = nil;
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] &&
                scene.activationState == UISceneActivationStateForegroundActive) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }
        
        if (!activeScene) {
            NSLog(@"[Menu.mm] Không tìm thấy active UIWindowScene");
            return;
        }
        
        // Tạo overlay window
        overlayWindow = [[UIWindow alloc] initWithWindowScene:activeScene];
        overlayWindow.frame = activeScene.coordinateSpace.bounds;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.windowLevel = UIWindowLevelAlert + 3000;  // Cao hơn nữa để chắc chắn overlay
        overlayWindow.hidden = NO;
        
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        overlayWindow.rootViewController = rootVC;
        
        NSMutableArray *buttons = [NSMutableArray array];
        CGFloat buttonSize = 72.0;
        CGFloat spacing = 100.0;
        CGFloat startY = 180.0;
        
        for (int i = 0; i < numButtons; i++) {
            UIView *btnContainer = [[UIView alloc] initWithFrame:CGRectMake(
                activeScene.coordinateSpace.bounds.size.width - buttonSize - 20,  // Bắt đầu cạnh phải
                startY + i * spacing, buttonSize, buttonSize)];
            
            btnContainer.layer.cornerRadius = buttonSize / 2;
            btnContainer.clipsToBounds = YES;
            btnContainer.layer.borderWidth = 1.5;
            btnContainer.layer.borderColor = [buttonConfigs[i].color colorWithAlphaComponent:0.8].CGColor;
            btnContainer.layer.shadowColor = buttonConfigs[i].color.CGColor;
            btnContainer.layer.shadowOpacity = 0.75;
            btnContainer.layer.shadowRadius = 12;
            btnContainer.layer.shadowOffset = CGSizeMake(0, 5);
            
            // Blur mạnh hơn
            UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
            UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
            blurView.frame = btnContainer.bounds;
            [btnContainer addSubview:blurView];
            
            // Text
            UILabel *lbl = [[UILabel alloc] initWithFrame:btnContainer.bounds];
            lbl.text = buttonConfigs[i].title;
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.textColor = [UIColor whiteColor];
            lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
            lbl.adjustsFontSizeToFitWidth = YES;
            lbl.minimumScaleFactor = 0.75;
            [btnContainer addSubview:lbl];
            
            // Gestures
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[FloatHandler class]
                                                                                  action:@selector(handlePan:)];
            [btnContainer addGestureRecognizer:pan];
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:rootVC action:@selector(buttonTapped:)];
            [btnContainer addGestureRecognizer:tap];
            
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:rootVC action:@selector(longPressToggle:)];
            [btnContainer addGestureRecognizer:longPress];
            
            btnContainer.tag = 200 + i;
            
            [rootVC.view addSubview:btnContainer];
            [buttons addObject:btnContainer];
            
            // Animation xuất hiện
            btnContainer.alpha = 0;
            btnContainer.transform = CGAffineTransformMakeScale(0.4, 0.4);
            [UIView animateWithDuration:0.5
                                  delay:0.08 * i
                 usingSpringWithDamping:0.7
                  initialSpringVelocity:0.8
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                btnContainer.alpha = 1;
                btnContainer.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
        
        floatButtons = [buttons copy];
        NSLog(@"[Menu.mm] Đã tạo 3 nút nổi: Ghost - Tele - Freeze");
    });
}

// Tap nút
%hook UIViewController

- (void)buttonTapped:(UITapGestureRecognizer *)tap {
    NSInteger index = tap.view.tag - 200;
    if (index >= 0 && index < numButtons) {
        NSString *feature = buttonConfigs[index].title;
        NSLog(@"[Menu.mm] Activated: %@", feature);
        
        // Gọi logic hack của bạn ở đây
        // Ví dụ: if (index == 0) { enableGhost(); }
        
        // Feedback tap + glow
        [UIView animateWithDuration:0.1 animations:^{
            tap.view.transform = CGAffineTransformMakeScale(0.85, 0.85);
            tap.view.layer.shadowOpacity = 1.0;
            tap.view.layer.shadowRadius = 18;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.25 animations:^{
                tap.view.transform = CGAffineTransformIdentity;
                tap.view.layer.shadowOpacity = 0.75;
                tap.view.layer.shadowRadius = 12;
            }];
        }];
    }
}

// Long press bất kỳ nút nào → ẩn/hiện toàn bộ
- (void)longPressToggle:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [FloatHandler toggleVisibility];
    }
}

%end

// Load tự động (có thể gọi từ FloatButton.mm khi tap "NP")
%ctor {
    // Không gọi tự động ở đây nếu muốn chỉ hiện khi tap nút chính
    // createThreeFloatingButtons();  // Comment nếu dùng từ FloatButton.mm
    NSLog(@"[Menu.mm] Loaded - Sẵn sàng tạo 3 nút nổi");
}