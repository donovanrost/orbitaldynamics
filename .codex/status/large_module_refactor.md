# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-package row-source policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the closed source-artifact-type to operator-review-package row-source
mapping into `OrbitalDynamics.CadenceImport.ReviewPackageRowSourcePolicy`.
Preserve the existing `CadenceImport` private call seam as a one-line delegate.

Selection evidence:
- `cadence_import.ex` is now 3,654 lines.
- The selected private family spans about 53 lines and has one call site in the
  operator-review-package adapter context.
- The family is a pure mapping for 16 explicit artifact contracts plus identical
  binary and non-binary fallbacks.
- Review rows, review actions, source artifact identity, manifest construction,
  schemas, ordering, and every other operator-review field remain outside the
  boundary.

Verification:
Pending: focused standalone-review baseline, exact mapping matrix, strict
compile, all combined CadenceImport tests, schema contracts, static single
ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport generic review-action policy extraction, selected in `c5639be1`,
corrected in `45d53209`, and implemented in `4ef7d3c9`.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing map after
review-package row-source policy has one production owner.

Blocked:
No.
