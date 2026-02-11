#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "h5ggEngine.h"
#import "FloatButton.h"
#import "AppWinController.h"

// Biến quản lý trạng thái
static BOOL isLagging = NO;
static BOOL isVPNActive = NO;

// --- 1. LOGIC FAKE LAG (NGỪNG) ---
// Tận dụng hàm setFloatTolerance trong h5ggEngine để làm chậm tiến trình
%hook h5ggEngine
- (void)setFloatTolerance:(NSString *)arg1 {
    if ([arg1 floatValue] > 0) {
        isLagging = YES;
        // Ghi đè giá trị cực nhỏ để ép Engine quét liên tục gây độ trễ mạng giả
        %orig(@"0.0000000001"); 
    } else {
        isLagging = NO;
        %orig;
    }
}
%end

// --- 2. LOGIC VPN (FAKE STATUS) ---
// Giả lập trạng thái kết nối thông qua lớp vỏ Controller
%hook AppWinController
- (void)startVPNService {
    isVPNActive = YES;
    // Có thể thêm code thực tế để bóp băng thông tại đây
    NSLog(@"[DVS] VPN Simulator Started");
}
%end

// --- 3. LOGIC NÚT NỔI (FLOAT BUTTON) ---
// Điều khiển ẩn/hiện và vị trí dựa trên FloatButton.h
%hook FloatButton
- (void)setHidden:(_Bool)arg1 {
    // Nếu đang trong trận, có thể ép nút luôn hiện để tránh lỗi mất nút
    %orig(arg1);
}

- (void)updatePosition:(struct CGPoint)point {
    // Lưu tọa độ để không bị văng khỏi màn hình khi xoay
    %orig(point);
}
%end

// --- KHỞI TẠO (CONSTRUCTOR) ---
%ctor {
    NSLog(@"[DVS] NetPing Dylib Initialized for iOS 18");
    
    // Trì hoãn nạp Menu 5 giây để tránh lỗi văng "aaaaa" khi mở game
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Code để nạp menu.html vào UIWindow
    });
}
