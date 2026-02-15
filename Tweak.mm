// Tweak.mm
// Entry point của dylib NetPingPro
// Không dùng HTML/JS - Chỉ native floating buttons từ FloatButton.mm và menu.mm

#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

// Khai báo hàm từ FloatButton.mm (nút chính "NP")
extern void createMainFloatButton(void);

// Khai báo hàm từ menu.mm (3 nút Ghost/Tele/Freeze)
extern void createThreeFloatingButtons(void);

static void (*orig_applicationDidBecomeActive)(id, SEL, UIApplication *);
static BOOL hasInjectedOverlay = NO;

#pragma mark - Hooked Method

static void replaced_applicationDidBecomeActive(id self,
                                                SEL _cmd,
                                                UIApplication *application)
{
    // Gọi original trước
    if (orig_applicationDidBecomeActive) {
        orig_applicationDidBecomeActive(self, _cmd, application);
    }
    
    // Delay nhẹ để UI ổn định rồi hiện overlay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        
        if (!hasInjectedOverlay) {
            NSLog(@"[NetPingPro] App became active → Tạo nút nổi chính 'NP'");
            createMainFloatButton();  // Hiện nút "NP" từ FloatButton.mm
            
            // Optional: Nếu muốn hiện luôn 3 nút mà không cần tap "NP"
            // createThreeFloatingButtons();
            
            hasInjectedOverlay = YES;
        }
    });
}

#pragma mark - Constructor (dylib load)

__attribute__((constructor))
static void init(void)
{
    NSLog(@"[NetPingPro] Dylib loaded - Khởi tạo tweak");
    
    // Hook applicationDidBecomeActive để xử lý khi app foreground
    Class uiAppClass = objc_getClass("UIApplication");
    if (uiAppClass) {
        MSHookMessageEx(uiAppClass,
                        @selector(applicationDidBecomeActive:),
                        (IMP)replaced_applicationDidBecomeActive,
                        (IMP *)&orig_applicationDidBecomeActive);
    } else {
        NSLog(@"[NetPingPro] Không tìm thấy UIApplication class!");
    }
    
    // Delay ban đầu khi load dylib (để chắc chắn UI đã sẵn sàng)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        
        if (!hasInjectedOverlay) {
            NSLog(@"[NetPingPro] Constructor delay → Tạo nút nổi chính 'NP'");
            createMainFloatButton();
            hasInjectedOverlay = YES;
        }
    });
}