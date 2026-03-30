# Implementation Plan

## Scope

Implement the backend based on the current contracts in `api/spec`.

The backend workspace keeps a local copy of the contracts so backend development, generated docs, and contract checks can live together.

## Status Summary

- [x] Phoenix application skeleton exists
- [x] base endpoint and router exist
- [x] health endpoint exists
- [x] repo configuration exists
- [ ] domain schemas exist
- [ ] migrations exist
- [ ] feature routes exist beyond health
- [ ] contract-aligned auth flow exists
- [ ] contract-aligned attendance flow exists
- [ ] contract-aligned reimbursement flow exists
- [ ] contract-aligned reports flow exists

## Current Focus

- [ ] complete persistence foundation before adding feature routes
- [ ] define the first feature slice after persistence is in place

## Modules

- [ ] auth
- [ ] employees
- [ ] attendance
- [ ] reimbursements
- [ ] reports
- [ ] files

## Build Order

## 1. Foundation

- [x] service bootstrap
- [x] environment config
- [x] PostgreSQL connection configuration
- [x] Ecto repo configuration
- [ ] Ecto schemas
- [ ] Ecto migrations
- [x] health endpoint
- [ ] shared validation
- [ ] shared error handling
- [ ] seed script
- [ ] local setup instructions validated

## 2. Auth And Employees

- [ ] login
- [ ] bearer auth guard
- [ ] session persistence
- [ ] logout
- [ ] profile read
- [ ] profile update
- [ ] profile language update
- [ ] profile photo persistence

## 3. Attendance

- [ ] clock in
- [ ] clock out
- [ ] attendance history
- [ ] suspicious flag rule service

## 4. Reimbursements

- [ ] submit request
- [ ] list requests
- [ ] cancel pending request
- [ ] approve request
- [ ] reject request
- [ ] attach payment reference

## 5. Reports

- [ ] attendance CSV export
- [ ] reimbursement CSV export
- [ ] response mapping to inline JSON content defined in the current spec

## 6. Hardening

- [ ] role checks
- [ ] rate limits
- [ ] audit fields
- [ ] observability
- [ ] contract cleanup for upload and token flows

## Slice Backlog

### Slice F1. Bootstrap

- [x] create the Elixir application skeleton
- [x] configure Phoenix endpoint and router
- [x] add the `/api/health` endpoint
- [x] add base repo configuration

### Slice F2. Persistence Foundation

- [ ] add initial Ecto schemas for employees, sessions, attendance, reimbursements, and files
- [ ] add the first database migration set
- [ ] add seed data for local development

### Slice F3. Shared HTTP Foundation

- [ ] add request validation strategy
- [ ] add shared error response mapping
- [ ] add auth plug scaffolding
- [ ] add API contract serving or validation hooks if needed

### Slice A1. Auth Skeleton

- [ ] define employee and session schemas
- [ ] add login request and response mapping
- [ ] add auth plug skeleton for bearer token parsing
- [ ] add placeholder session issuance flow
- [ ] verify the auth slice with a focused test or compile check

### Slice E1. Employee Profile Read

- [ ] define profile query path from authenticated employee to response shape
- [ ] add profile presenter or response mapper
- [ ] expose the profile read endpoint
- [ ] verify profile response shape against the current contract

### Slice T1. Attendance Clock In

- [ ] define attendance record schema and changeset
- [ ] implement clock-in domain flow
- [ ] expose the clock-in endpoint
- [ ] verify one success path and one invalid path

### Slice R1. Reimbursement Submission

- [ ] define reimbursement request and attachment schemas
- [ ] implement reimbursement submission flow
- [ ] expose the submission endpoint
- [ ] verify request persistence and response mapping

## Verification Backlog

- [x] format Elixir files
- [x] parse Elixir source files successfully
- [ ] fetch dependencies with `mix deps.get`
- [ ] run `mix test`
- [ ] run a compile-level verification after dependencies are installed

## Done Criteria

- [ ] every current OpenAPI path has a working handler
- [ ] database schema covers attendance, reimbursement, employee, session, and file data
- [ ] local seed data supports employee and admin review flows
- [ ] tests cover state transitions and CSV generation
