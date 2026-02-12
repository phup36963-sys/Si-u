#import <UIKit/UIKit.h>
#import "FloatWindow.h"
#import "FloatButton.h"

#pragma mark - FloatWindow Implementation

@implementation FloatWindow

- (instancetype)initWithWindowScene:(UIWindowScene *)scene {
    self = [super initWithWindowScene:scene];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.windowLevel = UIWindowLevelStatusBar + 2;
        self.hidden = NO;
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self) {
        return nil;
    }
    return view;
}

@end


#pragma mark - Overlay Logic

static FloatWindow *overlayWindow = nil;
static UIButton *floatButton = nil;

void createNetPingOverlay(void)
{
    if (overlayWindow) return;

    UIWindowScene *activeScene = nil;

    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]] &&
            scene.activationState == UISceneActivationStateForegroundActive) {
            activeScene = (UIWindowScene *)scene;
            break;
        }
    }

    if (!activeScene) return;

    overlayWindow = [[FloatWindow alloc] initWithWindowScene:activeScene];
    overlayWindow.frame = [UIScreen mainScreen].bounds;

    floatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    floatButton.frame = CGRectMake(120, 300, 65, 65);
    floatButton.backgroundColor =
        [[UIColor systemBlueColor] colorWithAlphaComponent:0.9];
    floatButton.layer.cornerRadius = 32.5;
    floatButton.clipsToBounds = YES;

    [floatButton setTitle:@"VPN" forState:UIControlStateNormal];
    [floatButton setTitleColor:UIColor.whiteColor
                      forState:UIControlStateNormal];

    [overlayWindow addSubview:floatButton];
    overlayWindow.hidden = NO;
}

void restoreOverlayIfNeeded(void)
{
    if (!overlayWindow) {
        createNetPingOverlay();
    }
}