# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Accepted-state callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace accepted-planning-state, spacecraft-state-estimate, and
maneuver-execution-delta callbacks with direct collection, primitive, and
stable-ID validation.

Why this slice:
All fourteen callbacks map to shared support. Dedicated accepted-state coverage
exercises schemas, imports, nested rows, trust boundaries, state vectors,
counts, invalid collections, and standalone fixtures.

Current coupling/problem:
The facade assembles one fourteen-function bag for three accepted-state entry
points even though the leaf owns import and row trust-boundary semantics.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/accepted_state_contracts.ex`

Definition of done:
The facade bag and all three call-site callback arguments are gone; focused
accepted-state/schema export tests, fingerprint, formatting, and export checks
pass; xref shows direct collection, primitive, and stable-ID dependencies.

Behavior/schema changes:
None intended. Import provenance, trust boundaries, state vectors, maneuver
deltas, nested collection behavior, derived counts, paths/messages, and schema
output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` (passed).
- `mix test test/orbital_dynamics/schema/accepted_state_contracts_test.exs test/orbital_dynamics/validation_test.exs:6471 test/orbital_dynamics/validation_test.exs:9322 test/orbital_dynamics/validation_test.exs:9483 test/orbital_dynamics/schema_export_test.exs`
  (12 passed, 178 excluded).
- Runtime fixture probes confirmed exact nested state trust-boundary and derived
  state-count paths/messages.
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
  (passed; checked-in export unchanged).
- Contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Focused xref callers confirmed direct collection and stable-ID dependencies
  plus the facade-only accepted-state leaf entry point.
- `mix format --check-formatted` and `git diff --check` (passed).
- Bounded local review confirmed unchanged nested collection order, import and
  row trust boundaries, state vectors, maneuver deltas, derived counts,
  paths/messages, and fallback behavior; review sidecar delegation was
  unavailable under runtime policy.

Verification gaps:
- Full suite not run.

Last commit:
`d0d577d0` (`Collapse accepted state callbacks`).

Next candidate:
Remove Pareto-frontier callbacks using direct optimizer model limits plus
collection, primitive, stable-ID, and numeric-map support.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 13,783 lines; accepted-state contracts are 265
  lines.
- Ending point: `schema.ex` is 13,761 lines; accepted-state contracts are 220
  lines.
- Published implementation commit: `d0d577d0`.
- Pareto-frontier validation was audited next: all fourteen callbacks map to
  shared support or the public optimizer model-limit source.
- Realized-state-snapshot validation was audited and deferred because it still
  composes callback-driven realized-activity validation.
- Timeline-transition application rows were audited and deferred because they
  compose callback-driven timeline-diff and selected-integrity validation.
- Quality-gate row and operational-readiness gate callbacks were audited and
  deferred because both compose facade-owned context and handoff validators.
- Plan-delta validation was audited and deferred because it composes facade-owned
  activity-context, timeline-link, uncertainty, and realized-activity validators.
- Campaign-plan validation was audited and deferred because its bag composes
  more than twenty facade-owned nested artifact validators.
- Resource-projection flow-row was audited and deferred because source-window
  validation still composes candidate-diff-owned behavior.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
