// vpn.mm - Fake/Real Lag Menu for Free Fire (NetPingPro style)

#import <UIKit/UIKit.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <dlfcn.h>  // cho hook dynamic
#import <pthread.h>  // cho delay thread

// Global vars
static UIWindow *overlayWindow = nil;
static UIButton *floatButton = nil;
static UIView *menuPanel = nil;
static BOOL menuVisible = NO;
static BOOL fakeLagEnabled = NO;
static BOOL realLagEnabled = NO;
static int fakeLagDelayMs = 200;  // ms delay giả lag

// Hook send/recv để fake lag (delay packet)
static ssize_t (*orig_send)(int socket, const void *buffer, size_t length, int flags);
static ssize_t hooked_send(int socket, const void *buffer, size_t length, int flags) {
    if (fakeLagEnabled) {
        usleep(fakeLagDelayMs * 1000);  // Delay giả lag (usleep an toàn hơn sleep)
    }
    return orig_send(socket, buffer, length, flags);
}

static ssize_t (*orig_recv)(int socket, void *buffer, size_t length, int flags);
static ssize_t hooked_recv(int socket, void *buffer, size_t length, int flags) {
    if (fakeLagEnabled) {
        usleep(fakeLagDelayMs * 1000);
    }
    return orig_recv(socket, buffer, length, flags);
}

// Hook cho real lag (thử throttle - khó hơn, cần network extension hoặc VPN profile)
// Note: Real VPN cần config .mobileconfig và user confirm, không tự động hoàn toàn
// Ở đây chỉ simulate bằng cách drop packet ngẫu nhiên (fake real lag)
static ssize_t hooked_recv_drop(int socket, void *buffer, size_t length, int flags) {
    if (realLagEnabled && (arc4random_uniform(100) < 30)) {  // 30% chance drop packet
        return -1;  // Simulate disconnect/lag spike
    }
    return orig_recv(socket, buffer, length, flags);
}

// Tạo menu
%hook UnityAppController  // Hook class chính của Free Fire (Unity game)

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL orig = %orig;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.windowLevel = UIWindowLevelAlert + 2000;  // Cao để overlay game
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.userInteractionEnabled = YES;
        overlayWindow.hidden = NO;

        // Floating Button
        floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        floatButton.frame = CGRectMake(30, 120, 80, 80);
        floatButton.layer.cornerRadius = 40;
        floatButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.75];
        floatButton.layer.borderWidth = 3;
        floatButton.layer.borderColor = [UIColor whiteColor].CGColor;
        [floatButton setTitle:@"VPN" forState:UIControlStateNormal];
        floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [floatButton addTarget:self action:@selector(toggleVpnMenu) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragButton:)];
        [floatButton addGestureRecognizer:pan];

        [overlayWindow addSubview:floatButton];

        // Menu Panel
        menuPanel = [[UIView alloc] initWithFrame:CGRectMake(40, 220, 320, 380)];
        menuPanel.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.3 alpha:0.85];
        menuPanel.layer.cornerRadius = 24;
        menuPanel.layer.borderWidth = 2;
        menuPanel.layer.borderColor = [UIColor colorWithRed:0 green:1 blue:1 alpha:1].CGColor;
        menuPanel.hidden = YES;

        // Toggle Fake Lag
        UISwitch *fakeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(220, 40, 0, 0)];
        [fakeSwitch addTarget:self action:@selector(toggleFakeLag:) forControlEvents:UIControlEventValueChanged];
        UILabel *fakeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 180, 30)];
        fakeLabel.text = @"Fake Lag (Delay)";
        fakeLabel.textColor = [UIColor whiteColor];
        fakeLabel.font = [UIFont systemFontOfSize:16];
        [menuPanel addSubview:fakeLabel];
        [menuPanel addSubview:fakeSwitch];

        // Toggle Real Lag (simulate drop)
        UISwitch *realSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(220, 90, 0, 0)];
        [realSwitch addTarget:self action:@selector(toggleRealLag:) forControlEvents:UIControlEventValueChanged];
        UILabel *realLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, 180, 30)];
        realLabel.text = @"Real Lag (Drop Pkt)";
        realLabel.textColor = [UIColor whiteColor];
        realLabel.font = [UIFont systemFontOfSize:16];
        [menuPanel addSubview:realLabel];
        [menuPanel addSubview:realSwitch];

        // Slider delay ms
        UISlider *delaySlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 140, 280, 30)];
        delaySlider.minimumValue = 50;
        delaySlider.maximumValue = 800;
        delaySlider.value = fakeLagDelayMs;
        [delaySlider addTarget:self action:@selector(updateDelay:) forControlEvents:UIControlEventValueChanged];
        UILabel *delayLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 170, 280, 30)];
        delayLabel.text = [NSString stringWithFormat:@"Delay: %d ms", fakeLagDelayMs];
        delayLabel.textColor = [UIColor cyanColor];
        delayLabel.tag = 999;
        [menuPanel addSubview:delaySlider];
        [menuPanel addSubview:delayLabel];

        [overlayWindow addSubview:menuPanel];
    });

    return orig;
}

%new
- (void)toggleVpnMenu {
    menuVisible = !menuVisible;
    menuPanel.hidden = !menuVisible;
}

%new
- (void)dragButton:(UIPanGestureRecognizer *)gesture {
    CGPoint trans = [gesture translationInView:overlayWindow];
    floatButton.center = CGPointMake(floatButton.center.x + trans.x, floatButton.center.y + trans.y);
    [gesture setTranslation:CGPointZero inView:overlayWindow];
}

%new
- (void)toggleFakeLag:(UISwitch *)sender {
    fakeLagEnabled = sender.isOn;
    NSLog(@"Fake Lag: %d", fakeLagEnabled);
}

%new
- (void)toggleRealLag:(UISwitch *)sender {
    realLagEnabled = sender.isOn;
    NSLog(@"Real Lag (Drop): %d", realLagEnabled);
}

%new
- (void)updateDelay:(UISlider *)slider {
    fakeLagDelayMs = (int)slider.value;
    UILabel *label = [menuPanel viewWithTag:999];
    label.text = [NSString stringWithFormat:@"Delay: %d ms", fakeLagDelayMs];
}

%end

// Hook network functions (chạy sớm)
%ctor {
    NSLog(@"[VPN.mm] Loaded - Fake/Real Lag Menu Ready!");

    // Hook send/recv (cần tìm đúng symbol, hoặc dùng MSHookFunction)
    void *handle = RTLD_DEFAULT;
    orig_send = (ssize_t (*)(int, const void *, size_t, int))dlsym(handle, "send");
    MSHookFunction((void *)orig_send, (void *)hooked_send, (void **)&orig_send);

    orig_recv = (ssize_t (*)(int, void *, size_t, int))dlsym(handle, "recv");
    MSHookFunction((void *)orig_recv, (void *)hooked_recv, (void **)&orig_recv);

    // Optional: Hook recv drop cho real lag
    // MSHookFunction((void *)orig_recv, (void *)hooked_recv_drop, (void **)&orig_recv);
}