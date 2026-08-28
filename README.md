# SkillSwap

Advanced README for the SkillSwap project

## Table of Contents

- Project Overview
- Key Features
- Architecture & Components
- Technology Stack
- Getting Started (Development)
  - Prerequisites
  - Local Setup
  - Running Services
- Directory Structure
- Database & Data Model
- Authentication & Authorization
- API Reference (Overview)
- Web Version (Next.js) — roadmap and integration guide
  - Creating the web/ workspace
  - Environment variables
  - API integration patterns
  - SSR/SSG and client-side rendering strategy
  - Deployment (Vercel) and CI
- Testing
- Performance & Security Considerations
- CI / CD
- Contributing
- License
- Contact & Acknowledgements

---

## Project Overview

SkillSwap is an opinionated platform for exchanging skills and micro-services between users. The core project implements the backend, business logic, and persistence layers. This README documents the architecture, development workflow, and how to add a modern web frontend under the `web/` folder using Next.js.

This document assumes the codebase is modular, with a server API (REST/GraphQL), a data store, and worker or background processing capabilities. If some of these are not present, treat the sections as guidance when you extend the project.

## Key Features

- User accounts and profiles
- Skill listings and discovery
- Booking / request flows for skill exchange
- Messaging and notifications (in-app + email)
- Ratings & reviews
- Admin dashboard for moderation
- Background jobs for long-running tasks (emails, notifications, reconciliation)

## Architecture & Components

- API Server: handles authentication, business logic, validation, and exposes stable endpoints for frontends and mobile clients.
- Database: stores users, skills, bookings, messages, and application state (SQL or NoSQL depending on implementation).
- Worker/Queue: executes background tasks such as sending emails, push notifications, or processing uploads.
- Web Frontend (planned): a Next.js app placed at `/web` that consumes the API, uses SSR/SSG where appropriate, and supports modern UX patterns.

Design principles:
- Keep business logic in the API; the frontend should be thin and composable.
- Version the API early if you expect multiple clients.
- Use feature flags for incremental rollout.

## Technology Stack (recommended)

- Language: Node.js (TypeScript recommended), Python, or Go (adapt to the repo)
- API: Express / Fastify / NestJS (Node.js) or Django / FastAPI (Python)
- Database: PostgreSQL (primary), Redis (caching, session store, queue broker)
- Queue: BullMQ / Sidekiq / Celery
- Authentication: JWT + refresh tokens OR OAuth 2.0 for third-party sign-ins
- Web Frontend: Next.js (React + TypeScript)
- Testing: Jest / Vitest, Cypress for e2e
- CI/CD: GitHub Actions
- Hosting: Vercel for frontend, containerised API (Docker) on Fly/Vultr/AWS/GCP

## Getting Started (Development)

### Prerequisites

- Node.js LTS (16/18/20) with npm or pnpm/yarn
- Docker & Docker Compose (optional but recommended for local DB and worker)
- PostgreSQL (or configured Docker container)
- Redis (for caching/queue)

### Local Setup (example)

1. Clone the repo:

   git clone https://github.com/turab202/SkillSwap.git
   cd SkillSwap

2. Copy environment variables:

   cp .env.example .env

3. Start services (Docker Compose) — optional:

   docker compose up -d

4. Install dependencies:

   npm install

5. Run migrations and seed (example with TypeORM/Prisma/migrations):

   npm run migrate
   npm run seed

6. Start the development server:

   npm run dev

7. Run background workers in another terminal:

   npm run worker

Adjust the commands above to match the project's actual scripts.

## Directory Structure (suggested)

- src/
  - api/ (HTTP handlers / controllers)
  - services/ (business logic)
  - models/ (ORM / schema definitions)
  - jobs/ (background processors)
  - lib/ (utilities)
  - config/ (environment, feature flags)
  - tests/
- web/ (Next.js frontend — planned)
- scripts/
- docker-compose.yml
- Dockerfile
- .github/workflows/

## Database & Data Model (overview)

Core entities:
- User (id, name, email, avatar, role, bio, skills[])
- Skill (id, owner_id, title, description, tags, price? availability)
- Booking / Exchange (id, skill_id, requester_id, state, scheduled_at, created_at)
- Message / Conversation (id, participants[], messages[])
- Review (id, rating, author_id, target_id, body)

Indexes and constraints:
- Index searchable columns (title, tags, full-text index on description)
- Foreign keys with cascade rules or soft deletes depending on business rules

Migration guidance:
- Keep migrations small and reversible
- Use feature flags when making large schema changes

## Authentication & Authorization

- User signup via email/password or OAuth (GitHub/Google)
- Issue JWT access tokens with reasonable expiry and a refresh token rotation strategy
- Protect sensitive endpoints; implement RBAC or ACL for admin features

Security tips:
- Rate limit authentication endpoints
- Store hashed and salted passwords (bcrypt/argon2)
- Validate and sanitize all inputs
- Keep secrets in environment variables or a secret manager

## API Reference (Overview)

Design a consistent API surface. Example endpoints:

- POST /api/auth/register
- POST /api/auth/login
- POST /api/auth/refresh
- GET /api/users/:id
- GET /api/skills
- POST /api/skills
- GET /api/skills/:id
- POST /api/bookings
- PATCH /api/bookings/:id/accept
- GET /api/conversations/:id/messages

Versioning:
- /api/v1/... or use headers for versioning

Pagination, filtering, and sorting:
- Use cursor-based pagination for lists with high churn
- Provide filter and sort query params for discovery endpoints

## Web Version (Next.js) — roadmap and integration guide

We will add a web frontend under `/web` implemented with Next.js. The following is a step-by-step guide to add and integrate it with the existing project.

1. Create the Next.js app inside the repository:

   cd SkillSwap
   npx create-next-app@latest web --typescript

2. Minimal package.json scripts (in repo root) to streamline local dev:

   "dev:web": "(cd web && pnpm dev)",
   "build:web": "(cd web && pnpm build)",
   "start:web": "(cd web && pnpm start)"

3. Folder structure inside /web (recommended):

- web/
  - app/ or pages/ (use app router for Next 13+ apps)
  - components/
  - lib/ (API clients, auth helpers)
  - styles/
  - public/
  - middleware.ts (for auth redirects, if required)

4. Environment variables (web/.env.local):

- NEXT_PUBLIC_API_BASE_URL=https://api.example.com
- NEXT_PUBLIC_AUTH_CLIENT_ID=...

5. API client strategy:

- Create a thin HTTP client in web/lib/api.ts that centralizes base URL, headers, and token handling.
- Use SWR or React Query for caching and revalidation.
- For authenticated pages, use cookies or HTTP-only cookie + server-side session to avoid exposing tokens to the browser.

6. Rendering strategy:

- Use SSR for user-profile pages and SEO-sensitive routes.
- Use SSG with Incremental Static Regeneration (ISR) for public listing pages (skills index), revalidate frequently.
- Use client-side rendering (CSR) for heavily interactive screens (conversations, in-app messaging).

7. Authentication on the web app:

- Prefer HTTP-only cookies set by the API when logging in. Next.js middleware can check cookies and redirect to /login if missing.
- Alternatively, use the OAuth flow with NextAuth.js (works well with Next.js) and connect to your API for custom operations.

8. Forms, validation, and UI:

- Use React Hook Form + Zod for schema-based validation.
- Use a component library (Chakra UI, Tailwind CSS + Headless UI, or Radix UI) for consistent UI building blocks.

9. Deployment:

- Recommended: Vercel for Next.js. Create a project pointing to the `web` directory as the root. Set environment variables on Vercel.
- For monorepos, Vercel supports the `rootDirectory` setting; configure build settings to `cd web && pnpm build`.
- CI: configure GitHub Actions to run `pnpm --prefix web build` and deploy on push to main.

10. Routes and API integration examples:

- Fetching public skills (ISR): getStaticProps in pages/skills or use app router’s fetch with { next: { revalidate } }.
- Authenticated user data: use getServerSideProps or server components that call the API with cookies.

11. Example API call client (web/lib/api.ts):

- Centralize token refresh handling and retry logic.
- Attach request and response interceptors to handle 401 and attempt a refresh.

## Testing

- Unit tests: Jest / Vitest for core services and components
- Integration tests: test API endpoints using supertest or Playwright for full-stack scenarios
- End-to-end tests: Cypress / Playwright targeting the web app and the running backend
- CI: run tests in GitHub Actions on PRs and block merges on failing tests

## Performance & Security Considerations

- Add caching layers: Redis and HTTP caches (CDN) for static assets and public listing endpoints
- Use a CDN for media / uploads (S3 + CloudFront)
- Ensure proper CORS configuration for API
- Rate limiting, IP throttling, and abuse detection on sensitive endpoints
- Input validation and content sanitization to avoid XSS/Injection
- Regular dependency audits and secret scanning

## CI / CD

- GitHub Actions pipeline:
  - Lint -> Test -> Build -> Deploy
  - PR checks: run unit tests + static analysis
  - Deploy: on merge to main, build & deploy API and web frontend

## Contributing

- Follow conventional commits
- Branch naming: feature/<short-description>, fix/<issue>
- Open a pull request with a clear description and link to the issue
- Include tests for new behavior
- Run linters and formatters before pushing

## License

Include the appropriate license (MIT, Apache-2.0, etc.). Add LICENSE file at project root.

## Contact & Acknowledgements

Maintainer: turab202 (GitHub)

Thank you for contributing and building SkillSwap. If you want, I can now create the `/web` Next.js scaffold inside the repository and add the recommended config, scripts, and a starting layout. Tell me whether to:

1) Initialize a TypeScript Next.js app under /web with recommended packages (React, SWR/React Query, Tailwind, NextAuth)
2) Add a minimal example page wired to the API base URL using environment variables
3) Add GitHub Actions to build the web app on PRs and merges

Pick one or more options and I will create the files.
