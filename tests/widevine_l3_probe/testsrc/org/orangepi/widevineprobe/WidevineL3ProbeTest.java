/*
 * Copyright (C) 2026
 * SPDX-License-Identifier: Apache-2.0
 */

package org.orangepi.widevineprobe;

import static org.junit.Assert.assertEquals;

import android.app.Instrumentation;
import android.os.Bundle;

import androidx.test.InstrumentationRegistry;
import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.Map;

/** Runs the Widevine probe with a real Android application package identity. */
@RunWith(AndroidJUnit4.class)
public final class WidevineL3ProbeTest {
    @Test
    public void verifyWidevineL3() {
        Instrumentation instrumentation = InstrumentationRegistry.getInstrumentation();
        boolean provision = Boolean.parseBoolean(
                InstrumentationRegistry.getArguments().getString("provision", "false"));
        Main.ProbeResult result = Main.run(
                provision ? new String[] {"--provision"} : new String[0]);

        Bundle status = new Bundle();
        for (Map.Entry<String, Object> entry : result.values.entrySet()) {
            status.putString("widevine." + entry.getKey(), String.valueOf(entry.getValue()));
        }
        instrumentation.sendStatus(0, status);

        String expected = provision ? "ok" : "not_provisioned";
        String actual = String.valueOf(result.values.get("status"));
        if (!"ok".equals(actual)) {
            assertEquals(expected, actual);
        }
    }
}
