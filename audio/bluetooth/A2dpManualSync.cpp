/* Copyright (C) 2026 The Android Open Source Project
 * SPDX-License-Identifier: Apache-2.0
 */
#include "core-impl/A2dpManualSync.h"

#include <algorithm>
#include <charconv>
#include <cstdint>
#include <string_view>

#if defined(__BIONIC__)
#include <android-base/properties.h>
#endif

namespace aidl::android::hardware::audio::core::a2dp_manual_sync {
namespace {

constexpr int32_t kMinimumRelativeDelayMs = -250;
constexpr int32_t kMaximumRelativeDelayMs = 250;
constexpr int32_t kMinimumAbsoluteDelayMs = 0;
constexpr int32_t kMaximumAbsoluteDelayMs = 1000;

ManualSyncMode parseManualSync(std::string_view value) {
    if (value == "on") return ManualSyncMode::ON;
    if (value == "auto") return ManualSyncMode::AUTO;
    return ManualSyncMode::OFF;
}

DelayMode parseDelayMode(std::string_view value) {
    return value == "absolute" ? DelayMode::ABSOLUTE : DelayMode::RELATIVE;
}

int32_t parseClampedInt(std::string_view value, int32_t defaultValue, int32_t minimum,
                        int32_t maximum) {
    int32_t parsed = defaultValue;
    const auto [end, error] = std::from_chars(value.data(), value.data() + value.size(), parsed);
    if (error != std::errc() || end != value.data() + value.size()) parsed = defaultValue;
    return std::clamp(parsed, minimum, maximum);
}

#if defined(__BIONIC__)
int32_t parseRelativeDelay(const char* value) {
    return parseClampedInt(value, 0, kMinimumRelativeDelayMs, kMaximumRelativeDelayMs);
}

int32_t parseAbsoluteDelay(const char* value) {
    return parseClampedInt(value, 200, kMinimumAbsoluteDelayMs, kMaximumAbsoluteDelayMs);
}
#endif

}  // namespace

Settings readSettings() {
#if defined(__BIONIC__)
    static ::android::base::CachedParsedProperty manualSync(
            "persist.bluetooth.a2dp_manual_sync", parseManualSync);
    static ::android::base::CachedParsedProperty delayMode(
            "persist.bluetooth.a2dp_delay_mode", parseDelayMode);
    static ::android::base::CachedParsedProperty relativeDelay(
            "persist.bluetooth.a2dp_relative_delay_ms", parseRelativeDelay);
    static ::android::base::CachedParsedProperty absoluteDelay(
            "persist.bluetooth.a2dp_absolute_delay_ms", parseAbsoluteDelay);
    return {
            .manualSync = manualSync.Get(),
            .delayMode = delayMode.Get(),
            .relativeDelayMs = relativeDelay.Get(),
            .absoluteDelayMs = absoluteDelay.Get(),
    };
#else
    return {};
#endif
}

Settings parseSettings(std::string_view manualSync, std::string_view delayMode,
                       std::string_view relativeDelay, std::string_view absoluteDelay) {
    return {
            .manualSync = parseManualSync(manualSync),
            .delayMode = parseDelayMode(delayMode),
            .relativeDelayMs = parseClampedInt(relativeDelay, 0, kMinimumRelativeDelayMs,
                                               kMaximumRelativeDelayMs),
            .absoluteDelayMs = parseClampedInt(absoluteDelay, 200, kMinimumAbsoluteDelayMs,
                                               kMaximumAbsoluteDelayMs),
    };
}

bool shouldApply(bool isInput, bool isA2dp) {
    return !isInput && isA2dp;
}

bool isValidDelayReport(bool positionAvailable, int64_t delayReportMs) {
    return positionAvailable && delayReportMs > kMinimumValidReportMs &&
            delayReportMs < kMaximumValidReportMs;
}

int32_t calculateLatencyMs(const Settings& settings, bool positionAvailable,
                           int64_t delayReportMs, int32_t existingLatencyMs,
                           int32_t fallbackLatencyMs) {
    if (settings.manualSync == ManualSyncMode::OFF) return existingLatencyMs;

    const bool validReport = isValidDelayReport(positionAvailable, delayReportMs);
    if (settings.manualSync == ManualSyncMode::AUTO && validReport) {
        return static_cast<int32_t>(delayReportMs);
    }

    int64_t latencyMs;
    if (settings.delayMode == DelayMode::ABSOLUTE) {
        latencyMs = std::clamp(settings.absoluteDelayMs, kMinimumAbsoluteDelayMs,
                               kMaximumAbsoluteDelayMs);
    } else {
        const int64_t baseLatencyMs = validReport ? delayReportMs : fallbackLatencyMs;
        latencyMs = baseLatencyMs +
                std::clamp(settings.relativeDelayMs, kMinimumRelativeDelayMs,
                           kMaximumRelativeDelayMs);
    }
    return static_cast<int32_t>(std::clamp<int64_t>(latencyMs, 0,
                                                    kMaximumEffectiveLatencyMs));
}

}  // namespace aidl::android::hardware::audio::core::a2dp_manual_sync
