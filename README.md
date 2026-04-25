# Verisite Backend

Backend workspace for implementing the Verisite API from the OpenAPI contracts in `api/spec`.

## Goal

Build the backend for:

- employee login
- attendance clock in and clock out
- suspicious attendance marking
- reimbursement submission and review
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

## Foundation Status

The workspace now includes:

- Phoenix-style application layout
- Ecto repository configuration
- Docker Compose for PostgreSQL and MinIO
- environment template
- health endpoint scaffold
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
