# Verisite Backend

Backend workspace for implementing the Verisite API from the OpenAPI contracts in `api/spec`.

## Goal

Build the backend for:

- employee login
- attendance clock in and clock out
- suspicious attendance marking
- reimbursement submission and review
- file uploads with switchable storage settings
- employee profile
- CSV report export

## Docs

- [Docs Index](docs/README.md)
- [Implementation Plan](docs/implementation-plan.md)
- [Development Workflow](docs/development-workflow.md)
- [Architecture](docs/architecture.md)
- [Spec Gap Notes](docs/spec-gap-notes.md)
- [API Spec Workspace](api/spec/README.md)

## Recommended Stack

- Elixir
- Phoenix
- PostgreSQL
- Ecto
- S3-compatible file storage
- Docker Compose for local services

For the future admin web app, the current direction is:

- Vue
- `shadcn-vue`
- a separate frontend slice focused on a minimal clean admin UI rather than Phoenix server-rendered pages

## Foundation Status

The workspace now includes:

- Phoenix-style application layout
- Ecto repository configuration
- Docker Compose for PostgreSQL and MinIO
- environment template
- health endpoint scaffold
- provider-backed file upload flow with persisted storage settings
- local API spec copy for backend work

## Local Commands

- `docker compose up --build`
- `docker compose run --rm test`
- `mix deps.get`
- `mix ecto.create`
- `mix ecto.migrate`
- `mix run priv/repo/seeds.exs`
- `mix phx.server`
- `mix test`

## Docker Workflow

Use Docker for the full local stack:

- `docker compose up --build`
- API: `http://localhost:4000/api/health`
- Postgres from host tools: `localhost:15432`
- MinIO console: `http://localhost:19001`

The app container waits for Postgres, creates the dev database, runs migrations, loads seed data, and starts Phoenix. Source code is bind-mounted into `/app`; dependencies, build output, Postgres data, and MinIO data live in Docker volumes.

For S3-compatible uploads, keep non-secret routing in the storage settings API and keep credentials in environment variables:

- `AWS_ACCESS_KEY_ID` or `STORAGE_ACCESS_KEY`
- `AWS_SECRET_ACCESS_KEY` or `STORAGE_SECRET_KEY`
- optional `AWS_SESSION_TOKEN`

The `aws` provider uses SigV4 path-style uploads, so it works against AWS S3 and MinIO-style endpoints when `aws.baseUrl` points at the target service.

Google Drive is intentionally deferred for now. The next product-facing admin work should focus on admin-only backend access plus a minimal admin UI for storage settings and reimbursement review. Later, admins can create roles and manage which roles can access routes.

Open a database shell with `docker compose exec postgres psql -U postgres -d verisite_be`. When running `mix` directly on the host against the Docker database, set `DB_PORT=15432`.

Seeded local accounts use `password123`:

- `employee@verisite.local`
- `admin@verisite.local`

## Working Rules

- Start each new feature from an up-to-date `master` branch.
- Break implementation into small slices before coding.
- Write plans as checklist items with `- [ ]` by default.
- Mark finished items with `- [x]` in the relevant plan doc.

The original contracts still exist in `/Users/dr4f/personal/serius/verisite/api/spec`. I copied them here, but I did not delete the originals yet so we do not break the Flutter repo unexpectedly.
