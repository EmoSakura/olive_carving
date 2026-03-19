# Olive Carving

Flutter project for the olive-carving interactive experience.

## Local build

Install dependencies and build the Android release APK:

```bash
flutter pub get
flutter build apk --release
```

The generated APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## GitHub release build

This repository includes a GitHub Actions workflow at `.github/workflows/android-release.yml`.

- Manual build: run the `Android Release` workflow from the Actions tab to generate a downloadable APK artifact.
- Release build: push a tag such as `v1.0.0` and GitHub Actions will build the APK and attach it to the GitHub Release automatically.

## Signing note

`android/app/build.gradle.kts` currently signs release builds with the default debug signing config so the APK can be built and downloaded immediately. If you want stable update signatures or store distribution later, replace this with your own release keystore.
