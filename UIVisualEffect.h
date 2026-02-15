// UIVisualEffect.h (private header - approximate reconstruction)
// Không chính thức từ Apple - chỉ dùng tham khảo cho tweak/dev

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class UIVisualEffect, _UIVisualEffectConfig, _UIVisualEffectBackdropView, _UIVisualEffectSubviewTraits;

@interface UIVisualEffect : NSObject <NSCopying, NSSecureCoding>

+ (instancetype)effectWithStyle:(NSInteger)style; // Internal style enum

@property (nonatomic, readonly) NSInteger effectStyle; // iOS 8+
@property (nonatomic, copy, nullable) _UIVisualEffectConfig *effectConfig;

- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (void)encodeWithCoder:(NSCoder *)coder;

@end

// Các subclass chính (public nhưng liên quan)
@interface UIBlurEffect : UIVisualEffect
+ (UIBlurEffect *)effectWithStyle:(UIBlurEffectStyle)style;
@end

@interface UIVibrancyEffect : UIVisualEffect
+ (UIVibrancyEffect *)effectForBlurEffect:(UIBlurEffect *)blurEffect;
+ (UIVibrancyEffect *)effectForBlurEffect:(UIBlurEffect *)blurEffect style:(UIVibrancyEffectStyle)style NS_AVAILABLE_IOS(10_0);
@end

// Private config (thường hook để custom blur radius/intensity)
@interface _UIVisualEffectConfig : NSObject
@property (nonatomic, assign) CGFloat blurRadius;         // Custom radius (iOS 9+ hack)
@property (nonatomic, assign) CGFloat saturationDeltaFactor;
@property (nonatomic, assign) CGFloat brightness;         // Tint/brightness adjust
// ... nhiều property khác như color matrix, vibrancy config
@end

// Traits cho subview (vibrancy)
@interface _UIVisualEffectSubviewTraits : NSObject
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, assign) CGFloat saturation;
@end

NS_ASSUME_NONNULL_END