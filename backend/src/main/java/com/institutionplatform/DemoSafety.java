package com.institutionplatform;

import java.util.Locale;

/** Guardrails against accidentally creating public demo accounts in a real DB. */
final class DemoSafety {
    private DemoSafety() {}

    static void requireLocalDemoDatabase(String jdbcUrl) {
        String url = jdbcUrl == null ? "" : jdbcUrl.trim().toLowerCase(Locale.ROOT);
        boolean safe = url.matches(
                "^jdbc:postgresql://(?:localhost|127\\.0\\.0\\.1)(?::[0-9]+)?/institution_platform_demo(?:\\?.*)?$");
        if (!safe) {
            throw new IllegalStateException(
                    "Demo profile is restricted to a local institution_platform_demo database. "
                    + "Do not run public demo credentials against a real or remote database.");
        }
    }
}
