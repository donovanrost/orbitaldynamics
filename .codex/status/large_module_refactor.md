# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation capability-context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract the Validation capability accessor, model-acceptance model-limit
projection, and schema-migration report/row status accessors into
`OrbitalDynamics.Schema.ValidationCapabilityContext`.
Route the Schema facade's model-acceptance and schema-migration consumers
through those four focused internal APIs.
Keep property dispatch, row-schema construction, contract validation, and
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,189 lines.
- Validation capabilities are fetched directly for the model-acceptance known
  limits and two lazily evaluated schema-migration status sets.
- The selected code has one responsibility: expose schema-facing
  Validation capability context to otherwise independent consumers.
- Focused function captures preserve lazy schema-migration callback timing and
  per-call capability evaluation. Model-acceptance/migration property dispatch
  and contract validators remain in their current owners.
- Exact known-limit values, migration status values and ordering, generated
  JSON Schema, validation results, and checked-in exports must remain
  unchanged.

Implementation:
Added `OrbitalDynamics.Schema.ValidationCapabilityContext`, which now owns the
Validation capability accessor, model-acceptance model-limit projection, and
schema-migration report/row status accessors. The Schema facade imports the
three focused consumer APIs and retains lazy function captures for migration
status evaluation.
`schema.ex` moved from 6,189 to 6,187 lines; the dedicated owner is 20 lines.

Verification:
- Strict focused export-validation/registry/validation/candidate-refresh
  baseline before extraction: 11 passed.
- The same strict focused suite after extraction: 11 passed.
- Strict full schema-export task plus adjacent JSON Schema export,
  fixture-visibility, and validation fixture coverage completed all 23 cases
  successfully; this combination suppressed ExUnit's final summary line.
- `mix xref callers OrbitalDynamics.Schema.ValidationCapabilityContext`
  reports only `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,062 files.
- Implementation commit `739e27fc` pushed to `main`.

Behavior/schema changes:
None. Public facades, lazy callback timing, per-call capability evaluation,
known-limit/status values and ordering, generated JSON Schema, validation
behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema validation capability-context extraction, selected in `1b7b8b2e` and
implemented in `739e27fc`.
`schema.ex` moved from 6,189 to 6,187 lines; the dedicated
ValidationCapabilityContext owner is 20 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
