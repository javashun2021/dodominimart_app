# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (choose a device/platform)
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze (lint)
flutter analyze

# Get dependencies
flutter pub get

# Build for a specific platform
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
flutter build windows    # Windows
```

## Architecture

This is a Flutter app targeting Android, iOS, Web, macOS, Linux, and Windows. The entry point is `lib/main.dart`. All application code lives under `lib/`.

The project currently uses the default Flutter counter scaffold and has no additional dependencies beyond `cupertino_icons`. Linting is configured via `flutter_lints` (see `analysis_options.yaml`).

State management and routing have not yet been introduced — add packages to `pubspec.yaml` and run `flutter pub get` as the app grows.
