
LOCAL_HOME := $(call my-dir)

#include ./jni/dependencies.mk

include $(CLEAR_VARS)
LOCAL_MODULE := chickmunk
LOCAL_PATH := $(LOCAL_HOME)/..
LOCAL_SRC_FILES := chickmunk.c
LOCAL_SHARED_LIBRARIES := chicken
LOCAL_SHARED_LIBRARIES += chipmunk
#remove lib prefix:
LOCAL_MODULE_FILENAME := chickmunk
include $(BUILD_SHARED_LIBRARY)

$(call import-add-path,/home/klm/prog/chicken/android-chicken/modules/)
$(call import-add-path,/home/klm/opt/Chipmunk-Physics/modules/)

$(call import-module,chicken)
$(call import-module,chipmunk)
