# TORVO V2 VERIFIED BUILD AND PREVIEW CONTRACT

This applies only to `torvo-v2-build`. It does not authorize changes to `main` / V27.

1. Every CI build checks out the exact triggering commit SHA, not a moving branch tip.
2. Dealer authentication contract verification runs before V2 web and Android builds.
3. Every preview artifact contains `torvo-build-sha.txt` so the built source can be identified exactly.
4. Preview artifacts remain available even when Netlify credentials are not configured. Missing Netlify secrets are an external deployment dependency, not a source-build failure.
5. A live Netlify preview is claimed only when credentials exist, deployment succeeds, and the live `torvo-build-sha.txt` equals the triggering commit SHA.
6. Android debug artifacts embed the same source SHA before Capacitor sync and are checked after sync.
7. Android artifacts remain DEBUG-VERIFIED until production signing/AAB/Play requirements are completed. A debug APK must never be described as a production release.
8. Production/domain switch remains blocked until staging/backend migrations, real auth providers, end-to-end checks, release signing and Owner approval are complete.

## CURRENT EXTERNAL PREVIEW DEPENDENCY
The Netlify workflow can build and upload an exact verified preview artifact without secrets. Live Netlify deployment additionally requires repository `NETLIFY_AUTH_TOKEN` and `NETLIFY_SITE_ID` secrets.
