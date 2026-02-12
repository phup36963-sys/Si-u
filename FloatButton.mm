#import "FloatWindow.h"

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

#pragma mark - Touch Passthrough

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

    UIView *view = [super hitTest:point withEvent:event];

    if (view == self) {
        return nil;
    }

    return view;
}

@end