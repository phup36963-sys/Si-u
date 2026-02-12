#import "FloatButton.h"

static UIWindow *floatWindow = nil;
static FloatButton *floatBtn = nil;

@implementation FloatButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        self.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.9];
        self.layer.cornerRadius = frame.size.width / 2;
        self.clipsToBounds = YES;

        [self setTitle:@"VPN" forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        UIPanGestureRecognizer *pan =
        [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        [self addTarget:self
                 action:@selector(showMenu)
       forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

#pragma mark - Drag

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x,
                              self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
}

#pragma mark - Active Window (iOS 18 Safe)

- (UIWindow *)activeWindow {

    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]] &&
            scene.activationState == UISceneActivationStateForegroundActive) {

            UIWindowScene *ws = (UIWindowScene *)scene;

            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) return w;
            }
        }
    }
    return nil;
}

#pragma mark - Menu

- (void)showMenu {

    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"VPN Mode"
                                        message:@"Chọn chế độ"
                                 preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:@"Tele (95%)"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self sendVPNCommandRate:95 mode:@"ALL"];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Ghost (92% TCP)"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self sendVPNCommandRate:92 mode:@"TCP"];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Stop"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self sendVPNCommandRate:0 mode:@"OFF"];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    UIWindow *window = [self activeWindow];
    if (window.rootViewController) {
        [window.rootViewController presentViewController:alert
                                                animated:YES
                                              completion:nil];
    }
}

#pragma mark - Send Config (FIXED VERSION)

- (void)sendVPNCommandRate:(NSInteger)rate mode:(NSString *)mode {

    // 🔥 Dùng App Group thay vì sendProviderMessage
    NSUserDefaults *defaults =
    [[NSUserDefaults alloc] initWithSuiteName:@"group.com.netping.shared"];

    [defaults setInteger:rate forKey:@"blockRate"];
    [defaults setObject:mode forKey:@"blockMode"];
    [defaults synchronize];

    NSLog(@"[NetPing] Saved config rate=%ld mode=%@", (long)rate, mode);
}

@end

#pragma mark - Overlay

void createNetPingOverlay(void) {

    if (floatWindow) return;

    dispatch_async(dispatch_get_main_queue(), ^{

        UIWindowScene *activeScene = nil;

        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] &&
                scene.activationState == UISceneActivationStateForegroundActive) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }

        if (!activeScene) return;

        floatWindow = [[UIWindow alloc] initWithWindowScene:activeScene];
        floatWindow.frame = [UIScreen mainScreen].bounds;
        floatWindow.backgroundColor = [UIColor clearColor];
        floatWindow.windowLevel = UIWindowLevelAlert + 100;
        floatWindow.hidden = NO;

        floatBtn = [[FloatButton alloc] initWithFrame:CGRectMake(120, 250, 65, 65)];
        [floatWindow addSubview:floatBtn];
        [floatWindow makeKeyAndVisible];

        NSLog(@"[NetPing] Overlay Ready");
    });
}