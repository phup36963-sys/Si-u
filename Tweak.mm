#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

#import "FloatButton.h"

static UIWindow *floatWindow = nil;
static FloatButton *floatBtn = nil;

#pragma mark - Create Floating UI (iOS 13+ Scene Safe)

static void createFloatingButton() {

    if (floatWindow) return;

    dispatch_async(dispatch_get_main_queue(), ^{

        NSLog(@"[NetPing] Creating Float Window");

        // Lấy active UIWindowScene (iOS 13+)
        UIWindowScene *activeScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] &&
                scene.activationState == UISceneActivationStateForegroundActive) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }

        if (!activeScene) {
            NSLog(@"[NetPing] No active scene found");
            return;
        }

        floatWindow = [[UIWindow alloc] initWithWindowScene:activeScene];
        floatWindow.frame = [UIScreen mainScreen].bounds;
        floatWindow.backgroundColor = [UIColor clearColor];
        floatWindow.windowLevel = UIWindowLevelAlert + 100;
        floatWindow.hidden = NO;

        floatBtn = [[FloatButton alloc] initWithFrame:CGRectMake(120, 250, 65, 65)];
        floatBtn.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.85];
        floatBtn.layer.cornerRadius = 32.5;
        floatBtn.clipsToBounds = YES;

        [floatBtn setTitle:@"NP" forState:UIControlStateNormal];
        [floatBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        // Drag Gesture
        UIPanGestureRecognizer *pan =
        [[UIPanGestureRecognizer alloc] initWithTarget:floatBtn
                                                action:@selector(handlePan:)];
        [floatBtn addGestureRecognizer:pan];

        [floatWindow addSubview:floatBtn];
        [floatWindow makeKeyAndVisible];

        NSLog(@"[NetPing] Float Button Created");
    });
}

#pragma mark - Drag Implementation

@interface FloatButton (Drag)
- (void)handlePan:(UIPanGestureRecognizer *)gesture;
@end

@implementation FloatButton (Drag)

- (void)handlePan:(UIPanGestureRecognizer *)gesture {

    CGPoint translation = [gesture translationInView:self.superview];

    self.center = CGPointMake(self.center.x + translation.x,
                              self.center.y + translation.y);

    [gesture setTranslation:CGPointZero inView:self.superview];
}

@end

#pragma mark - Constructor

__attribute__((constructor))
static void init() {

    NSLog(@"[NetPing] Dylib Loaded (iOS 18+)");

    // Delay tránh crash khi game chưa active scene
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{

        createFloatingButton();

    });
}