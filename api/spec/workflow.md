# API Spec Workflow

## Goal

Keep the OpenAPI files easy to implement from and easy to keep in sync with the Phoenix codebase.

## Spec-First Slice Flow

1. read the target YAML file
2. identify the exact path, method, request body, and response schema involved
3. check `../docs/spec-gap-notes.md` for known ambiguity
4. implement the smallest backend slice that matches the current contract
5. update the spec in the same change if the external behavior changes
6. update `../docs/implementation-plan.md` with `- [x]` only after the implementation exists

## Conventions

- Use checklist items for implementation tracking in docs, not inside the YAML files.
- Use `[]` in docs when a planned list is intentionally empty.
- Prefer explicit request and response schemas over vague descriptions.
- Reuse schema components when shapes are shared.
- Keep naming stable once a mobile client depends on it.
- Prefer backward-compatible additions over breaking contract edits.

## What To Verify When Editing A Spec

- the path and HTTP method are correct
- request body is present when the backend needs client input
- response schema matches the current intended payload
- success and error responses are defined consistently enough for implementation
- field names match the current app language and backend domain terms

## Current Consistency Notes

- auth and profile flows are split across `auth.yaml` and `profile.yaml`
- error response schemas are not standardized across files yet
- authenticated endpoints do not yet define a shared security scheme
- request validation detail is uneven across endpoints
- admin reimbursement review flows derive reviewer identity from auth context

## When To Change The Spec First

- when adding or removing externally visible fields
- when changing request requirements
- when changing status codes
- when resolving an ambiguity that would affect client behavior

## When Code Can Move First

- internal persistence changes
- internal validation rules that do not alter the documented response shape
- background refactors that preserve the current contract
