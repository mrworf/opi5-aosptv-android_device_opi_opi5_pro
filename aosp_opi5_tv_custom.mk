#
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, device/opi/opi5_pro/aosp_opi5_tv_common.mk)

ifneq ($(OPI5_BUILD_PROFILE),custom)
$(error aosp_opi5_tv_custom requires OPI5_BUILD_PROFILE=custom)
endif

OPI5_GAPPS_MK := vendor/gapps_tv/arm64/arm64-vendor.mk
ifeq ($(wildcard $(OPI5_GAPPS_MK)),)
$(error Custom profile requires GApps at $(OPI5_GAPPS_MK))
endif
GMS_VARIANT := minimal
$(call inherit-product, $(OPI5_GAPPS_MK))

ifeq ($(OPI5_ENABLE_WIDEVINE),true)
OPI5_WIDEVINE_MK := vendor/opi/widevine_local/widevine-vendor.mk
ifeq ($(wildcard $(OPI5_WIDEVINE_MK)),)
$(error Widevine is enabled but $(OPI5_WIDEVINE_MK) is missing)
endif
PRODUCT_SOONG_NAMESPACES += vendor/opi/widevine_local
$(call inherit-product, $(OPI5_WIDEVINE_MK))
else ifneq ($(OPI5_ENABLE_WIDEVINE),false)
$(error OPI5_ENABLE_WIDEVINE must be true or false)
endif

PRODUCT_NAME := aosp_opi5_tv_custom
