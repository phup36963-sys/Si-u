# Thiết lập cho iPhone 13 (A15 - arm64e)
export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk
THEOS = /opt/theos
TWEAK_NAME = NetPingPro
NetPingPro_FILES = Tweak.mm
NetPingPro_CFLAGS = -fobjc-arc -I./include
NetPingPro_FRAMEWORKS = UIKit Foundation JavaScriptCore CoreGraphics SystemConfiguration

include $(THEOS_MAKE_PATH)/tweak.mk
