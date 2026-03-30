# Architecture

## Direction

- modular monolith first
- simple synchronous flows for v1
- PostgreSQL as the source of truth
- object storage for uploaded files
- optimize for easy Codex iteration and low-risk slices

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

- employee
- session
- attendance_record
- reimbursement_request
- reimbursement_attachment
- stored_file

## Main Rules

- employee routes only expose the signed-in employee data
- admin reimbursement actions require admin role
- reimbursement status transitions are strict
- payment reference can only be attached after approval
- suspicious attendance is review metadata, not a blocked action

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
