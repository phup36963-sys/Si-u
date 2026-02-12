#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>
#import "FloatButton.h"

static void (*orig_applicationDidBecomeActive)(id, SEL, UIApplication *);
static BOOL hasInjectedOverlay = NO;

static void replaced_applicationDidBecomeActive(id self,
                                                SEL _cmd,
                                                UIApplication *application)
{
    if (orig_applicationDidBecomeActive) {
        orig_applicationDidBecomeActive(self, _cmd, application);
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(0.8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        if (!hasInjectedOverlay) {
            restoreOverlayIfNeeded();
            hasInjectedOverlay = YES;
        }
    });
}

__attribute__((constructor))
static void init()
{
    NSLog(@"[NetPing] Loaded");

    Class uiAppClass = objc_getClass("UIApplication");

    if (uiAppClass) {
        MSHookMessageEx(uiAppClass,
                        @selector(applicationDidBecomeActive:),
                        (IMP)replaced_applicationDidBecomeActive,
                        (IMP *)&orig_applicationDidBecomeActive);
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{

        if (!hasInjectedOverlay) {
            restoreOverlayIfNeeded();
            hasInjectedOverlay = YES;
        }
    });
}