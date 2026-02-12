#import <UIKit/UIKit.h>
#import "FloatButton.h"

%hook UIApplication

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        restoreOverlayIfNeeded();
    });
}

%end

__attribute__((constructor))
static void init() {

    NSLog(@"[NetPing] Loaded");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        createNetPingOverlay();
    });
}