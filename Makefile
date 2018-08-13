include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SBCard

SBCard_FILES = /mnt/d/codes/SBCard/Tweak.xm
SBCard_FRAMEWORKS = CydiaSubstrate UIKit CoreGraphics
SBCard_PRIVATE_FRAMEWORKS = SpringBoardServices SpringBoardUIServices
SBCard_LDFLAGS = -Wl,-segalign,4000

export ARCHS = arm64
SBCard_ARCHS = arm64

include $(THEOS_MAKE_PATH)/tweak.mk
	
all::
