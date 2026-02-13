#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "FloatWindow.h"
#import "FloatButton.h"

@interface NetPingAction : NSObject
+ (void)handleMove:(UIPanGestureRecognizer *)p;
@end

static UIWindow *overlayWindow = nil;
static UIButton *floatButton = nil;

@implementation NetPingAction
+ (void)handleMove:(UIPanGestureRecognizer *)p {
    if (floatButton) {
        CGPoint t = [p translationInView:floatButton.superview];
        floatButton.center = CGPointMake(floatButton.center.x + t.x, floatButton.center.y + t.y);
        [p setTranslation:CGPointZero inView:floatButton.superview];
    }
}
@end

void createNetPingOverlay(void) {
    // Nếu đã tồn tại thì không tạo nữa
    if (floatButton) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        // CHIẾN THUẬT MỚI: Thay vì tạo UIWindow riêng, ta bám vào Window có sẵn của Game
        UIWindow *keyWindow = nil;
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        
        if (!keyWindow) {
            // Nếu chưa có KeyWindow, lấy đại cái đầu tiên trong Scene
            UIWindowScene *scene = (UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject];
            keyWindow = scene.windows.firstObject;
        }

        if (keyWindow) {
            floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
            floatButton.frame = CGRectMake(100, 200, 60, 60);
            floatButton.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.9];
            floatButton.layer.cornerRadius = 30;
            floatButton.layer.zPosition = 9999; // Ép lên đỉnh Layer Stack
            floatButton.layer.borderWidth = 1.5;
            floatButton.layer.borderColor = [UIColor whiteColor].CGColor;
            [floatButton setTitle:@"NP" forState:UIControlStateNormal];

            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NetPingAction class] action:@selector(handleMove:)];
            [floatButton addGestureRecognizer:pan];

            // Add trực tiếp vào KeyWindow của App để né Sandbox Window riêng
            [keyWindow addSubview:floatButton];
            [keyWindow bringSubviewToFront:floatButton];
            
            NSLog(@"[NetPing] Overlay Injected into KeyWindow (iOS 18.4.1 Bypass)");
        }
    });
}

// Constructor tự động chạy
__attribute__((constructor))
static void initialize() {
    // iOS 18.4.1 quét rất gắt lúc load app, phải delay ít nhất 8-10 giây để "vượt rào"
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        createNetPingOverlay();
        
        // Tạo một vòng lặp kiểm tra để đảm bảo nút luôn nổi nếu app vẽ đè
        NSTimer *keepAlive = [NSTimer scheduledTimerWithTimeInterval:5.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            if (floatButton && floatButton.superview) {
                [floatButton.superview bringSubviewToFront:floatButton];
            } else {
                createNetPingOverlay();
            }
        }];
        [[NSRunLoop mainRunLoop] addTimer:keepAlive forMode:NSRunLoopCommonModes];
    });
}
