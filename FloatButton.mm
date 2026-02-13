#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <WebKit/WebKit.h> // Header quan trọng cho HTML
#import "FloatWindow.h"
#import "FloatButton.h"

// --- Interface xử lý Action ---
@interface NetPingAction : NSObject <WKScriptMessageHandler>
+ (void)handleMove:(UIPanGestureRecognizer *)p;
@end

// --- Biến Static quản lý ---
static UIView *containerView = nil; // Thay đổi từ UIButton thành UIView để chứa Web
static WKWebView *menuWebView = nil;
static BOOL isMenuOpen = NO;

@implementation NetPingAction

// Xử lý di chuyển nút
+ (void)handleMove:(UIPanGestureRecognizer *)p {
    if (containerView) {
        CGPoint t = [p translationInView:containerView.superview];
        containerView.center = CGPointMake(containerView.center.x + t.x, containerView.center.y + t.y);
        [p setTranslation:CGPointZero inView:containerView.superview];
    }
}

// Nhận lệnh từ HTML (Bridge)
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"netping"]) {
        NSDictionary *data = message.body;
        NSString *action = data[@"action"];
        
        if ([action isEqualToString:@"toggleOverlay"]) {
            // Xử lý đóng mở menu hoặc các lệnh khác
            NSLog(@"[NetPing] Action received: %@", action);
        }
    }
}
@end

#pragma mark - Overlay Logic

void createNetPingOverlay(void) {
    if (containerView) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        
        // Cố gắng tìm KeyWindow của Game
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
            // 1. Khởi tạo Container (Cái hộp chứa nút và Web)
            containerView = [[UIView alloc] initWithFrame:CGRectMake(50, 150, 60, 60)];
            containerView.backgroundColor = [UIColor clearColor];
            containerView.layer.zPosition = MAXFLOAT; // Ép lên đỉnh cao nhất

            // 2. Cấu hình WKWebView (Nạp file HTML)
            WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
            NetPingAction *handler = [[NetPingAction alloc] init];
            [config.userContentController addScriptMessageHandler:handler name:@"netping"];

            menuWebView = [[WKWebView alloc] initWithFrame:containerView.bounds configuration:config];
            
            // --- THIẾT LẬP VƯỢT RÀO CẢN MÀU ĐEN ---
            menuWebView.opaque = NO; // Trong suốt
            menuWebView.backgroundColor = [UIColor clearColor];
            menuWebView.scrollView.backgroundColor = [UIColor clearColor];
            menuWebView.scrollView.bounces = NO; // Tắt kéo dãn
            
            // Bypass Safe Area (Xóa bỏ mảng đen tai thỏ/đáy màn hình)
            if (@available(iOS 11.0, *)) {
                menuWebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
            
            // Nạp nội dung HTML
            NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
            if (htmlPath) {
                [menuWebView loadFileURL:[NSURL fileURLWithPath:htmlPath] allowingReadAccessToURL:[NSURL fileURLWithPath:[htmlPath stringByDeletingLastPathComponent]]];
            } else {
                // Nếu không có file, hiện chữ NP tạm thời
                UILabel *label = [[UILabel alloc] initWithFrame:containerView.bounds];
                label.text = @"NP";
                label.textAlignment = NSTextAlignmentCenter;
                label.textColor = [UIColor whiteColor];
                label.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.9];
                label.layer.cornerRadius = 30;
                label.clipsToBounds = YES;
                [containerView addSubview:label];
            }

            [containerView addSubview:menuWebView];

            // 3. Gesture di chuyển
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NetPingAction class] action:@selector(handleMove:)];
            [containerView addGestureRecognizer:pan];

            // 4. Ép vào Window chính
            [keyWindow addSubview:containerView];
            [keyWindow bringSubviewToFront:containerView];
            
            NSLog(@"[NetPing] HTML Menu Injected & Black Bars Fixed.");
        }
    });
}

// Constructor tự động chạy
__attribute__((constructor))
static void initialize() {
    // Delay 10s để tránh bị hệ thống quét Window lúc khởi động
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        createNetPingOverlay();
        
        // Vòng lặp cưỡng bức (Keep-Alive)
        [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            if (containerView && containerView.superview) {
                [containerView.superview bringSubviewToFront:containerView];
            } else {
                createNetPingOverlay();
            }
        }];
    });
}
