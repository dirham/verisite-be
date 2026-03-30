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

- `mix deps.get`
- `mix ecto.create`
- `mix phx.server`
- `mix test`

## Working Rules

- Start each new feature from an up-to-date `master` branch.
- Break implementation into small slices before coding.
- Write plans as checklist items with `- [ ]` by default.
- Mark finished items with `- [x]` in the relevant plan doc.

The original contracts still exist in `/Users/dr4f/personal/serius/verisite/api/spec`. I copied them here, but I did not delete the originals yet so we do not break the Flutter repo unexpectedly.
