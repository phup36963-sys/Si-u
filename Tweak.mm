#import <UIKit/UIKit.h>
#import <substrate.h>
#import "FloatButton.h"

__attribute__((constructor))
static void init() {

    NSLog(@"[NetPing] Tweak Loaded");

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        createNetPingOverlay();
    });
}