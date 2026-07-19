# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema optional decision-support validation extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract optional branch-comparison, ranking-comparison, optimizer-contract,
score-term-report, and branch-comparison source-row validation into
`OrbitalDynamics.Schema.DecisionSupportValidation`. Preserve existing private
callback arities and pass contract validation as explicit closures.

Selection evidence:
- `schema.ex` is 7,119 lines; the selected contiguous cluster spans
  6,311-6,373.
- The cluster has one responsibility: validate optional decision-support
  artifacts embedded in repair, strategy, review, and import handoffs.
- Four validators share contract dispatch; the source-row validator uses only
  primitive numeric/probability checks and its existing row-count contract.
- Registry data, JSON Schema export, contract dispatch ownership, unrelated
  family validation, and all public `Schema` APIs remain outside.

Verification:
Pending: focused optimizer/strategy baselines, exact old/new fixture validation
reports, strict compile, broader Schema contract tests, schema export checks,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema timeline-transition validation extraction, selected in `76e489e1` and
implemented in `17e58a4b`. `schema.ex` moved from 7,141 to 7,119 lines; the
dedicated owner is 140 lines.

Next candidate:
Re-inventory remaining Schema resource/filter and family-validation clusters
after optional decision-support validation has one production owner.

Blocked:
No.
