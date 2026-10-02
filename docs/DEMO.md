# Demo walkthrough (2-3 minutes)

1. 0:00-0:20: introduce the overview and local-only storage.
2. 0:20-0:45: open camera, show framing/focus/flash controls; import a receipt image when using an emulator.
3. 0:45-1:10: crop the receipt and run actual ML Kit OCR; review the extracted fields and measured latency.
4. 1:10-1:35: correct a field, choose a category and save; open Expenses and show the cached receipt.
5. 1:35-2:00: restart the app and show that SQLite retained the record.
6. 2:00-2:30: open Insights, tap categories and bars; explain calendar month and seven-day summaries.
7. 2:30-2:45: show editing/deletion and conclude with repository/APK links.

The supplied receipt fixture is synthetic and contains no real financial data. An emulator gallery import is real image OCR; the text-parser sample dialog is separately labelled and is not OCR evidence. Physical camera accuracy and a universal sub-100 ms result require device testing.
