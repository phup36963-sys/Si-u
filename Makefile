ARCHS = arm64 arm64e
TARGET = iphone:clang:latest

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NetPingPro

NetPingPro_FILES = Tweak.mm
NetPingPro_CFLAGS = -fobjc-arc -I./include
NetPingPro_FRAMEWORKS = UIKit Foundation JavaScriptCore CoreGraphics SystemConfiguration

include $(THEOS_MAKE_PATH)/tweak.mk