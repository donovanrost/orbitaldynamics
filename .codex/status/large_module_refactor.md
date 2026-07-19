# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-report validation extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract optional contact-filter, contact-contention, and
contact-contention-resolution report validation into
`OrbitalDynamics.Schema.ContactReportValidation`. Preserve the existing
arity-2 and arity-3 private Schema callback seams.

Selection evidence:
- `schema.ex` is 7,023 lines; the selected contact-report seams span
  5,872-5,905 and 5,952-5,963.
- The cluster has one responsibility: validate optional communications contact
  evidence before it is consumed by campaign and allocation contracts.
- Its only nested row dependency already has a production owner in
  `ResourceValidation`; the report contract modules and primitive error
  construction can be called directly by the new owner.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
Pending: focused filter/communications baselines, exact old/new fixture
validation reports, strict compile, broader Schema contract tests, JSON Schema
export checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema station-reservation validation extraction, selected in `24310979` and
implemented in `de73642a`. `schema.ex` moved from 7,037 to 7,023 lines; the
dedicated owner is 48 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after contact-report
validation has one production owner.

Blocked:
No.
