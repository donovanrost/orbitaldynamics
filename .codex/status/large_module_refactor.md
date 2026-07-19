# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport validation and readiness import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the five schema-validation, execution, operational-readiness, and
quality-gate constructor implementations into
`OrbitalDynamics.CadenceImport.ValidationReadinessImport`. Preserve every
public facade entry point and pass the existing review-package import seam as a
callback.

Selection evidence:
- `cadence_import.ex` is now 2,573 lines.
- The selected contiguous family and its three distant source-ID delegates span
  about 100 lines.
- The family has one responsibility: normalize validation/readiness reports,
  select their source identity, convert them to OperatorReview packages, and
  route the correct source contract.
- Public API docs, review-row construction, manifest assembly, schemas, and
  unrelated result-artifact identity remain outside the boundary.

Verification:
Pending: representative focused validation/readiness baselines, exact old/new
constructor equivalence proof, strict compile, all combined CadenceImport
tests, schema contracts, static single ownership, runtime xref, and bounded
review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport timeline review import orchestration extraction, selected in
`893716e0` and implemented in `fd48e3cf`. `cadence_import.ex` moved from 2,708
to 2,573 lines; the extracted owner is 221 lines.

Next candidate:
Re-inventory remaining public routing after validation/readiness imports have
one production owner.

Blocked:
No.
