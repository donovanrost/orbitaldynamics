# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-readiness classification callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace operational-readiness assumption/classification callbacks with direct
equality and error support.

Why this slice:
Both callbacks map to primitive support, with readiness fixtures covering
importable and review-required gate-derived classifications.

Current coupling/problem:
The facade assembles a two-function bag for a cohesive classifier that already
owns gate precedence, readiness-level, and report-status derivation.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_readiness_classification_contracts.ex`

Definition of done:
The facade bag and wrappers are gone, focused readiness/export tests and the
fingerprint pass, and xref shows a direct primitive dependency.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors`
- `mix test test/orbital_dynamics/schema/readiness_contracts_test.exs:6 test/orbital_dynamics/schema/readiness_contracts_test.exs:186 test/orbital_dynamics/schema_export_test.exs`
  (5 passed, 1 excluded)
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- Contract fingerprint:
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- `mix xref callers OrbitalDynamics.Schema.OperationalReadinessClassificationContracts`
- Focused xref graph for readiness classification
- `mix format --check-formatted`
- `git diff --check`

Verification gaps:
- Full suite not run.

Last commit:
`afed3f2b` (`Collapse readiness classification callbacks`).

Next candidate:
Remove primitive/stable callback plumbing from maneuver recommendations; keep
known mixed callback boundaries deferred.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 14,084 lines; readiness classification is 95
  lines.
- Ending point: `schema.ex` is 14,075 lines and readiness classification is 81
  lines.
- The generated schema export was byte-for-byte unchanged.
- Resource-projection flow-row was audited and deferred because source-window
  validation still composes candidate-diff-owned behavior.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
