# Development Workflow

## Branching

- Always start new work from an up-to-date `master`.
- Before creating a feature branch:
  - `git checkout master`
  - `git pull origin master`
  - `git checkout -b codex/<feature-name>`
- Prefer branch names with the `codex/` prefix unless the team agrees on another convention.
- If the current branch already contains unrelated work, do not stack new feature work on top of it by default.

## Planning

- Every new feature should have an implementation slice before coding starts.
- If a feature is too large for one pass, split it into smaller slices in `docs/implementation-plan.md` or a feature-specific plan doc.
- Default every task to unchecked with `- [ ]`.
- Mark completed work with `- [x]`.
- If a task is only partially done, split it into smaller checklist items instead of leaving ambiguous status.

## Codex Workflow

- Start by reading `README.md`, `docs/implementation-plan.md`, `docs/architecture.md`, and the relevant files under `api/spec`.
- Treat `docs/implementation-plan.md` as the execution checklist, not just a brainstorming note.
- Prefer one small vertical slice at a time:
  - route or controller
  - domain or context logic
  - persistence
  - verification
  - doc update
- Keep edits small enough that Codex can verify and explain them in one pass.
- When a task grows, add a new slice before writing more code.

## Slice Template

- [ ] define the contract or endpoint being implemented
- [ ] add or update persistence shape
- [ ] implement domain logic
- [ ] expose the HTTP layer
- [ ] add or update verification
- [ ] update docs and mark completed items

## Default Conventions

- Empty planned lists should be written as `[]` when a section has nothing yet.
- Actionable task lists should use markdown checkboxes.
- Prefer concrete task names over broad placeholders.
- Mark only code that exists and has been verified at the appropriate level as done.

## Documentation Updates

- Update docs in the same change that updates the implementation.
- Keep `README.md`, `docs/implementation-plan.md`, and architecture notes aligned with the current codebase.
- If a backend contract or workflow change affects `/Users/dr4f/personal/serius/verisite`, update the related docs there in the same pass.
- If a section is no longer current, rewrite it instead of layering contradictory notes on top.

## Verification

- Run the smallest useful verification for the change.
- Record completed verification tasks as `- [x]` in the relevant plan when they are part of the implementation slice.
- If verification is skipped or blocked, note that clearly in the doc or change summary.
- Prefer this order for small backend changes:
  - `mix format`
  - targeted syntax or compile check
  - focused test if one exists
