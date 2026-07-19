# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport operator-review package import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract operator-review package normalization, row filtering/ranking/metadata,
provenance/context construction, and manifest-builder invocation into
`OrbitalDynamics.CadenceImport.ReviewPackageImport`. Preserve
`from_operator_review_package/2` as the public facade delegate, pass concrete row
dispatch as a callback, and pass schema/status/capability inputs from the facade.

Selection evidence:
- `cadence_import.ex` is now 2,816 lines.
- The selected public entry body spans about 48 lines and orchestrates already
  extracted normalization, review-type, metadata, summary-context, row-source,
  and manifest-builder owners.
- The family has one responsibility: convert an operator-review package into
  the final import manifest while retaining source row order and ranks.
- Concrete row dispatch/builders, public routing, capability construction, and
  schemas remain outside the boundary.

Verification:
Pending: focused operator-review package baselines, exact old-AST orchestration
equivalence proof, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-row run-input metadata extension, selected in `de39d347`
and implemented in `840ddfb5`. `cadence_import.ex` moved from 2,819 to 2,816
lines; the shared metadata owner grew from 21 to 27 lines.

Next candidate:
Return to remaining public routing or row dispatch after operator-review package
import has one production owner.

Blocked:
No.
