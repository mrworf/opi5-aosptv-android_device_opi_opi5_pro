/*
 * Copyright (C) 2026
 * SPDX-License-Identifier: Apache-2.0
 */

package org.orangepi.widevineprobe;

import android.media.DeniedByServerException;
import android.media.MediaDrm;
import android.media.MediaDrmException;
import android.media.NotProvisionedException;
import android.media.ResourceBusyException;
import android.media.UnsupportedSchemeException;
import android.util.JsonWriter;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/** Minimal, non-secret Widevine L3 discovery and provisioning probe. */
public final class Main {
    private static final UUID WIDEVINE_UUID =
            new UUID(0xedef8ba979d64aceL, 0xa3c827dcd51d21edL);
    private static final int MAX_PROVISION_RESPONSE_BYTES = 2 * 1024 * 1024;

    private Main() {}

    public static void main(String[] args) {
        ProbeResult probeResult = run(args);
        writeResult(probeResult.values);
        System.exit(probeResult.exitCode);
    }

    static ProbeResult run(String[] args) {
        boolean provision = args.length == 1 && "--provision".equals(args[0]);
        if (args.length > 1 || (args.length == 1 && !provision)) {
            return failure("invalid_arguments", "IllegalArgumentException", 2);
        }

        LinkedHashMap<String, Object> result = new LinkedHashMap<>();
        result.put("schemaVersion", 1);
        result.put("widevineSupported", MediaDrm.isCryptoSchemeSupported(WIDEVINE_UUID));
        result.put("provisionRequested", provision);
        if (!Boolean.TRUE.equals(result.get("widevineSupported"))) {
            result.put("status", "unsupported");
            return new ProbeResult(result, 3);
        }

        MediaDrm drm = null;
        byte[] session = null;
        try {
            drm = new MediaDrm(WIDEVINE_UUID);
            result.put("vendor", property(drm, "vendor"));
            result.put("version", property(drm, "version"));
            result.put("description", property(drm, "description"));
            result.put("securityLevel", property(drm, "securityLevel"));
            result.put("systemId", property(drm, "systemId"));
            result.put("oemCryptoApiVersion", property(drm, "oemCryptoApiVersion"));
            result.put("secureDecoderAvc", drm.requiresSecureDecoder("video/avc"));
            result.put("secureDecoderHevc", drm.requiresSecureDecoder("video/hevc"));

            try {
                session = drm.openSession(MediaDrm.SECURITY_LEVEL_SW_SECURE_CRYPTO);
                result.put("provisioning", "already_provisioned");
            } catch (NotProvisionedException notProvisioned) {
                result.put("provisioning", "required");
                if (!provision) {
                    result.put("status", "not_provisioned");
                    return new ProbeResult(result, 4);
                }
                provision(drm, result);
                session = drm.openSession(MediaDrm.SECURITY_LEVEL_SW_SECURE_CRYPTO);
                result.put("provisioning", "completed");
            }

            int sessionLevel = drm.getSecurityLevel(session);
            result.put("sessionSecurityLevel", sessionLevel);
            boolean isL3 = "L3".equals(result.get("securityLevel"))
                    && sessionLevel == MediaDrm.SECURITY_LEVEL_SW_SECURE_CRYPTO;
            result.put("l3Verified", isL3);
            result.put("status", isL3 ? "ok" : "wrong_security_level");
            return new ProbeResult(result, isL3 ? 0 : 5);
        } catch (UnsupportedSchemeException unsupported) {
            return failure(result, "unsupported", unsupported, 3);
        } catch (ResourceBusyException busy) {
            return failure(result, "resource_busy", busy, 6);
        } catch (MediaDrmException drmError) {
            return failure(result, "drm_error", drmError, 6);
        } catch (IOException networkError) {
            return failure(result, "provision_network_error", networkError, 7);
        } catch (RuntimeException runtimeError) {
            return failure(result, "runtime_error", runtimeError, 6);
        } finally {
            if (drm != null) {
                if (session != null) {
                    try {
                        drm.closeSession(session);
                    } catch (RuntimeException ignored) {
                        // The result has already been emitted; never expose plugin details here.
                    }
                }
                drm.close();
            }
        }
    }

    private static String property(MediaDrm drm, String name) {
        try {
            return drm.getPropertyString(name);
        } catch (RuntimeException unavailable) {
            return "unavailable";
        }
    }

    private static void provision(MediaDrm drm, Map<String, Object> result)
            throws IOException, DeniedByServerException {
        MediaDrm.ProvisionRequest request = drm.getProvisionRequest();
        result.put("provisionHost", URI.create(request.getDefaultUrl()).getHost());

        // Match the platform MediaPlayer Widevine provisioning flow. The CDM's request data is
        // already encoded for use as the signedRequest query value; it is not a JSON POST body.
        String requestUrl = request.getDefaultUrl()
                + "&signedRequest="
                + new String(request.getData(), StandardCharsets.UTF_8);
        URL url = new URL(requestUrl);

        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setConnectTimeout(15_000);
        connection.setReadTimeout(15_000);
        connection.setRequestMethod("POST");
        connection.setDoOutput(false);
        connection.setDoInput(true);
        int responseCode = connection.getResponseCode();
        result.put("provisionHttpStatus", responseCode);
        if (responseCode < 200 || responseCode >= 300) {
            connection.disconnect();
            throw new IOException("provisioning HTTP request failed");
        }
        ByteArrayOutputStream response = new ByteArrayOutputStream();
        try (InputStream input = connection.getInputStream()) {
            byte[] buffer = new byte[8192];
            int count;
            while ((count = input.read(buffer)) != -1) {
                if (response.size() + count > MAX_PROVISION_RESPONSE_BYTES) {
                    throw new IOException("provision response exceeded limit");
                }
                response.write(buffer, 0, count);
            }
        } finally {
            connection.disconnect();
        }
        drm.provideProvisionResponse(response.toByteArray());
    }

    private static ProbeResult failure(
            LinkedHashMap<String, Object> result, String status, Throwable error, int exitCode) {
        result.put("status", status);
        result.put("errorClass", error.getClass().getSimpleName());
        return new ProbeResult(result, exitCode);
    }

    private static ProbeResult failure(String status, String errorClass, int exitCode) {
        LinkedHashMap<String, Object> result = new LinkedHashMap<>();
        result.put("schemaVersion", 1);
        result.put("status", status);
        result.put("errorClass", errorClass);
        return new ProbeResult(result, exitCode);
    }

    private static void writeResult(Map<String, Object> result) {
        try {
            JsonWriter writer = new JsonWriter(
                    new OutputStreamWriter(System.out, StandardCharsets.UTF_8));
            writer.setIndent("  ");
            writer.beginObject();
            for (Map.Entry<String, Object> entry : result.entrySet()) {
                writer.name(entry.getKey());
                Object value = entry.getValue();
                if (value instanceof Boolean) {
                    writer.value((Boolean) value);
                } else if (value instanceof Number) {
                    writer.value((Number) value);
                } else {
                    writer.value(String.valueOf(value));
                }
            }
            writer.endObject();
            writer.flush();
            System.out.println();
        } catch (IOException impossible) {
            System.err.println("{\"status\":\"json_output_error\"}");
        }
    }

    static final class ProbeResult {
        final LinkedHashMap<String, Object> values;
        final int exitCode;

        ProbeResult(LinkedHashMap<String, Object> values, int exitCode) {
            this.values = values;
            this.exitCode = exitCode;
        }
    }
}
