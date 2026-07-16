# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Suppressed-candidate callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace suppressed-candidate callbacks with direct primitive and stable-ID
support, including the separately reused duplicate-evidence entry point.

Why this slice:
All eleven callbacks map to shared support. Focused resource-filter tests cover
nested type/status validation, overlap counts, duplicate collision evidence,
and exact count/index errors through the public Schema facade.

Current coupling/problem:
The facade assembles and passes the same eleven-function bag to both the full
row validator and a separately reused duplicate-evidence check.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/suppressed_candidate_contracts.ex`
- `lib/orbital_dynamics/schema/primitive_validation.ex`

Definition of done:
The facade bag and both call-site callback arguments are gone; focused resource
filter/schema export tests, fingerprint, formatting, and export checks pass;
xref shows direct primitive and stable-ID dependencies.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` (passed).
- `mix test test/orbital_dynamics/resource_filter_test.exs:589 test/orbital_dynamics/resource_filter_test.exs:2745 test/orbital_dynamics/schema/resource_contracts_test.exs:444 test/orbital_dynamics/schema_export_test.exs`
  (6 passed, 40 excluded).
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
  (passed; checked-in export unchanged).
- Contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Focused xref callers/graph confirmed direct aggregation, primitive, and
  stable-ID dependencies.
- `mix format --check-formatted` and `git diff --check` (passed).
- Bounded local review confirmed unchanged validation order, overlap-count
  semantics, upper-bound helper behavior, paths, and messages; review sidecar
  delegation was unavailable under runtime policy.

Verification gaps:
- Full suite not run.

Last commit:
`8ffb3e18` (`Collapse suppressed candidate callbacks`).

Next candidate:
Remove shared-validation callbacks from refresh-budget reports, using direct
collection aggregation for its row-count sum.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 13,919 lines; suppressed candidate is 149
  lines.
- Ending point: `schema.ex` is 13,891 lines; suppressed candidate is 116 lines.
  Primitive validation is 418 lines after receiving the unchanged ten-line
  upper-bound helper.
- Operational-feedback validation was audited and deferred because its row
  traversal still composes the facade-owned realized-activity validator.
- Published implementation commit: `8ffb3e18`; the parent performed the exact
  mechanical commit/push because publisher delegation was unavailable under
  runtime policy.
- Campaign-plan validation was audited and deferred because its bag composes
  more than twenty facade-owned nested artifact validators.
- Published implementation commit: `b4db6998`; the parent performed the exact
  mechanical commit/push because publisher delegation was unavailable under
  runtime policy.
- Resource-projection flow-row was audited and deferred because source-window
  validation still composes candidate-diff-owned behavior.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
