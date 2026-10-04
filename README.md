# PocketReceipt

**Little receipts. A clearer picture.** An offline-first Flutter expense tracker built for Mini-Project 3.

- [Live browser companion](https://pocketreceipt-demo.onrender.com)
- [Android APK, demonstration video and technical report](https://github.com/it2kvku/pocketreceipt-ocr-expense-tracker/releases/latest)

The Android app performs real on-device image OCR. The browser companion supports typed receipt parsing, CRUD and charts with browser persistence; it explicitly does **not** claim browser ML Kit OCR or SQLite.

## Features

- Live camera, torch toggle, tap-to-focus and framing overlay. Gallery import handles devices without a camera.
- Adjustable crop edges with a live selection overlay. EXIF orientation is normalized and cropped images are capped at 1800 pixels wide.
- Google ML Kit Latin text recognition using its bundled Android model. No OCR service, API key or receipt upload.
- Regex/heuristic extraction of merchant, DD/MM/YYYY date and labelled VND totals. Supports `150,000 VND`, `150.000 đ`, grouped spaces and zero decimal fractions.
- Conservative parsing excludes subtotal, VAT, cash, change and discounts. Missing or ambiguous fields prompt review; values remain editable.
- SQLite persistence, private receipt JPEGs and 160-pixel thumbnail caching. Create, edit, search, category filter and confirmed delete.
- Food, Study, Travel, Gear and Entertainment categories.
- Animated, interactive donut and seven-day bar charts implemented directly with `CustomPainter`, no chart package. Month summaries use calendar months; bars use local calendar days.
- Empty, loading and error states. Optional clearly marked sample data; first launch starts empty.

## Setup

Tested toolchain: Flutter **3.47.5**, Dart **3.13.4**, Android SDK and Java 17+. Install a compatible Flutter 3.x release supporting Dart 3.13.4 or newer. Android minimum SDK 24. The repository targets Android and web; iOS is not configured or tested.

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d <android-device-id>
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
flutter run -d chrome
flutter build web --release --base-href /pocketreceipt-ocr-expense-tracker/
```

The mini-project APK uses Flutter's development signing configuration for easy sideloading. It is a release-mode build, not a Play Store distribution. Production publication requires a private upload key and signing configuration. Never commit keystores or passwords.

## Try it

1. Install the APK and open PocketReceipt. Grant camera permission when scanning.
2. Tap **Scan a receipt**, photograph a well-lit receipt (or import a JPEG/PNG), and adjust crop sliders.
3. Tap **Crop & recognize**. Review merchant, amount, date and category against the receipt. The displayed latency measures the ML Kit call, including platform overhead.
4. Save, reopen from Expenses, edit, search/filter or delete. Restart the app to check persistence.
5. Open Insights; tap donut segments, category chips or bars.
6. Use the top-right menu to add sample expenses or paste receipt text. These are demo helpers and do not impersonate an OCR scan.

## Architecture

```text
lib/
  domain/     Expense model, categories, pure receipt parser
  data/       Conditional store: SQLite/files on Android, preferences on web
  services/   ML Kit lifecycle, text extraction and measured call latency
  ui/         Capture/crop, review, overview/history, CustomPainter charts
test/         Parser edge cases, SQLite lifecycle, widget validation
docs/         Screenshots, technical report and demo instructions
```

Flow: camera/gallery bytes -> EXIF-aware crop -> private JPEG -> ML Kit -> raw text -> heuristic parser -> manual review -> SQLite -> summaries -> canvas charts. Recognition runs asynchronously; crop work uses a Dart isolate. Money is stored as integer VND, never floating point. Receipt and thumbnail files are removed on cancellation/deletion. Android backup is disabled, and the release manifest does not request network access.

SQLite schema v1: `expenses(id TEXT PRIMARY KEY, merchant TEXT, amount INTEGER CHECK(amount>0), date TEXT, category TEXT, receiptPath TEXT, rawText TEXT)`. Dates are local ISO calendar dates. There is no account, server, telemetry, cloud backup or synchronization. Browser storage can be cleared by the browser; uninstalling Android removes local records.

## Verification and honest limits

Automated tests cover grouped currency formats, invalid amounts/dates, Vietnamese totals, split-line totals, ambiguous totals, missing totals, category suggestions, SQLite insert/update/reopen/delete, review validation and empty charts. Screenshots and the video demonstrate the built app; see the report for measured results.

Sub-100 ms OCR is a **performance target**, not a universal guarantee. Cold model initialization, emulator speed, image resolution, lighting and device hardware affect latency. Benchmark release builds on physical devices before claiming the target. Recognition can misread accents, faint print or skewed receipts. The heuristic parser is not a trained receipt understanding model; review is always required. Currency support is intentionally VND only. Default category is Food when no keyword matches.

The assignment's official report template was not supplied. The included four-page report follows the requested feature checklist, architecture, screenshots and verification structure.

## Primary references

- [ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition/v2/android)
- [Flutter ML Kit plugin](https://pub.dev/packages/google_mlkit_text_recognition) (community maintained)
- [Camera](https://pub.dev/packages/camera), [sqflite](https://pub.dev/packages/sqflite)
- [Flutter CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)

MIT license. Built for educational demonstration.

