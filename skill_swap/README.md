# SkillSwap

SkillSwap is a community skill-exchange platform. People can discover nearby users, share skills, join projects, create communities, and connect with others through skill swaps.

The repository is being developed in two stages:

- `skill_swap/`: Flutter mobile application for Android and iOS.
- `web/`: reserved for the upcoming Next.js web application.

## Current Features

- Email/password authentication with Firebase Auth.
- Google Sign-In on supported mobile devices.
- Profile setup with skills offered, skills wanted, availability, experience, bio, location, and profile photo.
- Discover tabs for people, skills, services, projects, and communities.
- Firestore-backed community creation, membership, and starter communities.
- Community project creation and joining.
- Chat, notifications, collaborations, events, resources, and profile views.
- Responsive onboarding and mobile navigation.

## Technology

### Mobile

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage and Messaging
- Riverpod for state management
- Google Sign-In and Sign in with Apple

### Planned Web App

The web version will use:

- Next.js with TypeScript
- React
- Firebase Authentication and Firestore
- A shared data model with the Flutter app

The web client will reuse the same Firebase project and collections where practical, so users can move between mobile and web without creating separate accounts or data.

## Project Structure

```text
SkillSwap/
├── skill_swap/        # Flutter application
│   ├── lib/
│   │   ├── core/      # Theme, shared services, and widgets
│   │   └── features/  # Auth, profile, discover, community, chat, etc.
│   ├── assets/        # Images and application assets
│   ├── android/       # Android platform project
│   ├── ios/           # iOS platform project
│   └── pubspec.yaml
└── web/               # Next.js application, planned
```

## Requirements

For the Flutter app:

- Flutter SDK compatible with Dart `3.11.5`.
- Android Studio or Xcode for mobile builds.
- A configured Firebase project.
- An Android emulator, iOS simulator, or physical device.

For the planned web app:

- Node.js 20 or newer.
- npm, pnpm, or yarn.
- Firebase web configuration.

## Run the Flutter App

From the repository root:

```bash
cd skill_swap
flutter pub get
flutter devices
flutter run
```

Run static analysis and build a debug APK with:

```bash
flutter analyze
flutter build apk --debug
```

The project currently does not contain automated test files. Add tests under `skill_swap/test/` using the `_test.dart` naming convention.

## Firebase Configuration

The mobile app uses the Firebase configuration in:

- `skill_swap/lib/firebase_options.dart`
- `skill_swap/android/app/google-services.json`

Before running the app, make sure the Firebase project has the required services enabled:

1. Firebase Authentication providers used by the app.
2. Cloud Firestore.
3. Storage if photo storage is enabled for the environment.
4. Firebase Cloud Messaging if push notifications are being tested.

For Google Sign-In on Android, register the app package name and the SHA-1 certificate for each build variant in Firebase Console.

## Firestore Collections

The app currently uses collections including:

`users`, `posts`, `communities`, `projects`, `events`, `resources`, `messages`, `notifications`, `collaborations`, `meetings`, `appreciations`, and `skills`.

Keep field names consistent between Flutter and the future Next.js client. Community documents use fields such as `name`, `description`, `category`, `memberIds`, `createdBy`, and `createdAt`.

## Next.js Web Roadmap

The web client will be added under `web/` as a separate Next.js application. Planned milestones:

1. Scaffold the Next.js app with TypeScript and shared Firebase configuration.
2. Add authentication and protected routes.
3. Build desktop navigation and responsive versions of onboarding, profile, discover, and community pages.
4. Reuse Firestore queries and document contracts from the Flutter app.
5. Add web-specific testing, accessibility checks, and deployment configuration.

Suggested setup command when web development begins:

```bash
npx create-next-app@latest web --typescript --eslint --app
```

## Development Notes

- Keep feature-specific code under `skill_swap/lib/features/`.
- Put shared UI and services under `skill_swap/lib/core/`.
- Do not commit API keys, service-account files, or production credentials.
- Test authentication and Firestore writes on an emulator or development Firebase project before release builds.

## Useful Documentation

- [Flutter documentation](https://docs.flutter.dev/)
- [Firebase documentation](https://firebase.google.com/docs)
- [Next.js documentation](https://nextjs.org/docs)
