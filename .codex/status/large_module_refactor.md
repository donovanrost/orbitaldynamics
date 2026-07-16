# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh window callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace candidate-refresh window and remaining-horizon callbacks with direct
primitive, stable-ID, and collection validation.

Why this slice:
All twelve callbacks map to shared support. Focused candidate-refresh contract
coverage exercises window fixtures, sample coverage, horizon timing, required
types, stable IDs, and JSON Schema export.

Current coupling/problem:
The facade assembles a twelve-function bag for refreshed-window collections,
standalone windows, and remaining horizons even though the leaf owns their
timing and sample-coverage semantics.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_window_contracts.ex`

Definition of done:
The facade bag and all three call-site callback arguments are gone; focused
candidate refresh/schema export tests, fingerprint, formatting, and export
checks pass; xref shows direct primitive, stable-ID, and collection dependencies.

Behavior/schema changes:
None intended. Window IDs/types, intervals, assumptions, sample coverage,
horizon duration/output-step checks, paths/messages, and schema output remain
unchanged.

Tests run:
- `mix compile --warnings-as-errors` (passed).
- `mix test test/orbital_dynamics/schema/candidate_refresh_contracts_test.exs:999 test/orbital_dynamics/validation_test.exs:9214 test/orbital_dynamics/validation_test.exs:9431 test/orbital_dynamics/schema_export_test.exs`
  (6 passed, 188 excluded).
- Runtime fixture probes confirmed exact sample-coverage, positive output-step,
  and maximum output-step paths/messages.
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
  (passed; checked-in export unchanged).
- Contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Focused xref callers confirmed direct collection, primitive, and stable-ID
  dependencies plus the facade-only window leaf entry point.
- `mix format --check-formatted` and `git diff --check` (passed).
- Bounded local review confirmed unchanged collection paths, fallback clauses,
  validation order, interval/sample-coverage formulas, horizon timing, and exact
  messages; review sidecar delegation was unavailable under runtime policy.

Verification gaps:
- Full suite not run.

Last commit:
`b3a97150` (`Collapse candidate refresh window callbacks`).

Next candidate:
Remove candidate-activity callbacks by calling the already extracted activity
validator plus direct primitive and stable-ID support.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 13,854 lines; candidate-refresh window
  contracts are 235 lines.
- Ending point: `schema.ex` is 13,834 lines; candidate-refresh window contracts
  are 184 lines.
- Published implementation commit: `b3a97150`.
- Candidate-activity validation was audited next: one callback maps to the
  already extracted `ActivityContracts` leaf and the remainder map to shared
  primitive and stable-ID support.
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
