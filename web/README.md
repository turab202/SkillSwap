# SkillSwap Web

Next.js web client for SkillSwap. This app shares the Flutter mobile app's Firebase project and Firestore data; it does not introduce a new backend.

## Stack

- Next.js App Router
- TypeScript
- React
- Firebase Authentication, Firestore, and Storage

## Setup

```bash
npm install
copy .env.example .env.local
npm run dev
```

Fill `.env.local` with the web app configuration from the Firebase project `skillswap-ec546`. Public Firebase web configuration values are safe to expose in a client application; never place service-account credentials in this file.

## Validation

```bash
npm run lint
npm run build
```

The current page is only the web foundation health screen. Product features will be implemented one at a time against the existing Firebase collections and security rules.
