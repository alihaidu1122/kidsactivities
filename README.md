## Kids Activities Estonia (Flutter + Firebase)

This repo is a production-oriented Flutter app connected to Firebase Auth + Firestore + Storage, supporting role-based access for:

- **Parent**
- **Provider**
- **Admin**

### Firebase setup (required)

This repo includes placeholder `lib/firebase_options.dart`. Replace it with the generated file:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then ensure your Firebase project has:

- **Authentication**: Email/Password enabled
- **Firestore** enabled (EU region recommended)
- **Storage** enabled

### Running the app

```bash
flutter pub get
flutter run
```

### Backend (rules + functions)

Firebase deploy files are in [`firebase/`](firebase/):

- [`firebase/firestore.rules`](firebase/firestore.rules)
- [`firebase/storage.rules`](firebase/storage.rules)
- [`firebase/firebase.json`](firebase/firebase.json)
- Cloud Functions source in [`firebase/functions/`](firebase/functions/)

Build functions locally:

```bash
cd firebase/functions
npm install
npm run build
```

Seed categories (runs against your Firebase project credentials/environment):

```bash
cd firebase/functions
npm run seed:categories
```

### Roles (RBAC)

RBAC is enforced using **Firebase Auth custom claims** (`role: parent|provider|admin`).

Cloud Function:
- `setUserRole(uid, role)` (callable, admin-only)

### Dark / Light mode

Theme mode is stored in `SharedPreferences` and can be changed in **Settings**.

# kidsactivities

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
