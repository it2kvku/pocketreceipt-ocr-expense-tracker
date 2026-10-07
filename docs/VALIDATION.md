# Release validation — 8 October 2026

- Flutter 3.47.5 / Dart 3.13.4; local analyzer: no issues; 29 tests passed.
- Android release APK built and installed on Pixel_10a emulator.
- Native ML Kit image OCR: synthetic GREEN MART receipt, 150000 VND, 07/10/2026 all extracted correctly. Displayed call latency: 6552 ms.
- Saved receipt survived force-stop and relaunch in SQLite.
- Video demonstrates crop, actual OCR, review, save, restart, sample-labelled charts and expense history in 150 seconds.
- Browser parser/save/reload and chart selection checked separately. Browser uses preferences, not SQLite or image OCR.
- R8 release configuration preserves ML Kit component registrars. Android release manifest has no network or audio-recording permission.
- Physical camera/flash/focus and sub-100 ms performance are not verified. APK uses development signing for educational sideloading.
- Commit timestamps represent actual work; scheduled follow-up audits through 12 October create commits only for meaningful changes.
