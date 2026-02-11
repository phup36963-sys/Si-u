#import <UIKit/UIKit.h>

@interface AppWinController : UIViewController
{
    UIViewController *_bindVC;
}

@property(retain) UIViewController *bindVC;
- (void)startVPNService; // Hàm mod thêm cho nút VPN
- (long long)preferredInterfaceOrientationForPresentation;
- (unsigned long long)supportedInterfaceOrientations;
- (_Bool)shouldAutorotate;
- (id)initWithBind:(id)arg1;
@end
