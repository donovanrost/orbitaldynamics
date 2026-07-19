# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema optional operational-readiness validation consolidation.

Status:
Selected; implementation has not started.

Selected boundary:
Move optional operational-readiness and quality-gate report branching into the
existing `OrbitalDynamics.Schema.OperationalReadinessValidation` owner.
Preserve the existing arity-3 private Schema callback seams.

Selection evidence:
- `schema.ex` is 6,872 lines; the selected contiguous cluster spans
  5,982-5,998.
- The cluster has one responsibility: apply the common nil/object/type boundary
  before readiness and quality-gate contract validation.
- Both concrete report validators already have one production owner in
  `OperationalReadinessValidation`, so no registry or callback dependency moves.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
Pending: focused readiness/quality-gate baselines, exact old/new fixture
validation reports, strict compile, broader Schema contract tests, JSON Schema
export checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema operational-timeline validation extraction, selected in `477cf707` and
implemented in `0c32a016`. `schema.ex` moved from 6,878 to 6,872 lines; the
dedicated owner is 25 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after optional
operational-readiness validation has one production owner.

Blocked:
No.
