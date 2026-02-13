#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <WebKit/WebKit.h>
#import "FloatWindow.h"
#import "FloatButton.h"

// --- Interface xử lý Bridge giữa HTML và Dylib ---
@interface NetPingAction : NSObject <WKScriptMessageHandler>
+ (void)handleMove:(UIPanGestureRecognizer *)p;
@end

// --- Biến Static quản lý ---
static UIView *containerView = nil; 
static WKWebView *menuWebView = nil;

@implementation NetPingAction

// Xử lý di chuyển nút trên màn hình
+ (void)handleMove:(UIPanGestureRecognizer *)p {
    if (containerView) {
        CGPoint t = [p translationInView:containerView.superview];
        containerView.center = CGPointMake(containerView.center.x + t.x, containerView.center.y + t.y);
        [p setTranslation:CGPointZero inView:containerView.superview];
    }
}

// Nhận lệnh từ Javascript (index.html) gửi lên
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"netping"]) {
        // Xử lý logic tại đây nếu cần
        NSLog(@"[NetPing] Nhận lệnh từ HTML: %@", message.body);
    }
}
@end

#pragma mark - Core Overlay

void createNetPingOverlay(void) {
    if (containerView) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        
        // Tìm Window chính của Game để chèn Menu vào
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        
        if (!keyWindow) {
            UIWindowScene *scene = (UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject];
            keyWindow = scene.windows.firstObject;
        }

        if (keyWindow) {
            // 1. Khởi tạo khung chứa (Container)
            // Kích thước ban đầu bằng nút (60x60). 
            containerView = [[UIView alloc] initWithFrame:CGRectMake(50, 150, 60, 60)];
            containerView.backgroundColor = [UIColor clearColor];
            containerView.layer.zPosition = MAXFLOAT; 

            // 2. Cấu hình WebView để hiển thị HTML
            WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
            NetPingAction *handler = [[NetPingAction alloc] init];
            [config.userContentController addScriptMessageHandler:handler name:@"netping"];

            menuWebView = [[WKWebView alloc] initWithFrame:containerView.bounds configuration:config];
            
            // --- FIX TRIỆT ĐỂ KHOẢNG ĐEN & VƯỢT RÀO ---
            menuWebView.opaque = NO; 
            menuWebView.backgroundColor = [UIColor clearColor];
            menuWebView.scrollView.backgroundColor = [UIColor clearColor];
            menuWebView.scrollView.bounces = NO; 
            
            // Ép WebView tràn toàn bộ, bỏ qua vùng Safe Area (Tai thỏ) của Apple
            if (@available(iOS 11.0, *)) {
                menuWebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
            
            // Load file index.html từ Bundle của App
            NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
            if (htmlPath) {
                [menuWebView loadFileURL:[NSURL fileURLWithPath:htmlPath] 
                         allowingReadAccessToURL:[NSURL fileURLWithPath:[htmlPath stringByDeletingLastPathComponent]]];
            } else {
                // Nếu thiếu file HTML, tạo nút đỏ tạm thời để không bị trống
                containerView.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.8];
                containerView.layer.cornerRadius = 30;
            }

            [containerView addSubview:menuWebView];

            // 3. Thêm cử chỉ vuốt để di chuyển
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NetPingAction class] action:@selector(handleMove:)];
            [containerView addGestureRecognizer:pan];

            // 4. Chèn vào Game
            [keyWindow addSubview:containerView];
            [keyWindow bringSubviewToFront:containerView];
            
            NSLog(@"[NetPing] Đã vượt rào và khởi tạo Menu thành công.");
        }
    });
}

// Hàm khởi tạo khi dylib được nạp vào Game
__attribute__((constructor))
static void initialize() {
    // Delay 10 giây để chắc chắn Game đã load xong UI mới chèn nút
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        createNetPingOverlay();
        
        // Vòng lặp kiểm tra: Nếu bị Game vẽ đè làm mất nút, nó sẽ tự hiện lại
        [NSTimer scheduledTimerWithTimeInterval:5.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            if (containerView && containerView.superview) {
                [containerView.superview bringSubviewToFront:containerView];
            } else {
                createNetPingOverlay();
            }
        }];
    });
}
