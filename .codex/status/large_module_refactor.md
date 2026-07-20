# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation capability-context extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema operational-readiness capability-context extraction, selected in
`37828a28` and implemented in `c7024a68`.
`schema.ex` moved from 6,186 to 6,189 lines; the validation owner moved from
234 to 232 lines and the dedicated OperationalReadinessCapabilityContext is 13
lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
