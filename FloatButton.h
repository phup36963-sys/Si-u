#import <UIKit/UIKit.h>

@interface FloatButton : UIButton
{
    struct CGPoint _lastPoint;
}

@property struct CGPoint lastPoint;
- (void)updatePosition:(struct CGPoint)point;
- (void)setHidden:(_Bool)arg1;
- (id)initWithFrame:(struct CGRect)arg1;
@end
