# This is a makefile which can be used to compile chickmunk for Android.
# You'll also need an Android-build for chipmunk. You can find a 
# suggestion of how to do that here: https://gist.github.com/2628615

LOCAL_HOME := $(dir $(lastword $(MAKEFILE_LIST)))

#include ./jni/dependencies.mk

$(shell cd $(LOCAL_HOME) ; csc -t -s chickmunk.scm -J)
$(shell cd $(LOCAL_HOME) ; csc -t -s chickmunk.import.scm)
$(shell cd $(LOCAL_HOME) ; csc -t -s chickmunk-draw.scm -J)
$(shell cd $(LOCAL_HOME) ; csc -t -s chickmunk-draw.import.scm)

include $(CLEAR_VARS)
LOCAL_MODULE := chickmunk
LOCAL_PATH := $(LOCAL_HOME)
LOCAL_CFLAGS := -DCP_USE_DOUBLES=0
LOCAL_SRC_FILES := chickmunk.c
LOCAL_SHARED_LIBRARIES := chicken chipmunk
include $(BUILD_SHARED_LIBRARY)


include $(CLEAR_VARS)
LOCAL_MODULE := chickmunk-draw
LOCAL_PATH := $(LOCAL_HOME)
LOCAL_CFLAGS := -std=c99 -DCP_USE_DOUBLES=0
LOCAL_LDLIBS := -lEGL -lGLESv1_CM -llog
LOCAL_SRC_FILES := chickmunk-draw.c ChipmunkDebugDraw.c
LOCAL_SHARED_LIBRARIES := chicken chipmunk
include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := chickmunk.import
LOCAL_PATH := $(LOCAL_HOME)
LOCAL_SRC_FILES := chickmunk.import.c
LOCAL_SHARED_LIBRARIES := chicken
include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := chickmunk-draw.import
LOCAL_PATH := $(LOCAL_HOME)
LOCAL_SRC_FILES := chickmunk-draw.import.c
LOCAL_SHARED_LIBRARIES := chicken
include $(BUILD_SHARED_LIBRARY)


$(call import-add-path,/home/klm/prog/chicken/)
$(call import-add-path,/home/klm/opt/Chipmunk-Physics/modules/)

$(call import-module,chicken)
$(call import-module,chipmunk)
