ARCHS = arm64 arm64e
TARGET = iphone:clang:latest

# Vượt rào: Ép chế độ rootless để tương thích các bản iOS 18 mới
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NetPingPro

# Cấu hình file nguồn
NetPingPro_FILES = Tweak.mm FloatButton.mm
NetPingPro_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

# Frameworks cần thiết cho nút nổi và chặn mạng
NetPingPro_FRAMEWORKS = UIKit Foundation NetworkExtension CoreGraphics QuartzCore

# --- PHẦN VƯỢT RÀO CẢN ---
# Tắt Substrate để dylib chạy độc lập (tốt cho No-Jailbreak)
NetPingPro_USE_SUBSTRATE = 0

# Linker flags: 
# -dynamiclib: Đảm bảo build ra dylib chuẩn
# -undefined dynamic_lookup: Không báo lỗi nếu thiếu symbol lúc build (sẽ tìm lúc chạy)
# -segalign 4000: Tối ưu bộ nhớ để lách kiểm tra của Apple
NetPingPro_LDFLAGS = -dynamiclib -Wl,-undefined,dynamic_lookup -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk
