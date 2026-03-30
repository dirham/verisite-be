# Architecture

## Direction

- modular monolith first
- simple synchronous flows for v1
- PostgreSQL as the source of truth
- object storage for uploaded files

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
  verisite_be_web/
    endpoint.ex
    router.ex
    controllers/
    auth/
    employees/
    attendance/
    reimbursements/
    reports/
    files/
  verisite_be/
    auth/
    database/
    http/
    storage/
priv/
  repo/
    migrations/
test/
```

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
