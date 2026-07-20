# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operator-review capability-context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract the OperatorReview capability accessor, model-limit projection,
source-artifact-type accessor, and review-type accessor into
`OrbitalDynamics.Schema.OperatorReviewCapabilityContext`.
Route the Schema facade's existing operational-handoff property dispatch,
operator-review row schema, and package/row validation through those four
focused internal APIs.
Keep all consuming schema construction, property dispatch, validation
ownership, and public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,184 lines.
- OperatorReview capability data is fetched directly at five schema and
  validation call sites plus the model-limit helper for the whole capability
  map, known limits, source artifact types, and review types.
- The selected code has one responsibility: expose schema-facing
  OperatorReview capability context to otherwise independent consumers.
- The four focused accessors replace repeated module coupling while preserving
  per-call capability evaluation. Operational-handoff dispatch,
  operator-review row schema construction, and package/row validators remain
  in their current owners.
- Exact atom-to-string conversion, capability values and ordering, generated
  JSON Schema, validation results, and checked-in exports must remain
  unchanged.

Implementation:
Added `OrbitalDynamics.Schema.OperatorReviewCapabilityContext`, which now owns
the OperatorReview capability accessor, model-limit projection,
source-artifact-type accessor, and review-type accessor. The Schema facade
routes all five former direct capability dependencies through those four
focused APIs.
`schema.ex` moved from 6,184 to 6,186 lines because the explicit import is two
lines larger than the removed helper/direct-call surface; the dedicated owner
is 21 lines.

Verification:
- Strict focused operator-review/export/Cadence-import/operational-timeline
  baseline before extraction: 23 passed.
- The same strict focused suite after extraction: 23 passed.
- Strict full schema-export task plus adjacent fixture-visibility,
  validation-evidence, candidate-refresh provenance, and communications
  fixture coverage: 10 passed.
- `mix xref callers
  OrbitalDynamics.Schema.OperatorReviewCapabilityContext` reports only
  `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,060 files.
- Implementation commit `236d08f0` pushed to `main`.

Behavior/schema changes:
None. Public facades, per-call capability evaluation, model-limit conversion,
source/review type ordering, generated JSON Schema, validation behavior, and
checked-in exports remain unchanged.

Last completed slice:
Schema operator-review capability-context extraction, selected in `8b3c2daf`
and implemented in `236d08f0`.
`schema.ex` moved from 6,184 to 6,186 lines; the dedicated
OperatorReviewCapabilityContext owner is 21 lines and all five direct
OperatorReview capability dependencies moved behind it.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
