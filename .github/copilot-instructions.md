# Mushtarayati AI Coding Agent Instructions

## Project Overview
- **Mushtarayati** is a Flutter application. The main entry point is `lib/main.dart`.
- The codebase follows standard Flutter/Dart conventions, but may have custom patterns in `lib/app/` for modularization.
- Platform-specific code is in `android/`, `ios/`, `linux/`, `macos/`, `windows/`, and `web/` folders.

## Architecture & Patterns
- **App Structure:**
  - `lib/app/` contains subfolders for bindings, core logic, data, modules, and routes. Each subfolder represents a major feature or service boundary.
  - Use feature-based organization: keep related screens, logic, and data together.
- **State Management:**
  - If using GetX, Provider, or Bloc, look for bindings and module patterns in `lib/app/bindings/` and `lib/app/modules/`.
- **Routing:**
  - Centralized in `lib/app/routes/`. Define all navigation routes here.
- **Firebase Integration:**
  - Firebase config is in `lib/firebase_options.dart` and `android/app/google-services.json`.
  - `firebase.json` and platform-specific plugin folders in `build/` indicate use of Firebase services (auth, firestore, etc).

## Developer Workflows
- **Build:**
  - Run `flutter build <platform>` (e.g., `flutter build apk`, `flutter build ios`).
- **Run:**
  - Use `flutter run` for local development.
- **Test:**
  - Tests are in `test/`. Run with `flutter test`.
- **Platform Assets:**
  - Customize launch screens and icons in platform asset folders (e.g., `ios/Runner/Assets.xcassets`).

## Conventions & Practices
- **Feature Folders:**
  - Place all code for a feature (UI, logic, data) in a single module folder under `lib/app/modules/`.
- **Bindings:**
  - Use bindings in `lib/app/bindings/` to connect controllers/services to UI.
- **Routes:**
  - Define and update navigation routes only in `lib/app/routes/`.
- **Firebase:**
  - Update config in `lib/firebase_options.dart` and platform-specific files when adding new Firebase services.
- **Assets:**
  - Store images in `assets/images/`, fonts in `assets/fonts/`.

## External Dependencies
- **Flutter/Dart:**
  - Managed via `pubspec.yaml`.
- **Firebase:**
  - Integrated via config files and plugins.

## Example Patterns
- To add a new feature:
  1. Create a new module in `lib/app/modules/`.
  2. Add related bindings in `lib/app/bindings/`.
  3. Register routes in `lib/app/routes/`.
- To add a new asset:
  1. Place the file in `assets/images/` or `assets/fonts/`.
  2. Register in `pubspec.yaml` under `assets:` or `fonts:`.

---
**If any section is unclear or missing important project-specific details, please provide feedback or point to files that contain more conventions.**
