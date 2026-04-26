# Architecture

## Direction

- modular monolith first
- simple synchronous flows for v1
- PostgreSQL as the source of truth
- object storage for uploaded files
- storage provider selection persisted in app settings
- lightweight organization or workspace boundaries before broader SaaS expansion
- optimize for easy Codex iteration and low-risk slices

## Organization Support Direction

- prefer a workspace-style SaaS model over heavy enterprise multi-tenancy for now
- keep one backend deployment and one mobile app shared across customers
- represent each client company as an `organization`
- scope employees, sessions, attendance, reimbursements, files, and settings to an organization
- treat `admin` as an organization-scoped role, not a global operator role
- keep room for a later platform-admin concept only if operations require it
- avoid separate database-per-customer unless a later enterprise requirement forces it

## Planned Organization Model

- `organizations` becomes the top-level business boundary
- existing `employees` can stay named as-is for now, but each record should belong to one organization
- auth should resolve both the signed-in employee and the organization context
- invites or join flows should attach employees to an organization
- storage settings should move from one global row to one row per organization
- future admin UI should operate within the current organization context

## Admin UI Direction

- the backend remains the source of truth for auth, role checks, storage settings, and reimbursement review actions
- only `admin` is an elevated role for now
- the future admin interface should be a separate web frontend, not embedded in Phoenix templates for now
- prefer Vue for that frontend and `shadcn-vue` for a minimal, clean admin UI system
- target a simple operator experience first:
  - storage provider settings
  - reimbursement review actions
  - admin-only navigation first
  - later role creation and route-access management controlled by admins

## Suggested Layout

```text
config/
  config.exs
  dev.exs
  runtime.exs
lib/
  verisite_be/
    application.ex
    repo.ex
    auth/
    employees/
    attendance/
    reimbursements/
    reports/
    files/
    storage/
    accounts/
  verisite_be_web/
    endpoint.ex
    router.ex
    controllers/
    plugs/
    serializers/
priv/
  repo/
    migrations/
test/
```

## Source Of Truth

- OpenAPI files in `api/spec` define the externally visible contract.
- `docs/implementation-plan.md` defines what is in progress and what is done.
- code should follow the docs; if code and docs drift, update both in the same change.

## Main Entities

- organization
- employee
- session
- attendance_record
- reimbursement_request
- reimbursement_attachment
- stored_file

## Main Rules

- employee routes only expose the signed-in employee data
- admin reimbursement actions require admin role within the current organization
- reimbursement status transitions are strict
- payment reference can only be attached after approval
- suspicious attendance is review metadata, not a blocked action
- organization-scoped settings and data should not bleed across customer boundaries

## Platform Notes

- Phoenix handles HTTP routing, JSON controllers, and endpoint concerns
- Ecto schemas and changesets should own persistence validation
- domain logic should live in plain Elixir modules under business contexts, not controllers
- background work can stay inline for v1 and move to Oban only when exports or file processing justify it

## Codex-Friendly Boundaries

- keep controllers thin and deterministic
- keep business rules in plain modules that are easy to test in isolation
- keep response mapping explicit so contract drift is easy to see
- avoid large cross-cutting refactors when a feature can land as a vertical slice
- prefer additive migrations and small context modules over framework-heavy abstractions

## Request Path

1. router matches the endpoint from `api/spec`
2. plug stack resolves request metadata and auth context
3. controller validates and normalizes input
4. context or service applies business rules
5. Ecto persists and loads domain data
6. serializer or presenter maps the result back to the OpenAPI response

## Empty Defaults

- use `[]` in docs when a section intentionally has no items yet
- use `- [ ]` and `- [x]` only for work tracking, not for descriptive lists
