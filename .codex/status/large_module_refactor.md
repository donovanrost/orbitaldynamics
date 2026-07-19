# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport capability ownership extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the full capability declaration, schema contract/version, accepted
manifest statuses, Cadence source statuses, and source-review-type composition
into `OrbitalDynamics.CadenceImport.Capability`. Preserve the public
`capability/0` and `capabilities/0` facade API, and have manifest assembly read
the same owner instead of duplicating policy constants.

Selection evidence:
- `cadence_import.ex` is now 866 lines.
- Capability metadata and its source/status constants occupy roughly 200 lines
  at the top of the facade.
- The metadata is one responsibility and is consumed by the public capability
  API, manifest builder configuration, review-package configuration, and
  supported-contract diagnostics.
- Public constructors, row builders, routing, manifest assembly behavior, and
  schemas remain outside the boundary.

Verification:
Pending: focused capability and representative manifest baselines, exact
old/new capability/manifest proofs, strict compile, all combined CadenceImport
tests, schema contracts, static single ownership, runtime xref, and bounded
review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport campaign-row builder extraction, selected in `2cfecef1` and
implemented in `60973011`. `cadence_import.ex` moved from 907 to 866 lines; the
dedicated builder is 61 lines.

Next candidate:
Re-inventory the remaining generic facade orchestration seams after capability
metadata has one production owner.

Blocked:
No.
