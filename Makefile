messages=yes

ifeq ($(shell [ -f ./framework/makefiles/common.mk ] && echo 1 || echo 0),0)
all clean package install::
	git submodule update --init
	./framework/git-submodule-recur.sh init
	$(MAKE) $(MAKEFLAGS) MAKELEVEL=0 $@
else

TWEAK_NAME = RemindMeLater
RemindMeLater_OBJC_FILES = RemindMeLater.mm RMLSnoozer.m RMLAlertView.m RMLController.m obslider/OBSlider/OBSlider.m
RemindMeLater_FRAMEWORKS = UIKit AVFoundation AudioToolbox CoreGraphics
RemindMeLater_LDFLAGS = -lsubstrate

BUNDLE_NAME = RemindMeLaterSettings
RemindMeLaterSettings_OBJC_FILES = RemindMeLaterSettings.m
RemindMeLaterSettings_INSTALL_PATH = /System/Library/PreferenceBundles
RemindMeLaterSettings_FRAMEWORKS = UIKit CoreGraphics QuartzCore
RemindMeLaterSettings_PRIVATE_FRAMEWORKS = Preferences

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
include framework/makefiles/bundle.mk

endif
