# Implementation Plan

## Scope

Implement the backend based on the current contracts in `api/spec`.

The backend workspace keeps a local copy of the contracts so backend development, generated docs, and contract checks can live together.

## Modules

- auth
- employees
- attendance
- reimbursements
- reports
- files

## Build Order

## 1. Foundation

- service bootstrap
- environment config
- PostgreSQL connection
- Ecto repo, schemas, and migrations
- health endpoint
- shared validation and error handling

## 2. Auth And Employees

- login
- bearer auth guard
- session persistence
- logout
- profile read and update
- profile language update
- profile photo persistence

## 3. Attendance

- clock in
- clock out
- attendance history
- suspicious flag rule service

## 4. Reimbursements

- submit request
- list requests
- cancel pending request
- approve request
- reject request
- attach payment reference

## 5. Reports

- attendance CSV export
- reimbursement CSV export
- response mapping to inline JSON content defined in the current spec

## 6. Hardening

- role checks
- rate limits
- audit fields
- observability
- contract cleanup for upload and token flows

## Done Criteria

- every current OpenAPI path has a working handler
- database schema covers attendance, reimbursement, employee, session, and file data
- local seed data supports employee and admin review flows
- tests cover state transitions and CSV generation
