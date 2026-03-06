# Arya Notes (Flutter + Firebase)

Secure notes app with:
- Firebase Auth
- Firestore sync
- Local offline storage
- Client-side encryption before Firestore write

## Security Setup (Before Run)

1. Generate Firebase client config locally:
```bash
flutterfire configure
```

2. Keep these files local only (already in `.gitignore`):
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

3. Set encryption secret at runtime (required):
```bash
flutter run --dart-define=NOTES_ENCRYPTION_PEPPER="your-long-random-secret"
```

Use at least 16 characters. Prefer 32+ random characters.

## Firestore Rules (Required)

Use strict per-user rules:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/notes/{noteId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Run

```bash
flutter pub get
flutter run --dart-define=NOTES_ENCRYPTION_PEPPER="your-long-random-secret"
```

## GitHub Upload Commands

If this project is not a git repo yet:

```bash
git init
git add .
git commit -m "Initial secure commit"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

If you already committed sensitive files earlier, untrack and rotate keys:

```bash
git rm --cached android/app/google-services.json lib/firebase_options.dart
git commit -m "Remove sensitive Firebase config from git tracking"
git push
```

Then regenerate Firebase configs locally with `flutterfire configure`.
# Arya-Notes
