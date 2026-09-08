# KREVZY Release Checklist

- Version: 1.1.0+2
- Verify Firebase Android app/package identity before release.
- Configure a real upload/release keystore; current template uses debug signing and must not be shipped to production.
- Deploy Firestore and Storage rules.
- Verify Firebase Storage bucket and upload on a physical Android device.
- Test login, password reset, saved posts, sharing, blocked accounts, active sessions, deactivate/delete, app lock and biometrics.
- Build: `flutter build appbundle --release` after signing is configured.
- Build APK for internal QA: `flutter build apk --release`.
