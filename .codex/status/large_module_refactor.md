# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-type inclusion policy extraction.

Status:
Completed and published.

Selected boundary:
Extract the supported import-manifest review-type allowlist and the
strategy-review exclusion for recommendation rows into
`OrbitalDynamics.CadenceImport.ReviewTypePolicy`. Preserve the facade's existing
`import_manifest_review_row?/1` and `strategy_review_manifest_row?/1` seams as
delegates.

Selection evidence:
- `cadence_import.ex` is now 2,876 lines.
- The selected contiguous policy spans about 55 lines and gates which operator
  review rows become import-manifest rows.
- The family has one responsibility: maintain exact review-type membership and
  exclude strategy recommendations from the secondary strategy review pass.
- Review-package lookup/counting, row dispatch/building, schemas, and source
  ordering remain outside the boundary.

Verification:
- Strict test compile passed with 3,823 files and warnings as errors.
- Two focused strategy/general review tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An AST-derived proof against selection commit `7f604aa3` confirmed exact
  membership and order for all 45 review types, then exercised every member,
  recommendation exclusion, accepted strategy fallback, unknown type, and
  malformed row.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed membership and strategy exclusion have one
  production implementation behind the preserved facade seams.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `review_type_policy.ex`.
- Bounded local review found no allowlist membership/order, exclusion,
  fallback, row selection, dispatch, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-type inclusion policy extraction, selected in `7f604aa3`
and implemented in `cc8132e5`. `cadence_import.ex` moved from 2,876 to 2,825
lines; the extracted owner is 60 lines.

Next candidate:
Return to remaining review-package orchestration or row dispatch after
review-type inclusion has one production owner.

Blocked:
No.
