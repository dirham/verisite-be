# Spec Gap Notes

The current spec is enough to plan the backend, but a few decisions should be settled before implementation goes far.

## Open Questions

- [x] login response defines a bearer access token field
- [x] logout invalidates the current persisted session
- [x] attendance requests now include location, timezone, and device integrity fields needed for suspicious checks
- [ ] reimbursement admin endpoints do not define how admin identity is authenticated
- [ ] future custom-role and route-permission management is not defined yet
- [x] attachment and profile photo requests use uploaded file identifiers instead of raw client paths
- [ ] reports only cover `singleEmployee` scope, while broader reporting is mentioned elsewhere in product planning
- [ ] error response format is inconsistent across endpoints

## Safe v1 Interpretation

- keep response shapes stable unless the backend needs a documented contract field, such as the auth bearer token
- add internal persistence fields without exposing them yet
- implement inline CSV report responses as written
- keep uploads behind a file service that can translate real storage keys into the current response `path` fields
- persist the active storage backend in backend settings so an admin panel can switch providers later without rewriting feature flows

## Implementation Bias

- prefer Phoenix controllers plus context modules over pushing business rules into routing layers
- model contract-facing validation with changesets and explicit request mappers so spec drift stays easy to spot

## Codex Notes

- if a gap blocks implementation, document the chosen temporary interpretation in the slice that uses it
- do not silently invent externally visible contract fields without updating `api/spec`
- when possible, implement behind internal fields first and keep the API response stable

## Recommended Resolution Order

- [x] auth token and session contract
- [x] upload and file identifier contract
- [ ] admin authorization contract
- [ ] custom role and route-authorization contract
- [x] attendance suspicious-check request fields
- [ ] shared error envelope
- [ ] report scope and pagination decisions

## Current Upload Interpretation

- `aws` means an S3-compatible backend, including MinIO-style deployments
- storage settings persist the routing target such as bucket, region, base URL, and prefix
- storage credentials stay in server environment variables and are not exposed through the admin-facing settings API
- Google Drive remains deferred until the admin UI and role model are clearer

## Spec Location Recommendation

- for active backend implementation, it is worth keeping the contracts in this workspace under `api/spec`
- the backend will likely become the main place where contract validation, OpenAPI serving, and contract tests run
- to avoid drift, choose one source of truth soon:
  - either move ownership to `verisite-be/api/spec`
  - or keep ownership in the Flutter repo and treat `verisite-be/api/spec` as a synced mirror

My recommendation for the next step is to make `verisite-be/api/spec` the primary contract home once the team is ready, because backend implementation will change these files more often than the mobile shell.

## Future Admin UI Notes

- plan a separate admin web frontend using Vue and `shadcn-vue`
- keep admin as the only elevated role in the first UI pass
- add custom role creation and route-permission management later, controlled by admins
- keep backend APIs role-based so the UI only reflects permissions that already exist server-side
- start with a minimal clean UI around storage settings and reimbursement review before expanding to broader admin dashboards
