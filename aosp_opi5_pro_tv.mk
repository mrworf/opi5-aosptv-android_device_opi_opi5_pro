#
# Copyright (C) 2021-2023 KonstaKANG
# Copyright (C) 2025 Venkata Atchuta Bheemeswara Sarma Darbha
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit device configuration
$(call inherit-product, device/opi/opi5_pro/device.mk)

# Pre-authorize the build workstation without disabling ADB authentication.
PRODUCT_ADB_KEYS := device/opi/opi5_pro/adb_keys

PRODUCT_AAPT_PREF_CONFIG := tvdpi
PRODUCT_CHARACTERISTICS := tv

# Preserve logcat under /data/misc/logd so a failed headless boot can be
# diagnosed by attaching the NVMe to the build workstation.
PRODUCT_PRODUCT_PROPERTIES += \
    logd.logpersistd=logcatd

# This TV has no Car watchdog service or resource-overuse configuration.
PRODUCT_ENABLE_TV_IOWATCHDOG := false
$(call inherit-product, device/google/atv/products/atv_base.mk)
$(call enforce-product-packages-exist,com.android.ranging vendor_tracing_descriptors)

# Google TV services and Play Store, without replacing the AOSP TV launcher.
GMS_VARIANT := minimal
$(call inherit-product, vendor/gapps_tv/arm64/arm64-vendor.mk)

# Android TV
PRODUCT_PACKAGES += \
    DocumentsUI \
    LeanbackIME \
    TvProvision \
    TvSampleLeanbackLauncher \
    TvSettingsTwoPanel

# Bluetooth
PRODUCT_VENDOR_PROPERTIES += \
    bluetooth.device.class_of_device=34,4,36

# Boot animation
PRODUCT_COPY_FILES += \
    device/google/atv/products/bootanimations/bootanimation.zip:$(TARGET_COPY_OUT_SYSTEM)/media/bootanimation.zip

# Overlays
PRODUCT_PACKAGES += \
    AndroidTvNativeResolutionOverlay \
    AndroidTvOpiOverlay \
    BluetoothOpiOverlay \
    SettingsProviderTvOpiOverlay \
    WifiOpiOverlay

# Device identifier. This must come after all inclusions.
PRODUCT_DEVICE := opi5_pro
PRODUCT_NAME := aosp_opi
PRODUCT_BRAND := Orangepi
PRODUCT_MODEL := Orange Pi 5
PRODUCT_MANUFACTURER := Orangepi
