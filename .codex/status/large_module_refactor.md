# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: resource-flow summary equality ownership cleanup.

Status:
Completed and published.

Selected slice:
Move generic field equality into primitive support and let resource-projection
flow-summary derived-count validation call it directly.

Why this slice:
Fifty cohesive derived-field checks route one callback; existing unrelated
callback consumers remain compatible through the facade import.

Current coupling/problem:
Resolved. Primitive support owns equality, resource-flow consistency calls it
directly, and the facade retains compatibility imports for other consumers.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Resource-flow derivation order, nil-expected skip semantics, paths, and exact
  mismatch errors.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/primitive_validation.ex`
- `lib/orbital_dynamics/schema/resource_projection_flow_summary_count_contracts.ex`

Definition of done:
Field equality is support-owned, the resource-flow callback bag/wrappers are
gone, focused/broad tests and fingerprint pass, and xref shows primitive support.

Behavior/schema changes:
None. Derivation order, nil-expected skipping, paths, messages, and deterministic
schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- 26 broad resource, provenance, JSON-schema, and export tests passed.
- Four exact ignored-row, count-consistency, overflow/shortfall, and row-derived
  pressure tests passed; 45 unrelated resource-projection tests were excluded.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and a direct primitive-support edge.
- Formatting, `git diff --check`, and checked-in schema cleanliness passed.

Verification gaps:
- Full suite not run; the 30-test resource/export boundary and deterministic
  fingerprint are the verification boundary for this slice.

Last commit:
`c76e9843` (`Collapse resource flow equality callback`).

Next candidate:
Reassess remaining multi-operation callback families; keep mixed
activity-context ownership deferred.

Blocked:
No.

Notes:
- `schema.ex` is 14,507 lines after this slice (down from 14,523).
- `ResourceProjectionFlowSummaryCountContracts` is 695 lines (down from 765);
  its unrelated helper-specific callback clusters remain intact.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.
