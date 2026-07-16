# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-activity callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace candidate-activity callbacks with direct activity, schema-contract,
primitive, and stable-ID validation.

Why this slice:
All sixteen callbacks map to already extracted shared support. Focused
candidate-refresh contract coverage exercises candidate fixtures, score/source
identity, bounds, stable-ID lists, types, and JSON Schema export.

Current coupling/problem:
The facade assembles a sixteen-function bag for one candidate-activity entry
point even though the leaf owns its score and source-window identity semantics.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/candidate_activity_contracts.ex`

Definition of done:
The facade bag and call-site callback argument are gone; focused candidate
refresh/schema export tests, fingerprint, formatting, and export checks pass;
xref shows direct activity, schema-contract, primitive, and stable-ID dependencies.

Behavior/schema changes:
None intended. Base activity validation, stable IDs, scoring, source-window
identity, objective/resource fields, bounds, paths/messages, and schema output
remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` (passed; retained the shared facade
  `validate_activity/3` wrapper after compile showed campaign bags still use it).
- `mix test test/orbital_dynamics/schema/candidate_refresh_contracts_test.exs:629 test/orbital_dynamics/schema/candidate_refresh_contracts_test.exs:999 test/orbital_dynamics/validation_test.exs:9021 test/orbital_dynamics/schema_export_test.exs`
  (6 passed, 188 excluded).
- Runtime fixture probes confirmed exact score-sum and source-window identity
  paths/messages.
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
  (passed; checked-in export unchanged).
- Contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Focused xref callers confirmed direct activity and schema-contract dependencies
  plus the facade-only candidate-activity leaf entry point.
- `mix format --check-formatted` and `git diff --check` (passed).
- Bounded local review confirmed unchanged validation order, base activity
  behavior, scoring, source-window identity, stable-ID lists, bounds, paths, and
  messages; review sidecar delegation was unavailable under runtime policy.

Verification gaps:
- Full suite not run.

Last commit:
`999b718e` (`Collapse candidate activity callbacks`).

Next candidate:
Remove planned-activity callbacks by calling extracted activity contact-field,
schema-contract, execution-metric, primitive, and stable-ID support directly.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 13,834 lines; candidate-activity contracts are
  199 lines.
- Ending point: `schema.ex` is 13,812 lines; candidate-activity contracts are
  141 lines.
- Published implementation commit: `999b718e`.
- Planned-activity validation was audited next: its contact-field and execution
  uncertainty callbacks map to the already extracted `ActivityContracts` and
  `ExecutionMetricContracts` leaves; the remainder map to shared support.
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
