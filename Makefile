ARCHS = arm64 arm64e
TARGET = iphone:clang:latest

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NetPingPro

NetPingPro_FILES = Tweak.mm FloatButton.mm
NetPingPro_CFLAGS = -fobjc-arc
NetPingPro_FRAMEWORKS = UIKit Foundation NetworkExtension

# Quan trọng: tránh hard link substrate
NetPingPro_LDFLAGS += -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk