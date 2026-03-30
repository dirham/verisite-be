# API Spec Workspace

Swagger or OpenAPI contracts that back the backend implementation.

These files were copied from `/Users/dr4f/personal/serius/verisite/api/spec` while scaffolding the Phoenix backend workspace.

Use this folder as the contract source of truth for backend-facing behavior.

## Reading Order

1. `README.md`
2. `workflow.md`
3. the relevant YAML file for the slice you are implementing
4. `../docs/spec-gap-notes.md` when the contract is ambiguous

## Files

- `auth.yaml`: login contract
- `attendance.yaml`: attendance actions and history
- `profile.yaml`: profile read and update flows
- `reimbursement.yaml`: employee and admin reimbursement flows
- `reports.yaml`: CSV export responses

## Rules

- Read the relevant spec before writing code.
- Treat the YAML as the external contract source of truth.
- Do not invent response fields in code without updating the matching spec file.
- If the spec is incomplete but implementation must continue, document the temporary interpretation in `../docs/spec-gap-notes.md`.
- Prefer small contract changes that preserve current response shapes unless the team explicitly decides otherwise.

## Recommendation

- keep `verisite-be/api/spec` as the main contract location once backend implementation starts
- if the Flutter repo still needs local copies, mirror from this workspace instead of editing both places manually

## Current Gaps To Remember

- auth still does not define token fields or logout invalidation details
- attendance write endpoints still have no request body for location, timezone, or device signals
- reimbursement admin endpoints still rely on explicit `reviewerId` in the payload
- profile photo and reimbursement attachments still use mock-friendly file paths
- report exports still return inline CSV content rather than an async file flow
