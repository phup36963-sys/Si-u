#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>
#import "FloatButton.h"

#pragma mark - Globals

static void (*orig_applicationDidBecomeActive)(id, SEL, UIApplication *);
static BOOL overlayInitialized = NO;

#pragma mark - Safe Overlay Restore

static void restoreOverlayIfNeeded(void) {

    if (overlayInitialized) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        createNetPingOverlay();
        overlayInitialized = YES;
    });
}

#pragma mark - Hooked Method

static void replaced_applicationDidBecomeActive(id self,
                                                SEL _cmd,
                                                UIApplication *application) {

    // Gọi original trước
    orig_applicationDidBecomeActive(self, _cmd, application);

    // Delay nhỏ tránh crash khi app vừa resume
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(0.8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        restoreOverlayIfNeeded();
    });
}

#pragma mark - Constructor

__attribute__((constructor))
static void init() {

    NSLog(@"[NetPing] Pro Max Loaded");

    Class uiAppClass = objc_getClass("UIApplication");

    if (uiAppClass) {
        MSHookMessageEx(uiAppClass,
                        @selector(applicationDidBecomeActive:),
                        (IMP)replaced_applicationDidBecomeActive,
                        (IMP *)&orig_applicationDidBecomeActive);

        NSLog(@"[NetPing] Hooked UIApplication");
    }

    // Tạo overlay lần đầu sau khi load tweak
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        restoreOverlayIfNeeded();
    });
}