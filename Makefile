ARCHS = arm64 arm64e
TARGET = iphone:clang:latest

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NetPingPro

NetPingPro_FILES = Tweak.mm FloatButton.mm
NetPingPro_CFLAGS = -fobjc-arc
NetPingPro_FRAMEWORKS = UIKit Foundation NetworkExtension

include $(THEOS_MAKE_PATH)/tweak.mk