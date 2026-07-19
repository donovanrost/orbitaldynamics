# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operator-review validation extraction.

Status:
Completed and published.

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
- Strict compile passed across 3,868 files with warnings as errors.
- Focused operator-review and review/import handoff contracts passed: 6 tests.
- Full Schema suite passed: 175 tests.
- JSON Schema export contracts passed: 15 tests.
- Exact old/new validation reports matched for 9 valid and mutated standalone
  and nested package, row, and row-link fixtures.
- Static inspection confirms the facade retains only its arity-2/arity-3 seams
  plus registry/capability/callback inputs; runtime xref reports `Schema` as the
  sole caller of the new owner.
- `git diff --check` and bounded ownership review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema operator-review validation extraction, selected in `b55ade2d` and
implemented in `818526c4`. `schema.ex` moved from 6,888 to 6,878 lines; the
dedicated owner is 46 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after operator-review
validation has one production owner.

Blocked:
No.
