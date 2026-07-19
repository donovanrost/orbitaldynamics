# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operator-review validation extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract optional package validation, package/row orchestration, and review-row
link validation into `OrbitalDynamics.Schema.OperatorReviewValidation`.
Preserve the existing arity-2 and arity-3 private Schema callback seams.

Selection evidence:
- `schema.ex` is 6,888 lines; the selected operator-review seams span
  6,075-6,087, 6,297-6,303, 6,756-6,766, and 6,779-6,789.
- The cluster has one responsibility: validate standalone and nested
  operator-review packages, rows, and row links.
- Registry dispatch, model limits, capability values, and callback builders
  remain facade-owned and can be supplied to the new validator.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
Pending: focused operator-review baselines, exact old/new fixture validation
reports, strict compile, broader Schema contract tests, JSON Schema export
checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema source-evidence validation extraction, selected in `32c1639d` and
implemented in `dde67b49`. `schema.ex` moved from 6,912 to 6,888 lines; the
dedicated owner is 40 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after operator-review
validation has one production owner.

Blocked:
No.
