# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Maneuver-recommendation callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace maneuver-recommendation validation callbacks with direct primitive and
stable-ID support while retaining module-owned magnitude/model-limit checks.

Why this slice:
All ten callbacks map to shared support, with focused maneuver tests covering
required fields, vector shape, magnitude consistency, and JSON Schema export.

Current coupling/problem:
The facade assembles a ten-function bag for a cohesive leaf whose only external
value dependency is the explicit model-limit list already passed separately.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/maneuver_recommendation_contracts.ex`

Definition of done:
The facade bag and wrappers are gone, focused maneuver/export tests and the
fingerprint pass, and xref shows direct primitive/stable-ID dependencies.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` (passed).
- `mix test test/orbital_dynamics/schema/maneuver_contracts_test.exs test/orbital_dynamics/schema_export_test.exs`
  (5 passed).
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
  (passed; checked-in export unchanged).
- Schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- `mix xref graph --label compile` confirmed direct primitive/stable-ID support
  dependencies.
- `mix format --check-formatted` (passed).

Verification gaps:
- Full suite not run.

Last commit:
`f3b56dc8` (`Collapse maneuver recommendation callbacks`).

Next candidate:
Audit policy-bundle ownership for another bounded callback cleanup. Keep
operational-readiness gate deferred: its primitive callbacks are mixed with five
facade-owned nested context validators.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 14,075 lines; maneuver recommendations are 102
  lines.
- Ending point: `schema.ex` is 14,059 lines; maneuver recommendations are 103
  lines. The leaf gained one import line while the facade lost the ten-function
  callback bag and associated call plumbing.
- Published implementation commit: `f3b56dc8`.
- Resource-projection flow-row was audited and deferred because source-window
  validation still composes candidate-diff-owned behavior.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
