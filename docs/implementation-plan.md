# Implementation Plan

## Scope

Implement the backend based on the current contracts in `api/spec`.

The backend workspace keeps a local copy of the contracts so backend development, generated docs, and contract checks can live together.

## Status Summary

- [x] Phoenix application skeleton exists
- [x] base endpoint and router exist
- [x] health endpoint exists
- [x] repo configuration exists
- [x] domain schemas exist
- [x] migrations exist
- [x] feature routes exist beyond health
- [x] contract-aligned auth flow exists
- [x] contract-aligned attendance flow exists
- [x] contract-aligned reimbursement flow exists
- [x] contract-aligned reports flow exists

## Current Focus

- [x] complete persistence foundation before adding feature routes
- [x] define the first feature slice after persistence is in place

## Modules

- [x] auth
- [x] employees
- [x] attendance
- [x] reimbursements
- [x] reports
- [x] files

## Build Order

## 1. Foundation

- [x] service bootstrap
- [x] environment config
- [x] PostgreSQL connection configuration
- [x] Ecto repo configuration
- [x] Ecto schemas
- [x] Ecto migrations
- [x] health endpoint
- [x] shared validation
- [x] shared error handling
- [x] seed script
- [x] local setup instructions validated

## 2. Auth And Employees

- [x] login
- [x] bearer auth guard
- [x] session persistence
- [x] logout
- [x] profile read
- [x] profile update
- [x] profile language update
- [x] profile photo persistence

## 3. Attendance

- [x] clock in
- [x] clock out
- [x] attendance history
- [x] location sample intake
- [ ] suspicious flag rule service hardening

## 4. Reimbursements

- [x] submit request
- [x] list requests
- [x] cancel pending request
- [x] approve request
- [x] reject request
- [x] attach payment reference

## 5. Reports

- [x] attendance CSV export
- [x] reimbursement CSV export
- [x] response mapping to inline JSON content defined in the current spec

## 6. Hardening

- [ ] role checks
- [ ] rate limits
- [ ] audit fields
- [ ] observability
- [ ] contract cleanup for token flows

## 7. Organization Support

- [ ] add organization or workspace persistence
- [ ] make auth and sessions organization-aware
- [ ] scope admin permissions by organization
- [ ] move settings and business data to organization boundaries
- [ ] add invite or join flow planning for employee onboarding

## Slice Backlog

### Slice F1. Bootstrap

- [x] create the Elixir application skeleton
- [x] configure Phoenix endpoint and router
- [x] add the `/api/health` endpoint
- [x] add base repo configuration

### Slice F2. Persistence Foundation

- [x] add initial Ecto schemas for employees, sessions, attendance, reimbursements, and files
- [x] add the first database migration set
- [x] add seed data for local development

### Slice F3. Shared HTTP Foundation

- [x] add request validation strategy
- [x] add shared error response mapping
- [x] add auth plug scaffolding
- [ ] add API contract serving or validation hooks if needed

### Slice F4. File Storage

- [x] add provider-backed file upload context
- [x] add persisted storage backend settings for future admin control
- [x] expose file upload and storage settings endpoints
- [x] refactor profile photo and reimbursement attachment flows to use uploaded file ids
- [x] wire the S3-compatible transport adapter for AWS and MinIO-style endpoints
- [ ] wire the Google Drive transport adapter if the product still needs it after the admin UI lands

### Slice H1. Admin Access And UI Preparation

- [ ] tighten backend role checks so admin is the only elevated role for now
- [ ] define admin-only API capabilities explicitly in `api/spec`
- [ ] design a later role-management slice where admins can create roles and assign route access
- [ ] add audit-oriented storage settings and reimbursement review coverage
- [ ] document the future admin web app contract for a minimal Vue + `shadcn-vue` UI
- [ ] keep the admin UI as a separate frontend slice from this backend repo unless product direction changes

### Slice O1. Organization Foundation

- [ ] add an `organizations` table and seed a default local organization
- [ ] add `organization_id` to employees and sessions
- [ ] update auth lookup so identity resolves within an organization context
- [ ] define how requests resolve the active organization, such as slug or subdomain later
- [ ] keep the first rollout limited to one organization per employee

### Slice O2. Organization Scoping

- [ ] add `organization_id` to attendance, reimbursement, file, and storage-setting tables
- [ ] update queries so organization boundaries are explicit in addition to employee ownership
- [ ] move storage settings from a global singleton row to one row per organization
- [ ] add tests that prove one organization cannot read or mutate another organization's data

### Slice O3. Organization Admin And Onboarding

- [ ] scope `admin` to organization membership rather than global authority
- [ ] define a lightweight invite or join flow for employee onboarding into an organization
- [ ] document the mobile-app assumption that one app serves many organizations
- [ ] defer advanced platform-admin, billing, and custom-domain concerns until product demand is real

### Slice A1. Auth Skeleton

- [x] define employee and session schemas
- [x] add login request and response mapping
- [x] add auth plug skeleton for bearer token parsing
- [x] add placeholder session issuance flow
- [x] verify the auth slice with a focused test or compile check

### Slice E1. Employee Profile Read

- [x] define profile query path from authenticated employee to response shape
- [x] add profile presenter or response mapper
- [x] expose the profile read endpoint
- [x] verify profile response shape against the current contract

### Slice T1. Attendance Clock In

- [x] define attendance record schema and changeset
- [x] implement clock-in domain flow
- [x] expose the clock-in endpoint
- [x] add session and location persistence required by the updated spec
- [x] expose clock-out, location sample, and history endpoints
- [x] verify success and invalid attendance paths

### Slice R1. Reimbursement Submission

- [x] define reimbursement request and attachment schemas
- [x] implement reimbursement submission flow
- [x] expose the submission endpoint
- [x] verify request persistence and response mapping

## Verification Backlog

- [x] format Elixir files
- [x] parse Elixir source files successfully
- [x] fetch dependencies with `mix deps.get`
- [x] run `mix test`
- [x] run a compile-level verification after dependencies are installed

## Done Criteria

- [x] every current OpenAPI path has a working handler
- [ ] database schema covers attendance, reimbursement, employee, session, and file data
- [ ] local seed data supports employee and admin review flows
- [ ] tests cover state transitions and CSV generation
- [ ] organization direction is documented before admin UI scope expands further
