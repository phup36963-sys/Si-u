# Makefile cho NetPingPro dylib (rootless, inject vào app như Free Fire)
# Tối ưu cho iOS 18+ non-jailbreak 2026

ARCHS = arm64 arm64e

# Rootless scheme phải đặt sớm nhất
THEOS_PACKAGE_SCHEME = rootless

# Target: clang mới nhất, deployment iOS 15.0+ (rootless yêu cầu)
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NetPingPro

# Các file nguồn (thêm menu.mm cho 3 nút nổi)
NetPingPro_FILES = Tweak.mm FloatButton.mm menu.mm vpn.mm  # Thêm vpn.mm nếu có fake/real lag

# CFLAGS: ARC + tắt warning deprecated (phổ biến iOS 18+)
NetPingPro_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-module-import-in-extern-c

# Frameworks cần cho UI overlay, network throttle, v.v.
NetPingPro_FRAMEWORKS = UIKit Foundation NetworkExtension CoreGraphics QuartzCore AVFoundation

# Tắt Substrate (dành cho non-jb inject, dùng MSHookFunction thủ công nếu cần)
NetPingPro_USE_SUBSTRATE = 0

# Linker flags quan trọng cho dylib inject:
# -dynamiclib: build dylib
# -undefined dynamic_lookup: bỏ qua symbol lúc build (tìm runtime)
# -segalign 4000: tối ưu memory alignment (giúp lách một số check Apple)
NetPingPro_LDFLAGS = -dynamiclib -Wl,-undefined,dynamic_lookup -Wl,-segalign,4000

# Optional: Nếu dùng libroot cho rootless path (nếu cần sau này)
# NetPingPro_LIBRARIES = root

include $(THEOS_MAKE_PATH)/tweak.mk