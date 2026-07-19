# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-row builder extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract `review_manifest_row/2`, its 36-type callback registry, all
review-specific row adapter functions, and their private normalization/context
helpers into `OrbitalDynamics.CadenceImport.ReviewRowBuilder`. Preserve one
private facade seam used by review-package and campaign/strategy orchestration.

Selection evidence:
- `cadence_import.ex` is now 1,415 lines.
- The selected cluster spans roughly 500 lines and wires 36 review types to
  family-specific row modules plus shared normalization/context policies.
- The cluster has one responsibility: construct one manifest row from one
  normalized operator-review row and rank.
- Campaign proposed-contact/strategy rows, public constructors, manifest
  routing, manifest assembly, capability data, and schemas remain outside the
  boundary.

Verification:
Pending: representative focused row-family baselines, exact old/new manifest
proofs, strict compile, all combined CadenceImport tests, schema contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport manifest routing extraction, selected in `dc7d43b2` and
implemented in `ee8f7b3a`. `cadence_import.ex` moved from 2,056 to 1,415 lines;
the dedicated router is 1,640 lines.

Next candidate:
Re-inventory the remaining campaign/strategy facade callback adapters after
review-row construction has one production owner.

Blocked:
No.
