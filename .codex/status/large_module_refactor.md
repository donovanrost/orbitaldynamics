# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema decision-support validation consolidation.

Status:
Selected; implementation has not started.

Selected boundary:
Move maneuver recommendation/review validation and optional objective
tradeoff/satisfaction validation into the existing
`OrbitalDynamics.Schema.DecisionSupportValidation` owner. Preserve the
existing arity-2 and arity-3 private Schema callback seams.

Selection evidence:
- `schema.ex` is 6,972 lines; the selected contiguous cluster spans
  6,021-6,065.
- The cluster has one responsibility: validate maneuver and objective
  decision-support evidence.
- Maneuver model limits remain shared facade/export data, while objective
  registry dispatch can be supplied as a callback to the existing owner.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
Pending: focused maneuver/objective baselines, exact old/new fixture validation
reports, strict compile, broader Schema contract tests, JSON Schema export
checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema candidate-rejection validation extraction, selected in `2a36e107` and
implemented in `deae0f5a`. `schema.ex` moved from 6,991 to 6,972 lines; the
dedicated owner is 36 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after decision-support
validation has one production owner.

Blocked:
No.
