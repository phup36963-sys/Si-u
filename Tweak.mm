#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

#import "h5ggEngine.h"
#import "FloatButton.h"
#import "AppWinController.h"

// ===============================
// GLOBAL STATE
// ===============================

static BOOL isLagging = NO;
static BOOL isVPNActive = NO;

#pragma mark - h5ggEngine Hook

static void (*orig_setFloatTolerance)(id, SEL, NSString *);

static void new_setFloatTolerance(id self, SEL _cmd, NSString *arg1) {
    if ([arg1 floatValue] > 0) {
        isLagging = YES;
        orig_setFloatTolerance(self, _cmd, @"0.0000000001");
    } else {
        isLagging = NO;
        orig_setFloatTolerance(self, _cmd, arg1);
    }
}

#pragma mark - AppWinController Hook

static void (*orig_startVPNService)(id, SEL);

static void new_startVPNService(id self, SEL _cmd) {
    isVPNActive = YES;
    NSLog(@"[DVS] VPN Simulator Started");
    
    if (orig_startVPNService) {
        orig_startVPNService(self, _cmd);
    }
}

#pragma mark - FloatButton Hooks

static void (*orig_setHidden)(id, SEL, BOOL);
static void new_setHidden(id self, SEL _cmd, BOOL hidden) {
    orig_setHidden(self, _cmd, hidden);
}

static void (*orig_updatePosition)(id, SEL, CGPoint);
static void new_updatePosition(id self, SEL _cmd, CGPoint point) {
    orig_updatePosition(self, _cmd, point);
}

#pragma mark - Constructor

__attribute__((constructor))
static void init() {
    NSLog(@"[DVS] NetPing Dylib Initialized for iOS 18");

    Class engineClass = objc_getClass("h5ggEngine");
    if (engineClass) {
        MSHookMessageEx(engineClass,
                        @selector(setFloatTolerance:),
                        (IMP)new_setFloatTolerance,
                        (IMP *)&orig_setFloatTolerance);
    }

    Class vpnClass = objc_getClass("AppWinController");
    if (vpnClass) {
        MSHookMessageEx(vpnClass,
                        @selector(startVPNService),
                        (IMP)new_startVPNService,
                        (IMP *)&orig_startVPNService);
    }

    Class floatClass = objc_getClass("FloatButton");
    if (floatClass) {
        MSHookMessageEx(floatClass,
                        @selector(setHidden:),
                        (IMP)new_setHidden,
                        (IMP *)&orig_setHidden);

        MSHookMessageEx(floatClass,
                        @selector(updatePosition:),
                        (IMP)new_updatePosition,
                        (IMP *)&orig_updatePosition);
    }

    // Delay 5s tránh crash khi game load
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSLog(@"[DVS] Delayed UI injection ready");
    });
}