# web/ scaffold

This is a minimal Flutter Web scaffold (index.html + manifest.json) — the
original upload didn't include a `web/` folder, so this recreates the
standard one Flutter needs to build for the browser.

Two things to do before your first web build:

1. **Icons**: this folder references `favicon.png` and `icons/Icon-192.png`,
   `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png` which
   aren't included (no source logo image was in the upload). Either run
   `flutter create . --platforms web` from the project root once (it will
   fill in default Flutter icons without touching your existing code), or
   drop your own PNGs into `web/icons/` with those exact names.
2. Build with your real keys:
   ```bash
   flutter build web --dart-define-from-file=env.local.json
   firebase deploy --only hosting
   ```
