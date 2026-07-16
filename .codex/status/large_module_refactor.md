# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Pareto-frontier callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace Pareto-frontier callbacks with direct optimizer model limits plus
collection, primitive, stable-ID, and numeric-map validation.

Why this slice:
All fourteen callbacks map to shared support or the public optimizer model-limit
source. Focused optimizer and validation-reference coverage exercises rows,
counts, IDs, objective maps/keys, model limits, and JSON Schema export.

Current coupling/problem:
The facade assembles a fourteen-function bag for one Pareto-frontier entry point
even though the leaf owns row classification and derived-count semantics.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/pareto_frontier_contracts.ex`

Definition of done:
The facade bag and call-site callback argument are gone; focused optimizer/schema
export tests, fingerprint, formatting, and export checks pass; xref shows direct
optimizer, collection, primitive, and stable-ID dependencies.

Behavior/schema changes:
None intended. Alternative/frontier/dominated counts, row ID sets, objective
maps/keys, model limits, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` (passed).
- `mix test test/orbital_dynamics/schema/optimizer_objective_contracts_test.exs test/orbital_dynamics/validation_test.exs:13709 test/orbital_dynamics/schema_export_test.exs`
  (6 passed, 180 excluded).
- Runtime fixture probes confirmed exact objective-key, numeric-map, and model-limit
  paths/messages.
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
  (passed; checked-in export unchanged).
- Contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Focused xref callers confirmed direct optimizer and collection dependencies
  plus the facade-only Pareto leaf entry point.
- `mix format --check-formatted` and `git diff --check` (passed).
- Bounded local review confirmed unchanged row traversal, classification,
  derived counts/ID sets, objective maps/keys, model limits, paths/messages, and
  fallback behavior; review sidecar delegation was unavailable under runtime
  policy.

Verification gaps:
- Full suite not run.

Last commit:
`dbb1aeb6` (`Collapse Pareto frontier callbacks`).

Next candidate:
Move schema-migration report model limits into its cohesive leaf and remove the
remaining shared-validation callback bag.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 13,761 lines; Pareto-frontier contracts are 206
  lines.
- Ending point: `schema.ex` is 13,741 lines; Pareto-frontier contracts are 153
  lines.
- Published implementation commit: `dbb1aeb6`.
- Schema-migration validation was audited next: thirteen callbacks map to shared
  support and the fixed model-limit list can move into the cohesive leaf while
  remaining the JSON Schema source.
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
