# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport contact-planning import extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the link-capacity, contact-allocation report, capacity-pack summary,
reservation-conflict summary, and standalone contact-intent constructor
implementations into `OrbitalDynamics.CadenceImport.ContactPlanningImport`.
Preserve all five public facade entry points and pass the existing
review-package import seam as a callback.

Selection evidence:
- `cadence_import.ex` is now 2,352 lines.
- The selected contiguous family spans about 80 lines and owns contact
  capacity, allocation, conflict, and intent normalization and routing.
- The family has one responsibility: turn contact-planning evidence into
  review-package imports while preserving the intent activity-ID fallback.
- Public API docs, row construction, manifest assembly, schemas, and adjacent
  station/resource-projection imports remain outside the boundary.

Verification:
Pending: focused contact-planning baselines, exact old/new constructor
equivalence proof, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport resource-projection import extraction, selected in `04cad874`
and implemented in `82f89a5d`. `cadence_import.ex` moved from 2,371 to 2,352
lines; the extracted owner is 45 lines.

Next candidate:
Re-inventory remaining public routing after contact-planning imports have one
production owner.

Blocked:
No.
