# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport activity-result import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the planned activity, realized activity, realized-state snapshot, and
result-artifact constructor implementations into
`OrbitalDynamics.CadenceImport.ActivityResultImport`. Preserve all four public
facade entry points and pass the existing review-package import seam as a
callback.

Selection evidence:
- `cadence_import.ex` is now 2,236 lines.
- The selected contiguous family spans about 75 lines plus one result identity
  delegate and owns activity/result normalization, conversion, and routing.
- The family has one responsibility: turn planned, realized, snapshot, and
  final result evidence into review-package imports while preserving each
  distinct identity chain.
- Public API docs, proposed-contact row construction, manifest assembly,
  schemas, and campaign/candidate-refresh imports remain outside the boundary.

Verification:
Pending: focused activity/result baselines, exact old/new constructor
equivalence proof, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport operational-timeline import extraction, selected in `88e73082`
and implemented in `a002de2b`. `cadence_import.ex` moved from 2,254 to 2,236
lines; the extracted owner is 36 lines.

Next candidate:
Re-inventory remaining public routing after activity/result imports have one
production owner.

Blocked:
No.
