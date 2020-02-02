export ARCHS = armv7 armv7s arm64 arm64e
export TARGET = iphone:clang:latest:9.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FLEXall
FLEXall_FRAMEWORKS = UIKit
FLEXall_FILES = Tweak.xm
FLEXall_CFLAGS += -fobjc-arc -w

include $(THEOS_MAKE_PATH)/tweak.mk

before-stage::
	find . -name ".DS_Store" -delete

after-install::
	install.exec "killall -9 SpringBoard"
