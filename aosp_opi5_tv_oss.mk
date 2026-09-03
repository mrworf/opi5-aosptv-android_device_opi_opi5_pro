#
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, device/opi/opi5_pro/aosp_opi5_tv_common.mk)

ifneq ($(OPI5_BUILD_PROFILE),oss)
$(error aosp_opi5_tv_oss requires OPI5_BUILD_PROFILE=oss)
endif
ifneq ($(OPI5_ENABLE_WIDEVINE),false)
$(error The OSS product cannot include Widevine)
endif

PRODUCT_NAME := aosp_opi5_tv_oss
