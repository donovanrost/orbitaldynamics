# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport campaign review-package import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the candidate-refresh and campaign-repair review-package constructor
implementations into
`OrbitalDynamics.CadenceImport.CampaignReviewPackageImport`. Preserve both
public facade entry points and pass the existing review-package import seam as
a callback.

Selection evidence:
- `cadence_import.ex` is now 2,193 lines.
- The selected pair spans about 50 lines around the custom strategy constructor
  and shares embedded-package precedence and generation-contract routing.
- The pair has one responsibility: turn candidate-refresh and repair artifacts
  into review-package imports while preserving refresh/repair provenance.
- Public API docs, V1 campaign and V3 strategy row construction, manifest
  assembly, schemas, and activity/result imports remain outside the boundary.

Verification:
Pending: focused generation baselines, exact old/new constructor equivalence
proof, strict compile, all combined CadenceImport tests, schema contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport activity-result import extraction, selected in `4f515b1f` and
implemented in `33cf46dc`. `cadence_import.ex` moved from 2,236 to 2,193 lines;
the extracted owner is 69 lines.

Next candidate:
Re-inventory V1 campaign/V3 strategy or manifest routing after generation
review-package imports have one production owner.

Blocked:
No.
