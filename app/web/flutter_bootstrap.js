{{flutter_js}}
{{flutter_build_config}}

// Served by the host's phone on the local network, maybe without internet:
// everything comes from the host, nothing from a CDN, no service worker.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
    canvasKitVariant: "full",
    // Never ask a font service for missing glyphs (privacy, and offline):
    // the app ships its fonts.
    fontFallbackBaseUrl: "assets/fallback-fonts/",
  },
});
