# Expense Tracker

Android app that reads bank SMS, tracks credits and debits, and shows a monthly picture of spending and balance.

## What it does

- Reads inbox SMS from senders whose names contain bank names like **HSBCIN**, **INDBNK** etc.
- Pulls credited and debited amounts from those messages
- Charts each day around zero: credit above, expense below
- Lets you enter your current bank balance, then shows monthly balance from that
- Saves every month’s transactions and summaries in a local SQLite database, so data stays even if SMS are deleted

SMS inbox access works on **Android** only. Allow SMS permission on first launch.

## Run

```bash
flutter pub get
flutter run
```

Use a physical Android phone. After install, allow SMS access and set your current bank balance from the wallet icon.
