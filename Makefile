export ARCHS = armv7 armv7s arm64 arm64e
export TARGET = iphone:clang:latest:9.0

FLEX_FOLDER_PATH = $(THEOS_PROJECT_DIR)/FLEX

after-clean::
	rm -rf $(FLEX_FOLDER_PATH)

before-all::
	if [ ! -d $(FLEX_FOLDER_PATH) ]; then git clone https://github.com/Flipboard/FLEX.git $(FLEX_FOLDER_PATH); fi

include $(THEOS)/makefiles/common.mk

dtoim = $(foreach dir,$(1),-I$(dir))

TWEAK_NAME = FLEXall
FLEXall_FRAMEWORKS = CoreGraphics UIKit ImageIO QuartzCore
FLEXall_FILES = Tweak.xm $(shell find $(FLEX_FOLDER_PATH)/CLASSES -name '*.m' -o -name '*.mm')
Flexall_LIBRARIES = sqlite3 z
FLEXall_CFLAGS += -fobjc-arc -w $(call dtoim, $(shell find $(FLEX_FOLDER_PATH)/CLASSES -type d))

include $(THEOS_MAKE_PATH)/tweak.mk

before-stage::
	find . -name ".DS_Store" -delete

after-install::
	install.exec "killall -9 SpringBoard"
