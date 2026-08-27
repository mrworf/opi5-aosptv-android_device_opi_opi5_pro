/* Copyright (C) 2026 The Android Open Source Project
 * SPDX-License-Identifier: Apache-2.0
 */
#pragma once

#include <cstdint>
#include <string_view>

namespace aidl::android::hardware::audio::core::a2dp_manual_sync {

enum class ManualSyncMode { OFF, ON, AUTO };
enum class DelayMode { RELATIVE, ABSOLUTE };

struct Settings {
    ManualSyncMode manualSync = ManualSyncMode::OFF;
    DelayMode delayMode = DelayMode::RELATIVE;
    int32_t relativeDelayMs = 0;
    int32_t absoluteDelayMs = 200;
};

constexpr int32_t kMinimumValidReportMs = 50;
constexpr int32_t kMaximumValidReportMs = 1000;
constexpr int32_t kMaximumEffectiveLatencyMs = 1250;
constexpr int32_t kExtraAudioSyncMs = 200;

Settings readSettings();

Settings parseSettings(std::string_view manualSync, std::string_view delayMode,
                       std::string_view relativeDelay, std::string_view absoluteDelay);

bool shouldApply(bool isInput, bool isA2dp);

bool isValidDelayReport(bool positionAvailable, int64_t delayReportMs);

int32_t calculateLatencyMs(const Settings& settings, bool positionAvailable,
                           int64_t delayReportMs, int32_t existingLatencyMs,
                           int32_t fallbackLatencyMs);

}  // namespace aidl::android::hardware::audio::core::a2dp_manual_sync
