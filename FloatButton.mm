#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "FloatWindow.h"
#import "FloatButton.h"

// --- 1. Khai báo Interface (Để sửa lỗi undeclared identifier) ---
@interface NetPingAction : NSObject
+ (void)handleMove:(UIPanGestureRecognizer *)p;
@end

// Biến static để quản lý bộ nhớ trong dylib
static FloatWindow *overlayWindow = nil;
static UIButton *floatButton = nil;

#pragma mark - FloatWindow Implementation

@implementation FloatWindow

- (instancetype)initWithWindowScene:(UIWindowScene *)scene {
    self = [super initWithWindowScene:scene];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        // Vượt rào: Mức ưu tiên Window cao nhất có thể trên iOS 18 "cổ"
        self.windowLevel = UIWindowLevelStatusBar + 1000000; 
        self.userInteractionEnabled = YES;
        self.hidden = NO;
        
        // Ép lớp layer luôn nằm trên cùng (zPosition cực đại)
        self.layer.zPosition = FLT_MAX;
    }
    return self;
}

- (BOOL)canBecomeKeyWindow { return NO; }

// Cơ chế hitTest để chơi game mượt mà không bị cản bởi Window
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self) {
        return nil; // Trả về nil để touch xuyên qua Window xuống Game (Free Fire)
    }
    return view;
}
@end

#pragma mark - NetPingAction Implementation (Fix lỗi class definition)

@implementation NetPingAction
+ (void)handleMove:(UIPanGestureRecognizer *)p {
    if (overlayWindow && floatButton) {
        CGPoint t = [p translationInView:overlayWindow];
        floatButton.center = CGPointMake(floatButton.center.x + t.x, floatButton.center.y + t.y);
        [p setTranslation:CGPointZero inView:overlayWindow];
    }
}
@end

#pragma mark - Overlay Logic

void createNetPingOverlay(void) {
    if (overlayWindow) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindowScene *activeScene = nil;

        // Lấy Scene đang hoạt động để bám vào (Vượt sandbox iOS 18)
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                activeScene = (UIWindowScene *)scene;
                if (scene.activationState == UISceneActivationStateForegroundActive) break;
            }
        }

        if (!activeScene) return;

        // Tạo Window
        overlayWindow = [[FloatWindow alloc] initWithWindowScene:activeScene];
        overlayWindow.frame = [UIScreen mainScreen].bounds;

        // Tạo Nút NP
        floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        floatButton.frame = CGRectMake(100, 200, 65, 65);
        floatButton.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.8];
        floatButton.layer.cornerRadius = 32.5;
        floatButton.layer.borderWidth = 2;
        floatButton.layer.borderColor = [UIColor whiteColor].CGColor;
        
        [floatButton setTitle:@"NP" forState:UIControlStateNormal];
        [floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];

        // Gesture di chuyển nút
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NetPingAction class] 
                                                                               action:@selector(handleMove:)];
        [floatButton addGestureRecognizer:pan];

        [overlayWindow addSubview:floatButton];
        
        // Ép Window hiển thị cưỡng bức
        [overlayWindow makeKeyAndVisible];
        overlayWindow.hidden = NO;
        
        NSLog(@"[NetPing] Overlay đã kích hoạt - Bypass Ready");
    });
}

// Hàm khôi phục nếu cần
void restoreOverlayIfNeeded(void) {
    if (!overlayWindow) {
        createNetPingOverlay();
    }
}

#pragma mark - Constructor (Dylib Injection)

__attribute__((constructor))
static void initialize() {
    // Đợi 3 giây sau khi game load để tránh bị system xóa window trong lúc boot
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        createNetPingOverlay();
    });
}
