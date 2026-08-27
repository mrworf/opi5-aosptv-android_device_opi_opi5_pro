/* Copyright (C) 2026 The Android Open Source Project
 * SPDX-License-Identifier: Apache-2.0
 */
#include "core-impl/A2dpManualSync.h"

#include <gtest/gtest.h>

namespace aidl::android::hardware::audio::core::a2dp_manual_sync {
namespace {

TEST(A2dpManualSyncTest, OffPreservesExistingLatency) {
    Settings settings;
    settings.manualSync = ManualSyncMode::OFF;
    settings.delayMode = DelayMode::ABSOLUTE;
    settings.absoluteDelayMs = 700;
    EXPECT_EQ(37, calculateLatencyMs(settings, true, 400, 37, 210));
}

TEST(A2dpManualSyncTest, OnRelativeUsesValidReportAndAdjustment) {
    Settings settings{ManualSyncMode::ON, DelayMode::RELATIVE, -40, 200};
    EXPECT_EQ(360, calculateLatencyMs(settings, true, 400, 400, 210));
}

TEST(A2dpManualSyncTest, OnRelativeUsesFallbackForMissingReport) {
    Settings settings{ManualSyncMode::ON, DelayMode::RELATIVE, 30, 200};
    EXPECT_EQ(240, calculateLatencyMs(settings, true, 0, 0, 210));
    EXPECT_EQ(240, calculateLatencyMs(settings, false, 0, 200, 210));
}

TEST(A2dpManualSyncTest, OnAbsoluteIgnoresReportAndFallback) {
    Settings settings{ManualSyncMode::ON, DelayMode::ABSOLUTE, 0, 330};
    EXPECT_EQ(330, calculateLatencyMs(settings, true, 400, 400, 210));
    EXPECT_EQ(330, calculateLatencyMs(settings, false, 0, 200, 210));
}

TEST(A2dpManualSyncTest, AutoPassesThroughValidReport) {
    Settings settings{ManualSyncMode::AUTO, DelayMode::ABSOLUTE, 0, 330};
    EXPECT_EQ(400, calculateLatencyMs(settings, true, 400, 400, 210));
}

TEST(A2dpManualSyncTest, AutoUsesConfiguredModeWithoutValidReport) {
    Settings relative{ManualSyncMode::AUTO, DelayMode::RELATIVE, 30, 200};
    Settings absolute{ManualSyncMode::AUTO, DelayMode::ABSOLUTE, 0, 330};
    EXPECT_EQ(240, calculateLatencyMs(relative, true, 0, 0, 210));
    EXPECT_EQ(330, calculateLatencyMs(absolute, true, 0, 0, 210));
}

TEST(A2dpManualSyncTest, DelayReportBoundariesAreRejected) {
    EXPECT_FALSE(isValidDelayReport(false, 400));
    EXPECT_FALSE(isValidDelayReport(true, 0));
    EXPECT_FALSE(isValidDelayReport(true, 50));
    EXPECT_TRUE(isValidDelayReport(true, 51));
    EXPECT_TRUE(isValidDelayReport(true, 999));
    EXPECT_FALSE(isValidDelayReport(true, 1000));
}

TEST(A2dpManualSyncTest, ManualValuesAndResultAreClamped) {
    Settings low{ManualSyncMode::ON, DelayMode::RELATIVE, -500, 200};
    Settings high{ManualSyncMode::ON, DelayMode::RELATIVE, 500, 200};
    Settings absolute{ManualSyncMode::ON, DelayMode::ABSOLUTE, 0, 5000};
    EXPECT_EQ(0, calculateLatencyMs(low, false, 0, 0, 100));
    EXPECT_EQ(1250, calculateLatencyMs(high, false, 0, 0, 1200));
    EXPECT_EQ(1000, calculateLatencyMs(absolute, false, 0, 0, 210));
}

TEST(A2dpManualSyncTest, MalformedSettingsUseSafeDefaults) {
    const Settings settings = parseSettings("invalid", "invalid", "12ms", "none");
    EXPECT_EQ(ManualSyncMode::OFF, settings.manualSync);
    EXPECT_EQ(DelayMode::RELATIVE, settings.delayMode);
    EXPECT_EQ(0, settings.relativeDelayMs);
    EXPECT_EQ(200, settings.absoluteDelayMs);

    const Settings clamped = parseSettings("on", "absolute", "-900", "5000");
    EXPECT_EQ(ManualSyncMode::ON, clamped.manualSync);
    EXPECT_EQ(DelayMode::ABSOLUTE, clamped.delayMode);
    EXPECT_EQ(-250, clamped.relativeDelayMs);
    EXPECT_EQ(1000, clamped.absoluteDelayMs);
}

TEST(A2dpManualSyncTest, AppliesOnlyToA2dpOutput) {
    EXPECT_TRUE(shouldApply(false, true));
    EXPECT_FALSE(shouldApply(true, true));
    EXPECT_FALSE(shouldApply(false, false));
}

}  // namespace
}  // namespace aidl::android::hardware::audio::core::a2dp_manual_sync
