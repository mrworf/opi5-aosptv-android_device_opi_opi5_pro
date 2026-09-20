#
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, device/opi/opi5_pro/device.mk)

ifeq ($(strip $(OPI5_PRODUCT_PROFILE_MK)),)
$(error OPI5_PRODUCT_PROFILE_MK is required; build through the opi5_tv workspace)
endif
ifeq ($(wildcard $(OPI5_PRODUCT_PROFILE_MK)),)
$(error OPI5 product profile does not exist: $(OPI5_PRODUCT_PROFILE_MK))
endif
include $(OPI5_PRODUCT_PROFILE_MK)

ifneq ($(OPI5_BUILD_VARIANT),$(TARGET_BUILD_VARIANT))
$(error OPI5_BUILD_VARIANT=$(OPI5_BUILD_VARIANT) does not match TARGET_BUILD_VARIANT=$(TARGET_BUILD_VARIANT))
endif

ifeq ($(strip $(OPI5_ADB_KEYS)),)
$(error OPI5_ADB_KEYS is required; run ./configure-adb-key in the opi5_tv workspace)
endif
ifeq ($(wildcard $(OPI5_ADB_KEYS)),)
$(error OPI5 ADB public key does not exist: $(OPI5_ADB_KEYS))
endif
PRODUCT_ADB_KEYS := $(OPI5_ADB_KEYS)
ifeq ($(TARGET_BUILD_VARIANT),user)
PRODUCT_COPY_FILES += \
    $(OPI5_ADB_KEYS):$(TARGET_COPY_OUT_PRODUCT)/etc/security/adb_keys
endif

OPI5_RELEASE_CONFIG_MAP := build/release/opi5/release_config_map.textproto
ifeq ($(wildcard $(OPI5_RELEASE_CONFIG_MAP)),)
$(error Missing Orange Pi 5 release configuration: $(OPI5_RELEASE_CONFIG_MAP))
endif
PRODUCT_RELEASE_CONFIG_MAPS += $(OPI5_RELEASE_CONFIG_MAP)

PRODUCT_AAPT_PREF_CONFIG := tvdpi
PRODUCT_CHARACTERISTICS := tv

# Canonical user-visible hardware name. First-boot Settings, Bluetooth, and
# Wi-Fi defaults derive from PRODUCT_MODEL instead of carrying independent
# board-name strings.
OPI5_PRODUCT_DISPLAY_NAME := Orange Pi 5

PRODUCT_PRODUCT_PROPERTIES += \
    persist.bluetooth.a2dp_aac.vbr_supported=true \
    persist.device_config.mglru_native.lru_gen_config=core \
    ro.lockscreen.disable.default=true

# Rockchip's legacy gralloc discovery still uses hw_get_module(), which probes
# ro.arch before the architecture-specific HAL variants. Define the standard
# build property so the probe does not fall through to default_prop under
# enforcing SELinux.
PRODUCT_SYSTEM_PROPERTIES += ro.arch=arm64

ifneq ($(TARGET_BUILD_VARIANT),user)
PRODUCT_PRODUCT_PROPERTIES += logd.logpersistd=logcatd
endif

PRODUCT_ENABLE_TV_IOWATCHDOG := false
$(call inherit-product, device/google/atv/products/atv_base.mk)
$(call enforce-product-packages-exist,com.android.ranging vendor_tracing_descriptors)

PRODUCT_PACKAGES += \
    DocumentsUI \
    LeanbackIME \
    TvSampleLeanbackLauncher \
    TvSettingsTwoPanel

PRODUCT_VENDOR_PROPERTIES += \
    bluetooth.device.class_of_device=34,4,36 \
    bluetooth.power.suspend.disconnect_acl.enabled=true \
    bluetooth.power.suspend.scan_mode_none.enabled=true \
    bluetooth.power.suspend.stop_le_scan.enabled=true \
    bluetooth.power.suspend.pause_advertisement.enabled=true

# This framework setting belongs on the product partition.  Putting it in
# vendor.prop makes vendor_init attempt to set an untyped system property,
# which enforcing SELinux correctly rejects.
PRODUCT_PRODUCT_PROPERTIES += \
    persist.settings.large_screen_opt.enabled=true

PRODUCT_COPY_FILES += \
    device/google/atv/products/bootanimations/bootanimation.zip:$(TARGET_COPY_OUT_SYSTEM)/media/bootanimation.zip

PRODUCT_PACKAGES += \
    AndroidTvOpiFrameworkOverlay \
    AndroidTvNativeResolutionOverlay \
    AndroidTvOpiOverlay \
    BluetoothOpiOverlay \
    SettingsProviderTvOpiOverlay \
    WifiOpiOverlay

# TARGET_DEVICE must retain the upstream directory name so Android can locate
# BoardConfig.mk. Public product, model, image, and DTB names identify OPI5.
PRODUCT_DEVICE := opi5_pro
PRODUCT_BRAND := opi5-aosptv
PRODUCT_MODEL := $(OPI5_PRODUCT_DISPLAY_NAME)
PRODUCT_MANUFACTURER := Community
