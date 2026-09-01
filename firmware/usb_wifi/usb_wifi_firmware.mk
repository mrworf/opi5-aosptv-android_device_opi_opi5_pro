# Pinned USB Wi-Fi firmware. Keep this list synchronized with manifest.json;
# scripts/usb_wifi_bundle.py verifies the complete set and hashes.

# These destinations are already owned by Android's prebuilt_firmware modules.
# Selecting their packages here makes the generated install rules materialize in
# vendor.img without conflicting PRODUCT_COPY_FILES entries.
PRODUCT_PACKAGES += \
    linux_firmware_mt7921 \
    linux_firmware_mt7925 \
    linux_firmware_rt2800usb \
    linux_firmware_rtw88-rtw8822c

OPI5_USB_WIFI_FIRMWARE_FILES := \
    ar5523.bin \
    ath9k_htc/htc_7010-1.4.0.fw \
    ath9k_htc/htc_9271-1.4.0.fw \
    brcm/brcmfmac43143.bin \
    brcm/brcmfmac43236b.bin \
    brcm/brcmfmac43242a.bin \
    brcm/brcmfmac43569.bin \
    brcm/brcmfmac4373.bin \
    carl9170-1.fw \
    mediatek/mt7610e.bin \
    mediatek/mt7610u.bin \
    mt7601u.bin \
    mt7662.bin \
    mt7662_rom_patch.bin \
    rt73.bin \
    rtlwifi/rtl8188eufw.bin \
    rtlwifi/rtl8188fufw.bin \
    rtlwifi/rtl8192cufw.bin \
    rtlwifi/rtl8192cufw_A.bin \
    rtlwifi/rtl8192cufw_B.bin \
    rtlwifi/rtl8192cufw_TMSC.bin \
    rtlwifi/rtl8192eu_nic.bin \
    rtlwifi/rtl8192fufw.bin \
    rtlwifi/rtl8710bufw_SMIC.bin \
    rtlwifi/rtl8710bufw_UMC.bin \
    rtlwifi/rtl8723aufw_A.bin \
    rtlwifi/rtl8723aufw_B.bin \
    rtlwifi/rtl8723aufw_B_NoBT.bin \
    rtlwifi/rtl8723bu_bt.bin \
    rtlwifi/rtl8723bu_nic.bin \
    rtw88/rtw8723d_fw.bin \
    rtw88/rtw8812a_fw.bin \
    rtw88/rtw8814a_fw.bin \
    rtw88/rtw8821a_fw.bin \
    rtw88/rtw8821c_fw.bin \
    rtw88/rtw8822b_fw.bin \
    rtw89/rtw8851b_fw.bin \
    rtw89/rtw8852b_fw-1.bin

PRODUCT_COPY_FILES += $(foreach file,$(OPI5_USB_WIFI_FIRMWARE_FILES),\
    $(DEVICE_PATH)/firmware/usb_wifi/files/$(file):$(TARGET_COPY_OUT_VENDOR)/firmware/$(file))

OPI5_USB_WIFI_FIRMWARE_LICENSES := \
    GPL-2.0 \
    LICENCE.atheros_firmware \
    LICENCE.broadcom_bcm43xx \
    LICENCE.mediatek \
    LICENCE.open-ath9k-htc-firmware \
    LICENCE.ralink-firmware.txt \
    LICENCE.ralink_a_mediatek_company_firmware \
    LICENCE.rtlwifi_firmware.txt

PRODUCT_COPY_FILES += $(foreach file,$(OPI5_USB_WIFI_FIRMWARE_LICENSES),\
    $(DEVICE_PATH)/firmware/usb_wifi/licenses/$(file):$(TARGET_COPY_OUT_VENDOR)/etc/firmware/usb_wifi/licenses/$(file))

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/firmware/usb_wifi/manifest.json:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/usb_wifi/manifest.json \
    $(DEVICE_PATH)/firmware/usb_wifi/WHENCE:$(TARGET_COPY_OUT_VENDOR)/etc/firmware/usb_wifi/WHENCE
