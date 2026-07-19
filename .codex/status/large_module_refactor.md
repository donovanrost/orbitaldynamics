# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-type inclusion policy extraction.

Status:
Selected; implementation has not started.

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
Pending: focused strategy/general review baselines, exact allowlist membership
proof, strict compile, all combined CadenceImport tests, schema contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport central manifest builder extraction, selected in `caa62f6f` and
implemented in `8e584b9a`. `cadence_import.ex` moved from 3,078 to 2,876 lines;
the extracted owner is 216 lines.

Next candidate:
Return to remaining review-package orchestration or row dispatch after
review-type inclusion has one production owner.

Blocked:
No.
