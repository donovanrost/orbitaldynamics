# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: proposed-contact callback and model-limit ownership cleanup.

Status:
Completed and published.

Selected slice:
Move proposed-contact model limits into the family module and replace its
callback bag with direct activity, primitive, and stable-ID dependencies.

Why this slice:
Activity/contact validation is now callback-free, the limits are static
family metadata, and every remaining callback maps to existing support.

Current coupling/problem:
Resolved. Model limits are family-owned, shared contact validation is a direct
activity dependency, primitive/stable-ID support is direct, and the facade only
delegates contacts.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/proposed_contact_contracts.ex`

Definition of done:
Proposed-contact metadata is family-owned, callback plumbing is gone, focused
contact/export tests and fingerprint pass, and xref shows direct activity,
primitive, and stable-ID dependencies.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Six proposed-contact, fixture, Cadence-row, and export tests passed.
- Full checked-in schema export produced no diffs.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and direct activity, primitive, and stable-ID
  dependencies.
- Formatting and `git diff --check` passed.

Verification gaps:
- Full suite not run; the focused six-test contact/export gate and deterministic
  fingerprint are the verification boundary for this slice.

Last commit:
`30ee2f3f` (`Collapse proposed contact callbacks`).

Next candidate:
Collapse policy-escalation callback ownership; its nested validator uses only
four primitive/stable-ID support operations.

Blocked:
No.

Notes:
- `schema.ex` is 14,172 lines after this slice (down from 14,193).
- `ProposedContactContracts` is 129 lines and callback-free.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.
