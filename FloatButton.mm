#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "FloatWindow.h"
#import "FloatButton.h"

#pragma mark - FloatWindow Implementation

@implementation FloatWindow

- (instancetype)initWithWindowScene:(UIWindowScene *)scene {
    self = [super initWithWindowScene:scene];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        // TRICK 1: Sử dụng mức ưu tiên cực cao. 
        // Trên iOS 18 đời đầu, 2.1e9 là giới hạn tối đa để đè cả hệ thống.
        self.windowLevel = UIWindowLevelStatusBar + 1000000; 
        self.userInteractionEnabled = YES;
        self.hidden = NO;
        
        // TRICK 2: Ép Window không bị ẩn khi Scene của App chính bị suspend
        self.layer.zPosition = FLT_MAX;
    }
    return self;
}

- (BOOL)canBecomeKeyWindow { return NO; }

// Chỉ cho phép tương tác tại vùng của Nút bấm
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    // Nếu chạm vào vùng trống của Window, trả về nil để tương tác xuyên xuống Free Fire
    if (view == self) return nil;
    return view;
}
@end

#pragma mark - Overlay Logic

static FloatWindow *overlayWindow = nil;
static UIButton *floatButton = nil;

// TRICK 3: Hàm xử lý kéo thả nút (Pan Gesture)
void handlePan(UIPanGestureRecognizer *gesture) {
    CGPoint translation = [gesture translationInView:overlayWindow];
    floatButton.center = CGPointMake(floatButton.center.x + translation.x, 
                                     floatButton.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:overlayWindow];
}

void createNetPingOverlay(void) {
    if (overlayWindow) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindowScene *activeScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                activeScene = (UIWindowScene *)scene;
                // Ưu tiên scene đang active nhưng không dừng lại nếu không tìm thấy
                if (scene.activationState == UISceneActivationStateForegroundActive) break;
            }
        }

        if (!activeScene) return;

        // Khởi tạo Window lách luật
        overlayWindow = [[FloatWindow alloc] initWithWindowScene:activeScene];
        overlayWindow.frame = [UIScreen mainScreen].bounds;

        floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        floatButton.frame = CGRectMake(100, 200, 65, 65);
        floatButton.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.8];
        floatButton.layer.cornerRadius = 32.5;
        floatButton.layer.borderWidth = 2;
        floatButton.layer.borderColor = [UIColor whiteColor].CGColor;
        [floatButton setTitle:@"NP" forState:UIControlStateNormal];

        // Thêm kéo thả
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:floatButton action:nil];
        // Sử dụng block hoặc target để xử lý di chuyển
        [floatButton addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:[NetPingAction class] action:@selector(handleMove:)]];

        [overlayWindow addSubview:floatButton];
        
        // TRICK 4: Ép Window luôn hiển thị bất chấp trạng thái App
        [overlayWindow makeKeyAndVisible];
        overlayWindow.hidden = NO;
        
        NSLog(@"[NetPing] Overlay Injected & Bypassing...");
    });
}

// Lớp hỗ trợ xử lý action cho nút
@implementation NetPingAction
+ (void)handleMove:(UIPanGestureRecognizer *)p {
    CGPoint t = [p translationInView:overlayWindow];
    floatButton.center = CGPointMake(floatButton.center.x + t.x, floatButton.center.y + t.y);
    [p setTranslation:CGPointZero inView:overlayWindow];
}
@end

// TRICK 5: Constructor tự động chạy khi dylib được nạp vào
__attribute__((constructor))
static void initialize() {
    // Đợi 2 giây sau khi app khởi động để tránh bị hệ thống reset window
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        createNetPingOverlay();
    });
}
